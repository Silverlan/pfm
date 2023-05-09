--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.RetargetRig", BaseEntityComponent)

include("rig.lua")
include("bone_remapper.lua")
include("auto_retarget.lua")

function Component.apply_rig(entSrc, entDst)
	local rigC = entDst:AddComponent(ents.COMPONENT_RETARGET_RIG)
	rigC:RigToActor(entSrc)
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_untranslatedBones = {}
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_MAINTAIN_ANIMATIONS, "ApplyRig")
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATION_RESET, "OnAnimationReset")
end
function Component:OnRemove()
	self:ClearRigFileListener()
end
local function add_file_listener(path, callback)
	local absPath = file.find_absolute_path(path)
	if absPath == nil then
		return false
	end
	local fname = file.get_file_name(path)
	return util.DirectoryChangeListener.create(file.get_file_path(absPath), function(f)
		if f == fname then
			callback()
		end
	end, util.DirectoryChangeListener.LISTENER_FLAG_BIT_WATCH_SUB_DIRECTORIES)
end
function Component:InitializeRigFileListener()
	self:ClearRigFileListener()

	if self.m_rigFilePath == nil then
		return
	end
	local listener, err = add_file_listener(self.m_rigFilePath, function()
		if util.is_valid(self.m_rigTargetEntity) then
			self:RigToActor(self.m_rigTargetEntity)
		end
	end)
	if listener ~= false then
		self.m_rigFileListener = listener
		self.m_rigFileListenerCb = game.add_callback("Think", function()
			listener:Poll()
		end)
	end
end
function Component:ClearRigFileListener()
	if self.m_rigFileListener == nil then
		return
	end
	self.m_rigFileListener:SetEnabled(false)
	self.m_rigFileListener = nil
	util.remove(self.m_rigFileListenerCb)
end
function Component:SetRig(rig, animSrc)
	self.m_rig = rig
	self.m_animSrc = animSrc

	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	--if(animC ~= nil) then animC:SetBindPose(rig:GetBindPose()) end
	self.m_absBonePoses = {}
	self:InitializeRemapTables()
	self:UpdatePoseData()
	self:InitializeRigFileListener()
end
function Component:GetRig()
	return self.m_rig
end

function Component:Unrig()
	self.m_rig = nil
	self.m_animSrc = nil
	self.m_absBonePoses = nil
	self.m_untranslatedBones = {}
	self.m_origBindPoseToRetargetBindPose = nil
	self.m_origBindPoseBoneDistances = nil
	self.m_curPoseData = nil
	self.m_rigFilePath = nil
	self.m_rigTargetEntity = nil
	self.m_cppCacheData = nil
	self:ClearRigFileListener()
end

function Component:RigToActor(actor, mdlSrc, mdlDst)
	self:Unrig()
	mdlDst = mdlDst or self:GetEntity():GetModel()
	mdlSrc = mdlSrc or actor:GetModel()
	local animSrc = actor:GetComponent(ents.COMPONENT_ANIMATED)
	if animSrc == nil then
		console.print_warning(
			"Unable to apply retarget rig: Actor " .. tostring(actor) .. " has no animated component!"
		)
	end
	if mdlSrc == nil or mdlDst == nil or animSrc == nil or (mdlSrc == mdlDst) then
		return false
	end
	local newRig = false
	local rig = Component.Rig.load(mdlSrc, mdlDst)
	self.m_rigFilePath = Component.Rig.get_rig_file_path(mdlSrc, mdlDst):GetString()
	self.m_rigTargetEntity = animSrc:GetEntity()
	--[[if(rig == false) then
		rig = Component.Rig(mdlSrc,mdlDst)

		local boneRemapper = Component.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		local translationTable = boneRemapper:AutoRemap()
		rig:SetDstToSrcTranslationTable(translationTable)
		newRig = true
	end]]
	if rig == false then
		self:InitializeRigFileListener()
		return false
	end

	self.m_untranslatedBones = {} -- List of untranslated bones where all parents are also untranslated
	local translationTable = rig:GetDstToSrcTranslationTable()
	local function findUntranslatedBones(bone)
		if translationTable[bone:GetID()] ~= nil then
			return
		end
		self.m_untranslatedBones[bone:GetID()] = true
		for boneId, child in pairs(bone:GetChildren()) do
			findUntranslatedBones(child)
		end
	end
	for boneId, bone in pairs(mdlDst:GetSkeleton():GetRootBones()) do
		findUntranslatedBones(bone)
	end

	self:SetRig(rig, animSrc)
	return newRig
end

function Component:OnAnimationReset()
	self:GetEntity():PlayAnimation("reference")
end

function Component:FixProportionsAndUpdateUnmappedBonesAndApply(
	animSrc,
	translationTable,
	bindPoseTransforms,
	tmpPoses,
	retargetPoses,
	boneId,
	children,
	parentBoneId
)
	if boneId == nil then
		for boneId, children in pairs(self.m_curPoseData.boneHierarchy) do
			self:FixProportionsAndUpdateUnmappedBonesAndApply(
				animSrc,
				translationTable,
				bindPoseTransforms,
				tmpPoses,
				retargetPoses,
				boneId,
				children
			)
		end
		return
	end
	local finalPose
	if parentBoneId ~= nil then
		if translationTable[boneId] == nil then
			-- Keep all bones that don't have a translation in the same relative pose
			-- they had in the bind pose
			local poseParent = retargetPoses[parentBoneId]
			retargetPoses[boneId] = poseParent * bindPoseTransforms[boneId]
		else
			local method = 1
			if method == 1 then
				local poseParent = retargetPoses[parentBoneId]
				local poseWithBindOffset = poseParent * self.m_curPoseData.relBindPoses[boneId]
				local pose = retargetPoses[boneId]
				if self.m_untranslatedBones[parentBoneId] ~= true then
					pose:SetOrigin(poseWithBindOffset:GetOrigin())
				end
			else
				-- Old version; Obsolete?
				-- Clamp bone distances to original distance to parent to keep proportions intact
				local origDist = self.m_origBindPoseBoneDistances[boneId]

				local origin = retargetPoses[parentBoneId]:GetOrigin()
				local dir = tmpPoses[boneId]:GetOrigin() - tmpPoses[parentBoneId]:GetOrigin()
				local l = dir:Length()
				if l > 0.001 then
					dir:Normalize()
				else
					dir = Vector()
				end

				local bonePos = origin + dir * origDist
				local pose = retargetPoses[boneId]
				pose:SetOrigin(bonePos)

				-- TODO: We should still take into account if the animation has any actual bone translations, i.e.
				-- Multiply our distance by (targetBoneAnimDistance /targetBoneBindPoseDistance)
			end
		end
		finalPose = retargetPoses[boneId]
	else
		finalPose = retargetPoses[boneId]
	end
	if parentBoneId ~= nil and translationTable[parentBoneId] ~= nil then
		finalPose = translationTable[parentBoneId][2] * finalPose
	end

	self.m_absBonePoses[boneId] = finalPose
	--animSrc:SetBonePose(boneId,finalPose)
	--animSrc:SetBoneScale(boneId,Vector(1,1,1))

	for childBoneId, subChildren in pairs(children) do
		self:FixProportionsAndUpdateUnmappedBonesAndApply(
			animSrc,
			translationTable,
			bindPoseTransforms,
			tmpPoses,
			retargetPoses,
			childBoneId,
			subChildren,
			boneId
		)
	end
end

function Component:TranslateBoneToTarget(boneId)
	local rig = self:GetRig()
	if rig == nil then
		return
	end
	return rig:GetBoneTranslation(boneId)
end

function Component:TranslateBoneFromTarget(boneId)
	local boneIds = {}
	local rig = self:GetRig()
	if rig == nil then
		return boneIds
	end
	local t = rig:GetDstToSrcTranslationTable()
	for boneIdSrc, data in pairs(t) do
		local boneIdTgt = data[1]
		if boneIdTgt == boneId then
			table.insert(boneIds, boneIdSrc)
		end
	end
	return boneIds
end

function Component:GetTargetActor()
	return util.is_valid(self.m_animSrc) and self.m_animSrc:GetEntity() or nil
end

function Component:SetEnabledBones(bones)
	--[[self.m_enabledBones = {}
	for _,boneId in ipairs(bones) do
		self.m_enabledBones[boneId] = true
	end]]
end

function Component:InitializeRemapTables()
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()

	local origBindPose = mdl:GetReferencePose()
	local newBindPose = self:GetRig():GetBindPose()
	local origBindPoseToRetargetBindPose = {}
	local origBindPoseBoneDistances = {}
	for boneId = 0, skeleton:GetBoneCount() - 1 do
		local diff = origBindPose:GetBonePose(boneId):GetInverse() * newBindPose:GetBonePose(boneId)
		origBindPoseToRetargetBindPose[boneId] = diff:GetInverse()

		local bone = skeleton:GetBone(boneId)
		local parent = bone:GetParent()
		local distFromParent = 0.0
		if parent ~= nil then
			distFromParent = origBindPose
				:GetBonePose(parent:GetID())
				:GetOrigin()
				:Distance(origBindPose:GetBonePose(boneId):GetOrigin())
		end
		origBindPoseBoneDistances[boneId] = distFromParent
	end
	self.m_origBindPoseToRetargetBindPose = origBindPoseToRetargetBindPose
	self.m_origBindPoseBoneDistances = origBindPoseBoneDistances
end

function Component:UpdatePoseData()
	-- Precalculating some data so we don't have to recompute them every frame
	local animSrc = self:GetEntity():GetAnimatedComponent() -- TODO: Flip these names
	local animDst = self.m_animSrc
	local mdl = self:GetEntity():GetModel()
	local skeleton = mdl:GetSkeleton()
	local rig = self:GetRig()
	self.m_curPoseData = {
		retargetPoses = {},
		tmpPoses = {},
		origBindPoses = {},
		relBindPoses = {},
		bindPosesOther = {},
		boneHierarchy = skeleton:GetBoneHierarchy(),
		invRootPose = rig:GetRootPose():GetInverse(),
	}
	local retargetPoses = self.m_curPoseData.retargetPoses
	local tmpPoses = self.m_curPoseData.tmpPoses
	local relBindPoses = self.m_curPoseData.relBindPoses
	local bindPosesOther = self.m_curPoseData.bindPosesOther
	local origBindPoses = self.m_curPoseData.origBindPoses
	local bindPose = rig:GetBindPose()
	local translationTable = rig:GetDstToSrcTranslationTable()
	local origBindPose = mdl:GetReferencePose()
	for boneId = 0, skeleton:GetBoneCount() - 1 do
		local boneBindPose = bindPose:GetBonePose(boneId)
		local bone = skeleton:GetBone(boneId)
		local parent = bone:GetParent()
		relBindPoses[boneId] = (parent ~= nil and (bindPose:GetBonePose(parent:GetID()):GetInverse() * boneBindPose))
			or boneBindPose:Copy()
		retargetPoses[boneId] = boneBindPose:Copy()
		tmpPoses[boneId] = retargetPoses[boneId]:Copy()
		origBindPoses[boneId] = origBindPose:GetBonePose(boneId)

		if translationTable[boneId] ~= nil then
			local data = translationTable[boneId]
			local boneIdOther = data[1]
			bindPosesOther[boneIdOther] = animDst:GetBoneBindPose(boneIdOther):GetInverse()
		end
	end
end

function Component:ApplyRig(dt)
	local animSrc = self:GetEntity():GetAnimatedComponent() -- TODO: Flip these names
	local animDst = self.m_animSrc
	local rig = self:GetRig()
	if rig == nil or util.is_valid(animSrc) == false or util.is_valid(animDst) == false then
		return
	end

	local enableCppAcceleration = true
	if enableCppAcceleration then
		-- Same algorithm as the Lua variant, but significantly faster (since the garbage collector will not get overloaded)
		self.m_cppCacheData = self.m_cppCacheData
			or util.retarget.initialize_retarget_data(
				self.m_absBonePoses,
				self.m_origBindPoseToRetargetBindPose,
				self.m_origBindPoseBoneDistances,

				self.m_curPoseData.bindPosesOther,
				self.m_curPoseData.origBindPoses,
				self.m_curPoseData.tmpPoses,
				self.m_curPoseData.retargetPoses,
				self.m_curPoseData.invRootPose,

				rig:GetBindPoseTransforms(),
				self.m_curPoseData.relBindPoses,

				self.m_untranslatedBones,
				rig:GetDstToSrcTranslationTable()
			)
		util.retarget.apply_retarget_rig(
			self.m_cppCacheData,
			self:GetEntity():GetModel(),
			animSrc,
			animDst,
			self:GetEntity():GetModel():GetSkeleton()
		)
		return util.EVENT_REPLY_HANDLED
	end

	animDst:UpdateEffectiveBoneTransforms() -- Make sure the target entity's bone transforms have been updated
	local translationTable = rig:GetDstToSrcTranslationTable()
	--local rigPoseTransforms = rig:GetRigPoseTransforms()
	local bindPoseTransforms = rig:GetBindPoseTransforms()
	local mdl = self:GetEntity():GetModel()
	local skeleton = mdl:GetSkeleton()

	local retargetPoses = self.m_curPoseData.retargetPoses
	local tmpPoses = self.m_curPoseData.tmpPoses
	local relBindPoses = self.m_curPoseData.relBindPoses
	local bindPosesOther = self.m_curPoseData.bindPosesOther
	local origBindPoses = self.m_curPoseData.origBindPoses

	for boneId = 0, skeleton:GetBoneCount() - 1 do
		if translationTable[boneId] ~= nil then
			-- Grab the animation pose from the target entity
			local data = translationTable[boneId]
			local boneIdOther = data[1]
			local pose = animDst:GetEffectiveBoneTransform(boneIdOther)
			local tmpPose1 = pose * bindPosesOther[boneIdOther]

			local curPose = origBindPoses[boneId]:Copy()
			curPose:SetRotation(tmpPose1:GetRotation()--[[*rigPoseTransforms[id0]] * curPose:GetRotation())
			curPose:SetOrigin(pose:GetOrigin())
			curPose:SetScale(pose:GetScale())
			-- debug.draw_line(self:GetEntity():GetPos() +curPose:GetOrigin(),self:GetEntity():GetPos() +curPose:GetOrigin()+Vector(0,0,20),Color.Red,0.1)
			retargetPoses[boneId] = curPose

			tmpPoses[boneId] = retargetPoses[boneId]:Copy()
		end
	end
	self:FixProportionsAndUpdateUnmappedBonesAndApply(
		animSrc,
		translationTable,
		bindPoseTransforms,
		tmpPoses,
		retargetPoses
	)

	local function applyPose(boneId, children, parentPose)
		-- We need to bring all bone poses into relative space (relative to the respective parent), as well as
		-- apply the bind pose conversion transform.
		local pose = self.m_absBonePoses[boneId] * self.m_origBindPoseToRetargetBindPose[boneId]
		local relPose = parentPose:GetInverse() * pose
		relPose:SetScale(animSrc:GetBoneScale(boneId))
		animSrc:SetBonePose(boneId, relPose)
		-- TODO: There are currently a few issues with scaling (e.g. broken eyes), so we'll disable it for now. This should be re-enabled once the issues have been resolved!
		-- UPDATE: Broken eyes should now be fixed with scaling, so it should work properly now? (TODO: TESTME and remove the line below if all is in order)
		-- animSrc:SetBoneScale(boneId,Vector(1,1,1))
		for boneId, subChildren in pairs(children) do
			applyPose(boneId, subChildren, pose)
		end
	end
	local invRootPose = self.m_curPoseData.invRootPose
	for boneId, children in pairs(self.m_curPoseData.boneHierarchy) do
		applyPose(boneId, children, invRootPose)
	end

	-- TODO: Remove this once new animation system is fully implemented
	local mdl = self:GetEntity():GetModel()
	for slot, animIdx in pairs(animSrc:GetLayeredAnimations()) do
		local anim = mdl:GetAnimation(animIdx)
		if anim ~= nil then
			local frame = anim:GetFrame(0)
			local n = anim:GetBoneCount()
			for i = 0, n - 1 do
				local boneId = anim:GetBoneId(i)
				local pose = animSrc:GetBonePose(boneId)
				pose = pose * frame:GetBonePose(i)
				animSrc:SetBonePose(boneId, pose)
			end
		end
	end

	return util.EVENT_REPLY_HANDLED
end
function Component:OnEntitySpawn()
	self:GetEntity():PlayAnimation("reference")
end
ents.COMPONENT_RETARGET_RIG = ents.register_component("retarget_rig", Component)

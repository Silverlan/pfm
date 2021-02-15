--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.RetargetRig",BaseEntityComponent)

include("rig.lua")
include("bone_remapper.lua")

function ents.RetargetRig.apply_rig(entSrc,entDst)
	local rigC = entDst:AddComponent(ents.COMPONENT_RETARGET_RIG)
	rigC:RigToActor(entSrc)
end

function ents.RetargetRig:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_MAINTAIN_ANIMATIONS,"ApplyRig")
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATION_RESET,"OnAnimationReset")
end
function ents.RetargetRig:SetRig(rig,animSrc)
	self.m_rig = rig
	self.m_animSrc = animSrc

	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then animC:SetBindPose(rig:GetBindPose()) end
end
function ents.RetargetRig:GetRig() return self.m_rig end

function ents.RetargetRig:RigToActor(actor,mdlSrc,mdlDst)
	mdlDst = mdlDst or self:GetEntity():GetModel()
	mdlSrc = mdlSrc or actor:GetModel()
	local animSrc = actor:GetComponent(ents.COMPONENT_ANIMATED)
	if(animSrc == nil) then
		console.print_warning("Unable to apply retarget rig: Actor " .. tostring(actor) .. " has no animated component!")
	end
	if(mdlSrc == nil or mdlDst == nil or animSrc == nil) then return false end
	local newRig = false
	local rig = ents.RetargetRig.Rig.load(mdlSrc,mdlDst)
	if(rig == nil) then
		rig = ents.RetargetRig.Rig(mdlSrc,mdlDst)

		local boneRemapper = ents.RetargetRig.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		local translationTable = boneRemapper:AutoRemap()
		rig:SetDstToSrcTranslationTable(translationTable)
		newRig = true
	end
	self:SetRig(rig,animSrc)
	return newRig
end

function ents.RetargetRig:OnAnimationReset()
	self:GetEntity():PlayAnimation("reference")
end

function ents.RetargetRig:FixProportionsAndUpdateUnmappedBonesAndApply(animSrc,bindPose,translationTable,bindPoseTransforms,tmpPoses,retargetPoses,bone,parent)
	if(bone == nil) then
		local skeleton = self:GetEntity():GetModel():GetSkeleton()
		for boneId,bone in pairs(skeleton:GetRootBones()) do
			self:FixProportionsAndUpdateUnmappedBonesAndApply(animSrc,bindPose,translationTable,bindPoseTransforms,tmpPoses,retargetPoses,bone)
		end
		return
	end
	local finalPose
	local boneId = bone:GetID()
	if(parent ~= nil) then
		if(translationTable[boneId] == nil) then
			-- Keep all bones that don't have a translation in the same relative pose
			-- they had in the bind pose
			local poseParent = retargetPoses[parent:GetID()]
			retargetPoses[boneId] = poseParent *bindPoseTransforms[boneId]
		else
			-- Clamp bone distances to original distance to parent to keep proportions intact
			local origDist = bindPose:GetBonePose(parent:GetID()):GetOrigin():Distance(bindPose:GetBonePose(boneId):GetOrigin()) -- TODO: We don't need to re-calculate this every time

			local origin = retargetPoses[parent:GetID()]:GetOrigin()
			local dir = tmpPoses[boneId]:GetOrigin() -tmpPoses[parent:GetID()]:GetOrigin()
			local l = dir:Length()
			if(l > 0.001) then dir:Normalize()
			else dir = Vector() end

			local bonePos = origin +dir *origDist
			local pose = retargetPoses[boneId]
			pose:SetOrigin(bonePos)

			-- TODO: We should still take into account if the animation has any actual bone translations, i.e.
			-- Multiply our distance by (targetBoneAnimDistance /targetBoneBindPoseDistance)
		end
		finalPose = retargetPoses[parent:GetID()]:GetInverse() *retargetPoses[boneId] -- We want the pose to be relative to the parent
	else finalPose = retargetPoses[boneId] end
	if(parent ~= nil and translationTable[parent:GetID()] ~= nil) then finalPose = translationTable[parent:GetID()][2] *finalPose end
	animSrc:SetBonePose(boneId,finalPose)

	for boneId,child in pairs(bone:GetChildren()) do
		self:FixProportionsAndUpdateUnmappedBonesAndApply(animSrc,bindPose,translationTable,bindPoseTransforms,tmpPoses,retargetPoses,child,bone)
	end
end

function ents.RetargetRig:TranslateBoneToTarget(boneId)
	local rig = self:GetRig()
	if(rig == nil) then return end
	return rig:GetBoneTranslation(boneId)
end

function ents.RetargetRig:TranslateBoneFromTarget(boneId)
	local boneIds = {}
	local rig = self:GetRig()
	if(rig == nil) then return boneIds end
	local t = rig:GetDstToSrcTranslationTable()
	for boneIdSrc,data in pairs(t) do
		local boneIdTgt = data[1]
		if(boneIdTgt == boneId) then
			table.insert(boneIds,boneIdSrc)
		end
	end
	return boneIds
end

function ents.RetargetRig:GetTargetActor() return util.is_valid(self.m_animSrc) and self.m_animSrc:GetEntity() or nil end

function ents.RetargetRig:SetEnabledBones(bones)
	--[[self.m_enabledBones = {}
	for _,boneId in ipairs(bones) do
		self.m_enabledBones[boneId] = true
	end]]
end

function ents.RetargetRig:ApplyRig()
	local animSrc = self:GetEntity():GetAnimatedComponent() -- TODO: Flip these names
	local animDst = self.m_animSrc
	local rig = self:GetRig()
	if(rig == nil or util.is_valid(animSrc) == false or util.is_valid(animDst) == false) then return end

	animDst:UpdateEffectiveBoneTransforms() -- Make sure the target entity's bone transforms have been updated
	local translationTable = rig:GetDstToSrcTranslationTable()
	--local rigPoseTransforms = rig:GetRigPoseTransforms()
	local bindPoseTransforms = rig:GetBindPoseTransforms()
	local mdl = self:GetEntity():GetModel()
	local origBindPose = mdl:GetReferencePose()
	local bindPose = rig:GetBindPose()
	local skeleton = mdl:GetSkeleton()
	local retargetPoses = {}
	local tmpPoses = {}
	for boneId=0,skeleton:GetBoneCount() -1 do
		if(translationTable[boneId] ~= nil) then
			-- Grab the animation pose from the target entity
			local data = translationTable[boneId]
			local boneIdOther = data[1]
			local pose = animDst:GetEffectiveBoneTransform(boneIdOther)
			local tmpPose1 = pose *animDst:GetBoneBindPose(boneIdOther):GetInverse()

			local curPose = origBindPose:GetBonePose(boneId)
			curPose:SetRotation(tmpPose1:GetRotation()--[[*rigPoseTransforms[id0]] *curPose:GetRotation())
			curPose:SetOrigin(pose:GetOrigin())
			curPose:SetScale(pose:GetScale())
			-- debug.draw_line(self:GetEntity():GetPos() +curPose:GetOrigin(),self:GetEntity():GetPos() +curPose:GetOrigin()+Vector(0,0,20),Color.Red,0.1)
			retargetPoses[boneId] = curPose
		else retargetPoses[boneId] = bindPose:GetBonePose(boneId):Copy() end
		tmpPoses[boneId] = retargetPoses[boneId]:Copy()
	end
	self:FixProportionsAndUpdateUnmappedBonesAndApply(animSrc,bindPose,translationTable,bindPoseTransforms,tmpPoses,retargetPoses)

	return util.EVENT_REPLY_HANDLED
end
function ents.RetargetRig:OnEntitySpawn()
	self:GetEntity():PlayAnimation("reference")
end
ents.COMPONENT_RETARGET_RIG = ents.register_component("retarget_rig",ents.RetargetRig)

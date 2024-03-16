--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_flat.lua")

util.register_class("ents.DebugSkeletonDraw", BaseEntityComponent)
local Component = ents.DebugSkeletonDraw

function Component:__init()
	BaseEntityComponent.__init(self)
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_bones = {}
	self:SetColor(Color.White)
	-- self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,"UpdateBones")
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED, "InitializeBones")

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:OnEntitySpawn()
	self:InitializeBones()
	if self:GetEntity():HasComponent(ents.COMPONENT_ANIMATED) then
		self:UpdateBones()
	end
end

function Component:OnRemove()
	self:ClearBones()
end

function Component:ClearBones()
	for _, tEnts in pairs(self.m_bones) do
		for _, ent in pairs(tEnts) do
			util.remove(ent)
		end
	end
	self.m_bones = {}
end

function Component:GetBoneEntities(boneId)
	return self.m_bones[boneId]
end

function Component:GetBoneEntity(boneId, boneDst)
	if self.m_bones[boneId] == nil then
		return
	end
	return self.m_bones[boneId][boneDst]
end

function Component:GetBones()
	return self.m_bones
end

function Component:InitializeBones()
	self:ClearBones()
	local mdl = self:GetEntity():GetModel()
	if mdl == nil then
		return
	end
	local compositeC = self:GetEntity():AddComponent(ents.COMPONENT_COMPOSITE)
	local skeleton = mdl:GetSkeleton()
	local function add_bone_model(boneParent, boneChild)
		local ent = ents.create_prop("pfm/bone")
		if ent == nil then
			return
		end
		ent:SetColor(self.m_color)
		self.m_bones[boneParent:GetID()] = self.m_bones[boneParent:GetID()] or {}
		self.m_bones[boneParent:GetID()][(boneChild ~= nil) and boneChild:GetID() or -1] = ent
		compositeC:AddEntity(ent)

		local ownableC = ent:AddComponent(ents.COMPONENT_OWNABLE)
		ownableC:SetOwner(self:GetEntity())
	end
	local function add_bone(bone)
		local hasChildBone = false
		for boneId, child in pairs(bone:GetChildren()) do
			add_bone_model(bone, child)
			add_bone(child)
			hasChildBone = true
		end

		if hasChildBone == false then
			add_bone_model(bone)
		end
	end
	for boneId, bone in pairs(skeleton:GetRootBones()) do
		add_bone(bone)
	end

	self:BroadcastEvent(Component.EVENT_ON_BONES_CREATED)
end

function Component:SetColor(col)
	self.m_color = col
	for _, tEnts in pairs(self.m_bones) do
		for _, ent in pairs(tEnts) do
			if ent:IsValid() then
				ent:SetColor(col)
			end
		end
	end
end
function Component:GetColor()
	return self.m_color
end

local DRAW_LINES = false
function Component:GetLines(animC, rootPose, bone, parentPose, lines)
	local pose = rootPose * animC:GetEffectiveBonePose(bone:GetID())
	if parentPose ~= nil then
		table.insert(lines, parentPose:GetOrigin())
		table.insert(lines, pose:GetOrigin())
	end
	for boneId, child in pairs(bone:GetChildren()) do
		self:GetLines(animC, rootPose, child, pose, lines)
	end
end

function Component:OnTick()
	self:UpdateBones()
end

local leafPose = math.ScaledTransform(Vector(0, 0, 1), Quaternion())
function Component:UpdateBones()
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	self:SetNextTick(time.cur_time() + 0.02)
	if mdl == nil then
		self:SetNextTick(time.cur_time() + 0.5)
		return
	end
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if animC == nil then
		self:SetNextTick(time.cur_time() + 0.5)
		return
	end
	local skeleton = mdl:GetSkeleton()
	local parentPose = math.ScaledTransform()
	local rootPose = self:GetEntity():GetPose()
	if DRAW_LINES then
		local lines = {}
		for boneId, bone in pairs(skeleton:GetRootBones()) do
			self:GetLines(animC, rootPose, bone, nil, lines)
		end
		debug.draw_lines(lines, Color.Red, 0.1)
	else
		local dirtyBones = {}
		local poses = animC:GetEffectiveBonePoses()
		local scale = rootPose:GetScale()
		if scale ~= Vector(1, 1, 1) then
			for _, pose in ipairs(poses) do
				local pos = pose:GetOrigin()
				pos = pos * scale
				pose:SetOrigin(pos)
			end
		end
		local hasDirtyBones = false
		local rootPoseChanged = rootPose ~= self.m_prevRootPose
		for i, pose in ipairs(poses) do
			if
				rootPoseChanged
				or self.m_prevPoses == nil
				or self.m_prevPoses[i] == nil
				or self.m_prevPoses[i] ~= pose
			then
				dirtyBones[i - 1] = true
				hasDirtyBones = true
			end
		end

		self.m_prevPoses = poses
		self.m_prevRootPose = rootPose
		if hasDirtyBones then
			for _, bone in ipairs(skeleton:GetBones()) do
				local boneId = bone:GetID()
				local tEnts = self.m_bones[boneId]
				for boneDstId, ent in pairs(tEnts or {}) do
					if ent:IsValid() and (dirtyBones[boneId] or dirtyBones[boneDstId]) then
						local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
						if renderC == nil or renderC:GetSceneRenderPass() == game.SCENE_RENDER_PASS_NONE then
							self.m_prevPoses[boneId + 1] = nil -- Keep this pose dirty until the bone is visible
						else
							local bonePose = poses[bone:GetID() + 1]
							local pose = rootPose * bonePose

							local childPose
							if boneDstId ~= -1 then
								childPose = poses[boneDstId + 1]
							else
								childPose = bonePose * leafPose
							end
							childPose = rootPose * childPose

							local dirToChild = childPose:GetOrigin() - pose:GetOrigin()
							local l = dirToChild:Length()
							if l < 0.0001 then
								dirToChild = vector.FORWARD
							else
								dirToChild = dirToChild / l
							end

							local up = vector.UP
							if math.abs(dirToChild:DotProduct(up)) > 0.999 then
								up = vector.RIGHT
							end
							local rot = Quaternion(dirToChild, up)
							pose:SetRotation(rot)

							ent:SetPose(pose)

							local length = pose:GetOrigin():Distance(childPose:GetOrigin())

							local orthoAxisLengthScale = math.max(0.3 * length, 1.0)
							ent:SetScale(Vector(orthoAxisLengthScale, orthoAxisLengthScale, length))
						end
					end
				end
			end
		end
	end
end
ents.COMPONENT_DEBUG_SKELETON_DRAW = ents.register_component("debug_skeleton_draw", Component)
Component.EVENT_ON_BONES_CREATED = ents.register_component_event(ents.COMPONENT_DEBUG_SKELETON_DRAW, "on_bones_created")

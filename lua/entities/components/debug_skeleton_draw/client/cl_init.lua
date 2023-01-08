--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_flat.lua")

util.register_class("ents.DebugSkeletonDraw",BaseEntityComponent)
local Component = ents.DebugSkeletonDraw

function Component:__init()
	BaseEntityComponent.__init(self)
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_bones = {}
	self:SetColor(Color.White)
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,"UpdateBones")
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"InitializeBones")
end

function Component:OnEntitySpawn()
	self:InitializeBones()
	if(self:GetEntity():HasComponent(ents.COMPONENT_ANIMATED)) then self:UpdateBones() end
end

function Component:OnRemove()
	self:ClearBones()
end

function Component:ClearBones()
	for boneId,ent in pairs(self.m_bones) do
		util.remove(ent)
	end
	self.m_bones = {}
end

function Component:GetBoneEntity(boneId)
	return self.m_bones[boneId]
end

function Component:GetBones() return self.m_bones end

function Component:InitializeBones()
	self:ClearBones()
	local mdl = self:GetEntity():GetModel()
	if(mdl == nil) then return end
	local compositeC = self:GetEntity():AddComponent(ents.COMPONENT_COMPOSITE)
	local skeleton = mdl:GetSkeleton()
	for _,bone in ipairs(skeleton:GetBones()) do
		local ent = ents.create_prop("pfm/bone")
		if(ent ~= nil) then
			ent:SetColor(self.m_color)
			self.m_bones[bone:GetID()] = ent
			compositeC:AddEntity(ent)

			local ownableC = ent:AddComponent(ents.COMPONENT_OWNABLE)
			ownableC:SetOwner(self:GetEntity())
		end
	end

	self:BroadcastEvent(Component.EVENT_ON_BONES_CREATED)
end

function Component:SetColor(col)
	self.m_color = col
	for boneId,ent in pairs(self.m_bones) do
		if(ent:IsValid()) then ent:SetColor(col) end
	end
end
function Component:GetColor() return self.m_color end

local DRAW_LINES = false
function Component:GetLines(animC,rootPose,bone,parentPose,lines)
	local pose = rootPose *animC:GetEffectiveBoneTransform(bone:GetID())
	if(parentPose ~= nil) then
		table.insert(lines,parentPose:GetOrigin())
		table.insert(lines,pose:GetOrigin())
	end
	for boneId,child in pairs(bone:GetChildren()) do
		self:GetLines(animC,rootPose,child,pose,lines)
	end
end

function Component:UpdateBones()
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	local skeleton = mdl:GetSkeleton()
	local parentPose = math.ScaledTransform()
	local rootPose = self:GetEntity():GetPose()
	if(DRAW_LINES) then
		local lines = {}
		for boneId,bone in pairs(skeleton:GetRootBones()) do
			self:GetLines(animC,rootPose,bone,nil,lines)
		end
		debug.draw_lines(lines,Color.Red,0.1)
	else
		for _,bone in ipairs(skeleton:GetBones()) do
			local ent = self.m_bones[bone:GetID()]
			if(util.is_valid(ent)) then
				local pose
				local parent = bone:GetParent()
				local length = 5.0
				if(parent ~= nil) then
					pose = rootPose *animC:GetEffectiveBoneTransform(parent:GetID())
					length = animC:GetBonePos(bone:GetID()):Length()
				else
					local bonePose = animC:GetEffectiveBoneTransform(bone:GetID())
					if(bonePose ~= nil) then pose = rootPose *animC:GetEffectiveBoneTransform(bone:GetID())
					else pose = rootPose end
				end
				ent:SetPose(pose)
				local orthoAxisLengthScale = 0.4
				ent:SetScale(Vector(length *orthoAxisLengthScale,length *orthoAxisLengthScale,length))
			end
		end
	end
end
ents.COMPONENT_DEBUG_SKELETON_DRAW = ents.register_component("debug_skeleton_draw",Component)
Component.EVENT_ON_BONES_CREATED = ents.register_component_event(ents.COMPONENT_DEBUG_SKELETON_DRAW,"on_bones_created")

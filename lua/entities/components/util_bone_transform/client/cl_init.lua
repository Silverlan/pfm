--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.UtilBoneTransformComponent",BaseEntityComponent)

function ents.UtilBoneTransformComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_transforms = {}
end
function ents.UtilBoneTransformComponent:OnRemove()
	for boneId,ent in pairs(self.m_transforms) do
		if(ent:IsValid()) then ent:Remove() end
	end
end
function ents.UtilBoneTransformComponent:SetTransformEnabled(boneId)
	if(type(boneId) == "string") then
		local mdl = self:GetEntity():GetModel()
		if(mdl == nil) then return end
		boneId = mdl:LookupBone(boneId)
	end
	if(boneId == -1) then return end
	if(util.is_valid(self.m_transforms[boneId])) then return self.m_transforms[boneId]:GetComponent("util_transform") end
	local ent = ents.create("util_transform")
	ent:Spawn()
	self.m_transforms[boneId] = ent

	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		local pose = animC:GetGlobalBonePose(boneId)
		if(pose ~= nil) then ent:SetPose(pose) end
	end

	local utilTransformC = ent:GetComponent("util_transform")
	if(utilTransformC ~= nil) then
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,function(pos)
			local localPos = pos:Copy()
			if(animC ~= nil) then
				local pose = animC:GetGlobalBonePose(boneId)
				pose:SetOrigin(pos)
				animC:SetGlobalBonePose(boneId,pose)

				localPos = animC:GetBonePos(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED,{boneId,pos,localPos})
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function(ang)
			local rot = ang:ToQuaternion()
			local localRot = rot:Copy()
			if(animC ~= nil) then
				local pose = animC:GetGlobalBonePose(boneId)
				pose:SetRotation(rot)
				animC:SetGlobalBonePose(boneId,pose)

				localRot = animC:GetBoneRot(boneId)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED,{boneId,rot,localRot})
		end)
		utilTransformC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED,function(scale)
			if(animC ~= nil) then
				local pose = animC:GetGlobalBonePose(boneId)
				pose:SetScale(scale)
				animC:SetGlobalBonePose(boneId,pose)
			end
			self:BroadcastEvent(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED,{boneId,scale,scale})
		end)
		utilTransformC:SetParentBone(boneId)
	end
	return ent:GetComponent("util_transform")
end
ents.COMPONENT_UTIL_BONE_TRANSFORM = ents.register_component("util_bone_transform",ents.UtilBoneTransformComponent)
ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM,"on_pos_changed")
ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM,"on_rot_changed")
ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED = ents.register_component_event(ents.COMPONENT_UTIL_BONE_TRANSFORM,"on_scale_changed")

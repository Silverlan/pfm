--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("debug_skeleton_draw")

util.register_class("ents.PFMSkeleton",BaseEntityComponent)

function ents.PFMSkeleton:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_clickCallbacks = {}
	self:BindEvent(ents.DebugSkeletonDraw.EVENT_ON_BONES_CREATED,"OnBonesCreated")
	self:AddEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
end

function ents.PFMSkeleton:OnRemove()
	self:ClearCallbacks()
	self:GetEntity():RemoveComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
end

function ents.PFMSkeleton:ClearCallbacks()
	for boneId,ent in pairs(self.m_clickCallbacks) do
		util.remove(ent)
	end
	self.m_clickCallbacks = {}
end

function ents.PFMSkeleton:OnBoneClicked(boneId,ent)

end

function ents.PFMSkeleton:OnBonesCreated()
	local c = self:GetEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)
	if(c == nil) then return end
	self:ClearCallbacks()
	for boneId,ent in pairs(c:GetBones()) do
		if(ent:IsValid()) then
			ent:AddComponent(ents.COMPONENT_BVH)
			local boneC = ent:AddComponent("pfm_bone")
			boneC:SetBoneId(boneId)
			local clickC = ent:AddComponent(ents.COMPONENT_CLICK)
			util.remove(self.m_clickCallbacks[boneId])
			self.m_clickCallbacks[boneId] = clickC:AddEventCallback(ents.ClickComponent.EVENT_ON_CLICK,function()
				if(ent:IsValid()) then self:OnBoneClicked(boneId,ent) end
			end)
		end
	end
end
ents.COMPONENT_PFM_SKELETON = ents.register_component("pfm_skeleton",ents.PFMSkeleton)

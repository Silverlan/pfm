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

	self.m_bones = {}
	self.m_clickCallbacks = {}
	self:BindEvent(ents.DebugSkeletonDraw.EVENT_ON_BONES_CREATED,"OnBonesCreated")
	self:AddEntityComponent(ents.COMPONENT_DEBUG_SKELETON_DRAW)

	local pm = tool.get_filmmaker()
	if(util.is_valid(pm)) then
		self.m_cbOnPropertSelected = pm:AddCallback("OnActorPropertySelected",function(fm,udmComponent,item,path,selected)
			self:OnActorPropertySelected(udmComponent,item,path,selected)
		end)
	end
end

function ents.PFMSkeleton:OnActorPropertySelected(udmComponent,item,path,selected)
	local actor = udmComponent:GetActor()
	if(actor:IsValid() == false or tostring(actor:GetUniqueId()) ~= tostring(self:GetEntity():GetUuid())) then return end
	local type = udmComponent:GetType()
	if(type ~= "animated" and type ~= "ik_solver") then return end
	local t = string.split(path,"/")
	if(t[1] ~= "bone" and t[1] ~= "control") then return end
	local mdl = self:GetEntity():GetModel()
	if(mdl == nil) then return end
	local skel = mdl:GetSkeleton()
	local boneId = skel:LookupBone(t[2])
	if(boneId == -1 or self.m_bones[boneId] == nil) then return end
	for childBoneId,ent in pairs(self.m_bones[boneId]) do
		if(ent:IsValid()) then
			local boneC = ent:GetComponent(ents.COMPONENT_PFM_BONE)
			if(boneC ~= nil) then boneC:SetSelected(selected) end
		end
	end
end

function ents.PFMSkeleton:OnRemove()
	util.remove(self.m_cbOnPropertSelected)
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
	self.m_bones = {}
	local solverC = self:GetEntity():GetComponent(ents.COMPONENT_IK_SOLVER)
	for boneId,tEnts in pairs(c:GetBones()) do
		for boneIdChild,ent in pairs(tEnts) do
			if(ent:IsValid()) then
				self.m_bones[boneId] = self.m_bones[boneId] or {}
				self.m_bones[boneId][boneIdChild] = ent
				ent:AddComponent(ents.COMPONENT_BVH)
				local boneC = ent:AddComponent("pfm_bone")
				boneC:SetBoneId(boneId)
				local clickC = ent:AddComponent(ents.COMPONENT_CLICK)
				util.remove(self.m_clickCallbacks[boneId])
				self.m_clickCallbacks[boneId] = clickC:AddEventCallback(ents.ClickComponent.EVENT_ON_CLICK,function()
					if(ent:IsValid()) then self:OnBoneClicked(boneId,ent) end
				end)

				if(solverC ~= nil) then
					local handle = solverC:GetControl(boneId)
					if(handle ~= nil) then
						local col = (handle.type == ents.IkSolverComponent.RigConfig.Control.TYPE_STATE) and Color.Crimson or Color.Orange
						ent:SetColor(col)
					end
				end
			end
		end
	end
end
ents.COMPONENT_PFM_SKELETON = ents.register_component("pfm_skeleton",ents.PFMSkeleton)

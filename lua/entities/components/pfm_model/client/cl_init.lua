--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMModel",BaseEntityComponent)

function ents.PFMModel:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent("pfm_actor")
	if(renderC ~= nil) then
		renderC:SetCastShadows(true)
	end

	self.m_boneTransforms = {}
	self.m_bHasBoneTransforms = false
end
function ents.PFMModel:OnEntitySpawn()
	if(self.m_bHasBoneTransforms == false) then return end
	local animSetC = self:AddEntityComponent("pfm_animation_set")
	local c = 0
	for boneId,pose in pairs(self.m_boneTransforms) do
		c = c +1
	end
	if(animSetC == nil) then return end

	-- Initialize default bone poses
	for boneId,pose in pairs(self.m_boneTransforms) do
		animSetC:SetBonePos(boneId,pose:GetOrigin())
		animSetC:SetBoneRot(boneId,pose:GetRotation())
	end

	-- Don't need these anymore
	self.m_boneTransforms = nil
	self.m_bHasBoneTransforms = false
end
function ents.PFMModel:Setup(actorData,mdlInfo)
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	local mdlName = mdlInfo:GetModelName()
	mdlC:SetModel(mdlName)
	mdlC:SetSkin(mdlInfo:GetSkin())

	local mdl = mdlC:GetModel()
	if(mdl == nil) then return end
	for _,node in ipairs(mdlInfo:GetBones()) do
		local boneId = mdl:LookupBone(node:GetName())
		if(boneId ~= -1) then
			self.m_boneTransforms[boneId] = node:GetPose()
			self.m_bHasBoneTransforms = true
		else
			pfm.log("Unknown bone '" .. node:GetName() .. "' for actor with model '" .. mdl:GetName() .. "'! Bone pose will be ignored...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
		end
	end
end
ents.COMPONENT_PFM_MODEL = ents.register_component("pfm_model",ents.PFMModel)

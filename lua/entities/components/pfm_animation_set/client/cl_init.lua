--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMAnimationSet",BaseEntityComponent)

include("channel")

ents.PFMAnimationSet.ROOT_TRANSFORM_ID = -2
function ents.PFMAnimationSet:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local animC = self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:AddEntityComponent(ents.COMPONENT_RENDER)

	-- TODO: Only add these if this is an articulated actor
	self:AddEntityComponent(ents.COMPONENT_FLEX)
	self:AddEntityComponent(ents.COMPONENT_VERTEX_ANIMATED)
	
	self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
		-- We have to apply our bone transforms every time the entity's skeleton/animations have been updated
		self:ApplyBoneTransforms()
	end)
	animC:SetAnimatedRootPoseTransformEnabled(true)

	self.m_cvAnimCache = console.get_convar("pfm_animation_cache_enabled")

	self.m_currentBoneTransforms = {}
	self.m_listeners = {}
end

function ents.PFMAnimationSet:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end

function ents.PFMAnimationSet:OnRemove()
	if(util.is_valid(self.m_cbUpdateSkeleton)) then self.m_cbUpdateSkeleton:Remove() end
end

function ents.PFMAnimationSet:SetBonePos(boneId,pos)
	self.m_currentBoneTransforms[boneId] = self.m_currentBoneTransforms[boneId] or {Vector(),Quaternion()}
	self.m_currentBoneTransforms[boneId][1] = pos
end

function ents.PFMAnimationSet:SetBoneRot(boneId,rot)
	self.m_currentBoneTransforms[boneId] = self.m_currentBoneTransforms[boneId] or {}
	self.m_currentBoneTransforms[boneId][2] = rot
end

function ents.PFMAnimationSet:SetFlexController(fcId,value)
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local fc = (mdl ~= nil) and mdl:GetFlexController(fcId) or nil -- TODO: Cache this
	local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
	if(flexC == nil or fc == nil) then return false end
	flexC:SetFlexController(fcId,pfm.translate_flex_controller_value(fc,value),0.0,self.m_flexControllerLimitsEnabled)
end

function ents.PFMAnimationSet:ApplyBoneTransforms()
	if(self.m_cvAnimCache:GetBool()) then return end
	local ent = self:GetEntity()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	local transformC = ent:GetComponent(ents.COMPONENT_TRANSFORM)

	if(transformC == nil or animC == nil) then return end
	for boneId,t in pairs(self.m_currentBoneTransforms) do
		if(t[1] ~= nil) then
			animC:SetBonePos(boneId,t[1])
		end
		if(t[2] ~= nil) then
			animC:SetBoneRot(boneId,t[2])
		end
	end
end

function ents.PFMAnimationSet:OnEntitySpawn()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:PlayAnimation("reference") -- Play reference animation to make sure animation callbacks are being called
	end
end

function ents.PFMAnimationSet:Setup(actorData,animSet)
	self.m_actorData = actorData
	self.m_mdlComponent = actorData:FindComponent("pfm_model")
	-- TODO: Update this value when it's changed, or if the model component is removed or added later
	self.m_flexControllerLimitsEnabled = true
	if(self.m_mdlComponent ~= nil) then self.m_flexControllerLimitsEnabled = self.m_mdlComponent:GetFlexControllerLimitsEnabled() end
	-- self.m_animSetData = animSet
end
ents.COMPONENT_PFM_ANIMATION_SET = ents.register_component("pfm_animation_set",ents.PFMAnimationSet)

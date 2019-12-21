--[[
    Copyright (C) 2019  Florian Weischer

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
	local actorC = self:AddEntityComponent("pfm_actor")
	self.m_translationChannel = actorC:AddChannel(ents.PFMActorComponent.TranslationChannel())
	self.m_rotationChannel = actorC:AddChannel(ents.PFMActorComponent.RotationChannel())
	self.m_boneTranslationChannel = actorC:AddChannel(ents.PFMAnimationSet.BoneTranslationChannel(self))
	self.m_boneRotationChannel = actorC:AddChannel(ents.PFMAnimationSet.BoneRotationChannel(self))
	self.m_flexControllerChannel = actorC:AddChannel(ents.PFMAnimationSet.FlexControllerChannel())

	self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
		-- We have to apply our bone transforms every time the entity's skeleton/animations have been updated
		self:ApplyBoneTransforms()
	end)

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

local function translate_flex_controller_value(fc,val)
	return fc.min +val *(fc.max -fc.min)
end

function ents.PFMAnimationSet:SetFlexController(fcId,value)
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local fc = (mdl ~= nil) and mdl:GetFlexController(fcId) or nil -- TODO: Cache this
	local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
	if(flexC == nil or fc == nil) then return false end
	flexC:SetFlexController(fcId,translate_flex_controller_value(fc,value),0.0,false)
end

function ents.PFMAnimationSet:ApplyBoneTransforms()
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
	self.m_animSetData = animSet
end
ents.COMPONENT_PFM_ANIMATION_SET = ents.register_component("pfm_animation_set",ents.PFMAnimationSet)

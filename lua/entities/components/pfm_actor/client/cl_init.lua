--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMActorComponent",BaseEntityComponent)

include("channel.lua")

function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
end

function ents.PFMActorComponent:OnRemove()
	if(util.is_valid(self.m_cbUpdateSkeleton)) then self.m_cbUpdateSkeleton:Remove() end
	if(util.is_valid(self.m_cbOnOffsetChanged)) then self.m_cbOnOffsetChanged:Remove() end
end

function ents.PFMActorComponent:OnEntitySpawn()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:PlayAnimation("reference") -- Play reference animation to make sure animation callbacks are being called
	end
end

function ents.PFMActorComponent:OnClipOffsetChanged(newOffset)

end

function ents.PFMActorComponent:ApplyTransforms()
	if(util.is_valid(self.m_clipComponent) == false) then return end
	self.m_oldOffset = self.m_oldOffset or self.m_clipComponent:GetOffset()
	local newOffset = self.m_clipComponent:GetOffset()
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset
	
	local ent = self:GetEntity()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	local mdl = mdlC:GetModel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS]:Apply(ent,newOffset)
end

function ents.PFMActorComponent:Setup(clipC,animSet)
	self.m_animationSet = animSet
	self.m_clipComponent = clipC
	
	self:GetEntity():SetName(animSet:GetName())

	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,function(newOffset)
		self:OnClipOffsetChanged(newOffset)
	end)

	print("Initializing actor '" .. self:GetEntity():GetName() .. "'...")
	local mdlInfo = animSet:GetProperty("model")
	if(mdlInfo ~= nil) then
		local mdlC = self:AddEntityComponent("pfm_model")
		mdlC:Setup(mdlInfo)
	end

	local camera = animSet:GetProperty("camera")
	if(camera ~= nil) then
		local cameraC = self:AddEntityComponent("pfm_camera")
		mdlC:Setup(camera)
	end

	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	-- TODO
	if(animC ~= nil) then
		-- TODO
		self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
			-- TODO: Do this whenever the offset changes?
			self:ApplyTransforms()
		end)
	end
	print("Done!")
end
function ents.PFMActorComponent:AddChannelTransform(channel,controllerName,time,value)
	if(self.m_channels[channel] == nil) then return end
	self.m_channels[channel]:AddTransform(controllerName,time,value)
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)

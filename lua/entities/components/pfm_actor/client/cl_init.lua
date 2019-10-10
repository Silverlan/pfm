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

	self.m_channels = {}
	self.m_translationChannel = self:AddChannel(ents.PFMActorComponent.TranslationChannel())
	self.m_rotationChannel = self:AddChannel(ents.PFMActorComponent.RotationChannel())
end

function ents.PFMActorComponent:AddChannel(channel)
	table.insert(self.m_channels,channel)
	return channel
end

function ents.PFMActorComponent:GetChannels() return self.m_channels end

function ents.PFMActorComponent:OnRemove()
	if(util.is_valid(self.m_cbOnOffsetChanged)) then self.m_cbOnOffsetChanged:Remove() end
end

function ents.PFMActorComponent:ApplyTransforms()
	if(util.is_valid(self.m_clipComponent) == false) then return end
	self.m_oldOffset = self.m_oldOffset or self.m_clipComponent:GetOffset()
	local newOffset = self.m_clipComponent:GetOffset()
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset
	
	local ent = self:GetEntity()
	for _,channel in ipairs(self:GetChannels()) do
		channel:Apply(ent,newOffset)
	end
end

function ents.PFMActorComponent:Setup(clipC,animSet)
	self.m_animationSet = animSet
	self.m_clipComponent = clipC
	
	self:GetEntity():SetName(animSet:GetName())

	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,function(newOffset)
		self:ApplyTransforms()
	end)

	print("Initializing actor '" .. self:GetEntity():GetName() .. "'...")
	local mdlInfo = animSet:GetProperty("model")
	if(mdlInfo ~= nil) then
		local mdlC = self:AddEntityComponent("pfm_model")
		mdlC:Setup(animSet,mdlInfo)
	end

	local camera = animSet:GetProperty("camera")
	if(camera ~= nil) then
		local cameraC = self:AddEntityComponent("pfm_camera")
		cameraC:Setup(animSet,camera)
	end

	local transformControls = animSet:GetTransformControls():GetValue()
	for iCtrl,ctrl in ipairs(transformControls) do
		local boneControllerName = ctrl:GetName()
		if(boneControllerName == "transform") then
			local posChannel = ctrl:GetPositionChannel()
			local log = posChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self.m_translationChannel:AddTransform(0,times[i]:GetValue(),values[i]:GetValue())
				end
			end

			local rotChannel = ctrl:GetRotationChannel()
			log = rotChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local tPrev = 0.0
				for _,t in ipairs(times) do
					tPrev = t:GetValue()
				end
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self.m_rotationChannel:AddTransform(0,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end
	print("Done!")
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)

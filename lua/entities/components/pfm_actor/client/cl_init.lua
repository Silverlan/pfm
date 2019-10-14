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

function ents.PFMActorComponent:Setup(clipC,actorData)
	self.m_clipComponent = clipC
	
	self:GetEntity():SetName(actorData:GetName())

	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,function(newOffset)
		self:ApplyTransforms()
	end)

	print("Initializing components for actor '" .. self:GetEntity():GetName() .. "'...")
	for _,value in ipairs(actorData:GetComponents():GetValue()) do
		local componentData = value:GetValue()
		local err
		if(componentData.GetComponentName == nil) then
			err = "Component is missing method 'GetComponentName'"
		end
		if(err ~= nil) then
			pfm.log("Attempted to add malformed component '" .. componentData:GetTypeName() .. "' to actor '" .. self:GetEntity():GetName() .. "': " .. err .. "!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_ERROR)
		else
			local c = self:AddEntityComponent(componentData:GetComponentName())
			if(c == nil) then pfm.log("Attempted to add unknown component '" .. componentData:GetComponentName() .. "' to actor '" .. self:GetEntity():GetName() .. "'!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
			else c:Setup(actorData,componentData) end
		end
	end
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)

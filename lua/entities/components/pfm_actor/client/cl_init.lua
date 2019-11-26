--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMActorComponent",BaseEntityComponent)

include("channel.lua") -- TODO: This is obsolete; Remove the channels!

function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
	self.m_channels = {}
	self.m_listeners = {}
end

function ents.PFMActorComponent:AddChannel(channel)
	table.insert(self.m_channels,channel)
	return channel
end

function ents.PFMActorComponent:GetChannels() return self.m_channels end
function ents.PFMActorComponent:GetActorData() return self.m_actorData end

function ents.PFMActorComponent:OnRemove()
	for _,listener in ipairs(self.m_listeners) do
		if(listener:IsValid()) then listener:Remove() end
	end
end

function ents.PFMActorComponent:OnEntitySpawn()
	local actorData = self:GetActorData()

	local ent = self:GetEntity()
	ent:SetPose(actorData:GetAbsolutePose())
	local t = actorData:GetTransform()
	table.insert(self.m_listeners,t:GetPositionAttr():AddChangeListener(function(newPos)
		ent:SetPose(actorData:GetAbsolutePose())
	end))
	table.insert(self.m_listeners,t:GetRotationAttr():AddChangeListener(function(newRot)
		ent:SetPose(actorData:GetAbsolutePose())
	end))
	table.insert(self.m_listeners,t:GetScaleAttr():AddChangeListener(function(newScale)
		ent:SetPose(actorData:GetAbsolutePose())
	end))
end

function ents.PFMActorComponent:OnOffsetChanged(clipOffset)
	local actorData = self:GetActorData()
	local ent = self:GetEntity()
	ent:SetPose(actorData:GetAbsolutePose())
	--print(ent,ent:GetPos())
	--[[self.m_oldOffset = self.m_oldOffset or clipOffset
	local newOffset = clipOffset
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset

	print("NEW OFFSET")
	
	local ent = self:GetEntity()
	for _,channel in ipairs(self:GetChannels()) do
		channel:Apply(ent,newOffset)
	end]]
end

function ents.PFMActorComponent:Setup(actorData)
	self.m_actorData = actorData
	self:GetEntity():SetName(actorData:GetName())

	pfm.log("Initializing " .. #actorData:GetComponents() .. " components for actor '" .. self:GetEntity():GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	for _,value in ipairs(actorData:GetComponents():GetTable()) do
		local componentData = value
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

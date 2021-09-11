--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_channel.lua")

fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP = fudm.register_element("PFMChannelClip")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,"timeFrame",fudm.PFMTimeFrame())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,"channels",fudm.Array(fudm.ELEMENT_TYPE_PFM_CHANNEL))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,"actor",fudm.String())

function fudm.PFMChannelClip:SetPlaybackOffset(offset,filter)
	--if(self:GetTimeFrame():IsInTimeFrame(offset) == false) then return end
	local timeFrame = self:GetTimeFrame()
	local localOffset = timeFrame:LocalizeOffset(offset)
	for _,channel in ipairs(self:GetChannels():GetTable()) do
		if(filter == nil or filter(channel) == true) then
			channel:SetPlaybackOffset(localOffset)
		end
	end
end

function fudm.PFMChannelClip:FindChannel(path)
	for _,channel in ipairs(self:GetChannels():GetTable()) do
		if(channel:GetTargetPath() == path) then return channel end
	end
end

function fudm.PFMChannelClip:GetChannel(path,type,addIfNotExists)
	local channel = self:FindChannel(path)
	if(channel ~= nil) then return channel end
	if(addIfNotExists ~= true) then return end
	channel = self:AddChannel(type)
	channel:SetTargetPath(path)
	return channel
end

function fudm.PFMChannelClip:AddChannel(type)
	local channel = self:CreateChild(fudm.ELEMENT_TYPE_PFM_CHANNEL)
	local log = channel:GetLog()
	local layer = log:CreateChild(fudm.ELEMENT_TYPE_PFM_LOG_LIST)
	layer:GetValuesAttr():SetValueType(type)
	log:GetLayers():PushBack(layer)
	self:GetChannelsAttr():PushBack(channel)
	return channel
end

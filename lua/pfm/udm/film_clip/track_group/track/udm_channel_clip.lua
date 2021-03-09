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

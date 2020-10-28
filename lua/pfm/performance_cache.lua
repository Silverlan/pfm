--[[
    Copyright (C) 2020  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- Note: Actor animations are currently cached through a separate system, however cameras don't have animation support yet, so we have to handle them
-- separately for now, which we'll do here. Once camera animations are supported, this class can be removed.

pfm = pfm or {}

util.register_class("pfm.PerformanceCache")

function pfm.PerformanceCache:__init()
end

function pfm.PerformanceCache:Initialize(filmClip)
	local cam = filmClip:GetProperty("camera")
	local animChannelTrack = filmClip:FindAnimationChannelTrack()
	if(cam == nil or animChannelTrack == nil) then return end
	local posChannelClip
	local posChannel
	local rotChannelClip
	local rotChannel
	for _,channelClip in ipairs(animChannelTrack:GetChannelClips():GetTable()) do
		for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
			local toElement = channel:GetToElement()
			if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM) then
				local parent = toElement:FindParentElement(function(el) return el:GetType() == udm.ELEMENT_TYPE_PFM_ACTOR end)
				if(util.is_same_object(parent,cam)) then
					local attr = channel:GetToAttribute()
					if(attr == "position") then
						posChannelClip = channelClip
						posChannel = channel
					elseif(attr == "rotation") then
						rotChannelClip = channelClip
						rotChannel = channel
					end
				end
			end
		end
	end
	self.m_camPosChannelClip = posChannelClip
	self.m_camRotChannelClip = rotChannelClip
	self.m_camPosChannel = posChannel
	self.m_camRotChannel = rotChannel
end

function pfm.PerformanceCache:SetOffset(gameViewFilmClip,offset)
	if(self.m_lastGameViewFilmClip == nil or util.is_same_object(gameViewFilmClip,self.m_lastGameViewFilmClip) == false) then
		self.m_lastGameViewFilmClip = gameViewFilmClip
		self:Initialize(gameViewFilmClip)
	end
	if(self.m_camPosChannel ~= nil) then
		self.m_camPosChannel:SetPlaybackOffset(self.m_camPosChannelClip:GetTimeFrame():LocalizeOffset(offset))
	end
	if(self.m_camRotChannel ~= nil) then
		self.m_camRotChannel:SetPlaybackOffset(self.m_camRotChannelClip:GetTimeFrame():LocalizeOffset(offset))
	end
end

function pfm.PerformanceCache:Clear()
	self.m_camPosChannel = nil
	self.m_camRotChannel = nil
end

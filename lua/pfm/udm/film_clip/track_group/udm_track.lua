--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track")

udm.ELEMENT_TYPE_PFM_TRACK = udm.register_element("PFMTrack")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"audioClips",udm.Array(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"filmClips",udm.Array(udm.ELEMENT_TYPE_PFM_FILM_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"overlayClips",udm.Array(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"channelClips",udm.Array(udm.ELEMENT_TYPE_PFM_CHANNEL_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"muted",udm.Bool(false),{
	getter = "IsMuted"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"volume",udm.Float(1.0))

function udm.PFMTrack:CalcTimeFrame()
	local timeFrame = udm.PFMTimeFrame()
	for _,filmClip in ipairs(self:GetFilmClips():GetTable()) do
		timeFrame = timeFrame:Max(filmClip:GetTimeFrame())
	end
	return timeFrame
end

function udm.PFMTrack:AddAudioClip(clip)
	if(type(clip) == "string") then
		local name = clip
		clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,name)
	end
	self:GetAudioClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddFilmClip(clip)
	if(type(clip) == "string") then
		local name = clip
		clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_FILM_CLIP,name)
	end
	self:GetFilmClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddOverlayClip(clip)
	if(type(clip) == "string") then
		local name = clip
		clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,name)
	end
	self:GetOverlayClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddChannelClip(clip)
	if(type(clip) == "string") then
		local name = clip
		clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,name)
	end
	self:GetChannelClipsAttr():PushBack(clip)
	return clip
end

function udm.PFMTrack:CalcBonePose(transform,t)
	local posLayer,posChannel,posChannelClip
	local rotLayer,rotChannel,rotChannelClip
	self.m_cachedBoneLayer = self.m_cachedBoneLayer or {}
	if(self.m_cachedBoneLayer[transform] ~= nil) then
		posLayer,posChannel,posChannelClip = unpack(self.m_cachedBoneLayer[transform].position)
		rotLayer,rotChannel,rotChannelClip = unpack(self.m_cachedBoneLayer[transform].rotation)
	else
		posLayer,posChannel,posChannelClip = self:FindBoneChannelLayer(transform,"position")
		rotLayer,rotChannel,rotChannelClip = self:FindBoneChannelLayer(transform,"rotation")
		self.m_cachedBoneLayer[transform] = {
			position = {posLayer,posChannel,posChannelClip},
			rotation = {rotLayer,rotChannel,rotChannelClip}
		}
	end

	-- We need the time relative to the respective channel clip
	local tPos = (posChannelClip ~= nil) and (t -posChannelClip:GetTimeFrame():GetStart()) or t
	local tRot = (rotChannelClip ~= nil) and (t -rotChannelClip:GetTimeFrame():GetStart()) or t

	local pos = (posLayer ~= nil) and posLayer:CalcInterpolatedValue(tPos) or Vector()
	local rot = (rotLayer ~= nil) and rotLayer:CalcInterpolatedValue(tRot) or Quaternion()
	return phys.ScaledTransform(pos,rot,Vector(1,1,1))
end

function udm.PFMTrack:FindBoneChannelLayer(transform,attribute)
	local channel,channelClip = self:FindBoneChannel(transform,attribute)
	local log = (channel ~= nil) and channel:GetLog() or nil
	if(log ~= nil) then return log:GetLayers():Get(1),channel,channelClip end
end

function udm.PFMTrack:SetPlaybackOffset(localOffset,absOffset,filter)
	for _,filmClip in ipairs(self:GetFilmClips():GetTable()) do
		filmClip:SetPlaybackOffset(absOffset,filter)
	end

	for _,channelClip in ipairs(self:GetChannelClips():GetTable()) do
		channelClip:SetPlaybackOffset(localOffset,filter)
	end
end

function udm.PFMTrack:FindFlexControllerChannel(flexWeight)
	for _,channelClip in ipairs(self:GetChannelClips():GetTable()) do
		for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
			local toElement = channel:GetToElement()
			if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR) then
				local flexWeightTo = toElement:FindModelFlexWeight()
				if(util.is_same_object(flexWeight,flexWeightTo)) then
					return channel,channelClip
				end
			end
		end
	end
end

function udm.PFMTrack:FindBoneChannel(transform,attribute)
	for _,channelClip in ipairs(self:GetChannelClips():GetTable()) do
		for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
			local toElement = channel:GetToElement()
			if(toElement ~= nil and toElement:GetType() == udm.ELEMENT_TYPE_TRANSFORM) then
				if(util.is_same_object(toElement,transform)) then
					if(attribute == nil or channel:GetToAttribute() == attribute) then
						return channel,channelClip
					end
				end
			end
		end
	end
end

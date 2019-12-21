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
function udm.PFMTrack:AddAudioClip(name)
	local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,name)
	self:GetAudioClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddFilmClip(name)
	local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_FILM_CLIP,name)
	self:GetFilmClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddOverlayClip(name)
	local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,name)
	self:GetOverlayClipsAttr():PushBack(clip)
	return clip
end
function udm.PFMTrack:AddChannelClip(name)
	local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,name)
	self:GetChannelClipsAttr():PushBack(clip)
	return clip
end

function udm.PFMTrack:SetPlaybackOffset(localOffset,absOffset)
	for _,filmClip in ipairs(self:GetFilmClips():GetTable()) do
		filmClip:SetPlaybackOffset(absOffset)
	end

	for _,channelClip in ipairs(self:GetChannelClips():GetTable()) do
		channelClip:SetPlaybackOffset(localOffset)
	end
end

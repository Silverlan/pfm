--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMChannelClip",BaseEntityComponent)

function ents.PFMChannelClip:Initialize()
	BaseEntityComponent.Initialize(self)
end

function ents.PFMChannelClip:OnRemove()
end

function ents.PFMChannelClip:Setup(channelClipData,trackC)
	self.m_channelClipData = channelClipData
	self.m_track = trackC
	self:GetEntity():SetName(channelClipData:GetName())

	local trackGroupC = util.is_valid(trackC) and trackC:GetTrackGroup() or nil
	local filmClipC = util.is_valid(trackGroupC) and trackGroupC:GetFilmClip() or nil
	local actor = util.is_valid(filmClipC) and filmClipC:FindActorByName(self:GetEntity():GetName()) or nil
	if(util.is_valid(actor) == false) then return end
	self.m_targetActor = actor
end

function ents.PFMChannelClip:GetChannelClipData() return self.m_channelClipData end
function ents.PFMChannelClip:GetTrack() return self.m_track end

function ents.PFMChannelClip:GetTimeFrame()
	local clip = self:GetChannelClipData()
	if(clip == nil) then return udm.PFMTimeFrame() end
	return clip:GetTimeFrame()
end

function ents.PFMChannelClip:SetOffset(offset)
	local timeFrame = self:GetTimeFrame()
	offset = offset -timeFrame:GetStart() +timeFrame:GetOffset()

	if(util.is_valid(self.m_targetActor)) then
		local actorC = self.m_targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if(actorC ~= nil) then actorC:OnOffsetChanged(offset) end
	end
end
ents.COMPONENT_PFM_CHANNEL_CLIP = ents.register_component("pfm_channel_clip",ents.PFMChannelClip)

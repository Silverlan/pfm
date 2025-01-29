--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMAudioClip", BaseEntityComponent)
function ents.PFMAudioClip:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_offset = 0.0
end

function ents.PFMAudioClip:OnRemove()
	if util.is_valid(self.m_sound) then
		self.m_sound:Remove()
	end
end

function ents.PFMAudioClip:GetAudioClipData()
	return self.m_audioClipData
end
function ents.PFMAudioClip:GetTrack()
	return self.m_track
end

function ents.PFMAudioClip:Setup(audioClip, trackC)
	self.m_audioClipData = audioClip
	self.m_track = trackC

	local soundData = audioClip:GetSound()
	local ent = self:GetEntity():CreateChild("pfm_sound_source")
	local sndC = ent:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
	if sndC ~= nil then
		sndC:Setup(self, soundData)
	end
	ent:Spawn()
	self.m_sound = ent
end

function ents.PFMAudioClip:GetTimeFrame()
	local clip = self:GetAudioClipData()
	if clip == nil then
		return fudm.PFMTimeFrame()
	end
	return clip:GetTimeFrame()
end

function ents.PFMAudioClip:GetOffset()
	return self.m_offset
end
function ents.PFMAudioClip:SetOffset(offset)
	local timeFrame = self:GetTimeFrame()
	offset = offset - timeFrame:GetStart()
	if offset == self.m_offset then
		return
	end
	self.m_offset = offset

	if util.is_valid(self.m_sound) then
		local soundC = self.m_sound:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
		if soundC ~= nil then
			soundC:OnOffsetChanged(offset)
		end
	end
end

ents.register_component("pfm_audio_clip", ents.PFMAudioClip, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMSoundSource", BaseEntityComponent)

local g_audioEnabled = false
ents.PFMSoundSource.set_audio_enabled = function(enabled)
	g_audioEnabled = enabled
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PFM_SOUND_SOURCE) }) do
		local sndC = ent:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
		if sndC ~= nil then
			if g_audioEnabled then
				sndC:Play()
			else
				sndC:Pause()
			end
		end
	end
end
function ents.PFMSoundSource:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_SOUND)
	self.m_playing = false
end

function ents.PFMSoundSource:OnRemove()
	if util.is_valid(self.m_cbOnOffsetChanged) then
		self.m_cbOnOffsetChanged:Remove()
	end
end

function ents.PFMSoundSource:OnEntitySpawn()
	if g_audioEnabled then
		local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
		if sndC ~= nil then
			sndC:SetPlayOnSpawn(true)
		end
	end
end

function ents.PFMSoundSource:Setup(clipC, sndInfo)
	self.m_clipComponent = clipC
	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED, function(offset)
		self:OnOffsetChanged(offset)
		return util.EVENT_REPLY_UNHANDLED
	end)

	local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndC ~= nil then
		sndC:SetSoundSource(sndInfo:GetSoundName())
		sndC:SetRelativeToListener(true)
		sndC:SetPitch(sndInfo:GetPitch())
		sndC:SetGain(sndInfo:GetVolume())
	end
end

function ents.PFMSoundSource:Play()
	self.m_playing = true
	local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndC ~= nil then
		sndC:SetOffset(self.m_clipComponent:GetOffset())
		sndC:Play()
	end
end

function ents.PFMSoundSource:Pause()
	self.m_playing = false
	local sndC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if sndC ~= nil then
		sndC:Pause()
	end
end

function ents.PFMSoundSource:OnOffsetChanged(offset)
	local soundC = self:GetEntity():GetComponent(ents.COMPONENT_SOUND)
	if soundC == nil then
		return
	end
	local snd = soundC:GetSound()
	if snd == nil then
		return
	end
	if snd:IsPlaying() == false and self.m_playing then
		-- Sound has probably reached its end, but we may have changed its offset to before
		-- its end time, so we'll restart it here
		-- TODO: Find a better solution
		snd:Play()
		snd:SetOffset(offset)
		return
	end

	if math.abs(offset - snd:GetOffset()) > 0.05 then
		snd:SetOffset(offset)
	end
end
ents.register_component(
	"pfm_sound_source",
	ents.PFMSoundSource,
	"pfm",
	ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR
)

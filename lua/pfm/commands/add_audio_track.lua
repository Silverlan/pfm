-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandAddAudioTrack", pfm.Command)
function Command:Initialize(name, targetFilmClip)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("name", udm.TYPE_STRING, name)
	data:SetValue("targetFilmClip", udm.TYPE_STRING, pfm.get_unique_id(targetFilmClip))
	data:SetValue("uuid", udm.TYPE_STRING, tostring(util.generate_uuid_v4())) -- We need to make sure the uuid is consistent every time
	return true
end
function Command:DoExecute(data)
	local filmClipUuid = data:GetValue("targetFilmClip", udm.TYPE_STRING)
	local targetFilmClip = pfm.dereference(filmClipUuid)
	if targetFilmClip == nil then
		self:LogFailure("Target FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end

	local name = data:GetValue("name", udm.TYPE_STRING)
	local uuid = data:GetValue("uuid", udm.TYPE_STRING)
	local newTrack = targetFilmClip:AddAudioTrack(name, uuid)
	if newTrack == nil then
		self:LogFailure("Failed to add audio track to FilmClip!")
		return false
	end
	return newTrack
end
function Command:DoUndo(data)
	local filmClipUuid = data:GetValue("targetFilmClip", udm.TYPE_STRING)
	local targetFilmClip = pfm.dereference(filmClipUuid)
	if targetFilmClip == nil then
		self:LogFailure("Target FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	local uuid = data:GetValue("uuid", udm.TYPE_STRING)
	local audioTrack = pfm.dereference(uuid)
	if audioTrack == nil then
		self:LogFailure("AudioTrack '" .. uuid .. "' not found!")
		return false
	end
	return targetFilmClip:RemoveAudioTrack(audioTrack)
end
pfm.register_command("add_audio_track", Command)

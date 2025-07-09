-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("add_audio_clip.lua")

local Command = util.register_class("pfm.CommandDeleteAudioClip", pfm.Command)
function Command:Initialize(audioClip)
	local data = self:GetData()
	local track = audioClip:GetParent()
	data:SetValue("targetTrack", udm.TYPE_STRING, tostring(track:GetUniqueId()))
	local acData = audioClip:GetUdmData()
	-- Serialize the audio clip data
	data:Add("audioClip"):Merge(acData, udm.MERGE_FLAG_BIT_DEEP_COPY)
end
function Command:DoExecute(data)
	local trackUuid = data:GetValue("targetTrack", udm.TYPE_STRING)
	local track = pfm.dereference(trackUuid)
	if track == nil then
		self:LogFailure("Track '" .. trackUuid .. "' not found!")
		return false
	end
	local udmAudioClip = data:Get("audioClip")
	local audioClip = pfm.dereference(udmAudioClip:GetValue("uniqueId", udm.TYPE_STRING))
	if audioClip == nil then
		self:LogFailure("AudioClip '" .. udmAudioClip:GetValue("uniqueId", udm.TYPE_STRING) .. "' not found!")
		return false
	end
	return track:RemoveGenericAudioClip(audioClip)
end
function Command:DoUndo(data)
	local trackUuid = data:GetValue("targetTrack", udm.TYPE_STRING)
	local track = pfm.dereference(trackUuid)
	if track == nil then
		self:LogFailure("Track '" .. trackUuid .. "' not found!")
		return false
	end
	local udmAudioClip = data:Get("audioClip")
	local audioClip = track:AddAudioClip()
	audioClip:Reinitialize(udmAudioClip)
	track:AddGenericAudioClip(audioClip)
	return audioClip
end
pfm.register_command("delete_audio_clip", Command)

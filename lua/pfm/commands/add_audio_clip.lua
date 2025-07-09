-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandAddAudioClip", pfm.Command)
function Command:Initialize(track, name, filePath, startTime, duration)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("name", udm.TYPE_STRING, name)
	data:SetValue("filePath", udm.TYPE_STRING, filePath)
	data:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	data:SetValue("duration", udm.TYPE_FLOAT, duration)
	data:SetValue("targetTrack", udm.TYPE_STRING, pfm.get_unique_id(track))
	data:SetValue("uuid", udm.TYPE_STRING, tostring(util.generate_uuid_v4())) -- We need to make sure the uuid is consistent every time
	return true
end
function Command:AddAudioClip(data)
	local trackUuid = data:GetValue("targetTrack", udm.TYPE_STRING)
	local targetTrack = pfm.dereference(trackUuid)
	if targetTrack == nil then
		self:LogFailure("Target FilmClip '" .. trackUuid .. "' not found!")
		return false
	end

	local name = data:GetValue("name", udm.TYPE_STRING)
	local soundPath = data:GetValue("filePath", udm.TYPE_STRING)
	local startTime = data:GetValue("startTime", udm.TYPE_FLOAT)
	local duration = data:GetValue("duration", udm.TYPE_FLOAT)
	local uuid = data:GetValue("uuid", udm.TYPE_STRING)
	return targetTrack:AddGenericAudioClip(name, soundPath, startTime, duration, uuid)
end
function Command:RemoveAudioClip(data)
	local trackUuid = data:GetValue("targetTrack", udm.TYPE_STRING)
	local targetTrack = pfm.dereference(trackUuid)
	if targetTrack == nil then
		self:LogFailure("Target FilmClip '" .. trackUuid .. "' not found!")
		return false
	end

	local uuid = data:GetValue("uuid", udm.TYPE_STRING)
	local audioClip = pfm.dereference(uuid)
	if audioClip == nil then
		self:LogFailure("AudioClip '" .. uuid .. "' not found!")
		return false
	end
	return targetTrack:RemoveGenericAudioClip(audioClip)
end
function Command:DoExecute(data)
	return self:AddAudioClip(data)
end
function Command:DoUndo(data)
	return self:RemoveAudioClip(data)
end
pfm.register_command("add_audio_clip", Command)

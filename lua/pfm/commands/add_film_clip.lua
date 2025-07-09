-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandAddFilmClip", pfm.Command)
function Command:Initialize(name, targetFilmClip, placeBeforeTarget)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("name", udm.TYPE_STRING, name)
	data:SetValue("targetFilmClip", udm.TYPE_STRING, pfm.get_unique_id(targetFilmClip))
	data:SetValue("placeBeforeTarget", udm.TYPE_BOOLEAN, placeBeforeTarget)
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

	local track = targetFilmClip:GetTrack()
	local placeBefore = data:GetValue("placeBeforeTarget", udm.TYPE_BOOLEAN)
	local uuid = data:GetValue("uuid", udm.TYPE_STRING)
	local newFc
	if placeBefore then
		newFc = track:InsertFilmClipBefore(targetFilmClip, uuid)
	else
		newFc = track:InsertFilmClipAfter(targetFilmClip, uuid)
	end

	newFc:SetName(data:GetValue("name", udm.TYPE_STRING))
	return newFc
end
function Command:DoUndo(data)
	local filmClipUuid = data:GetValue("uuid", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end

	local track = filmClip:GetTrack()
	track:ClearFilmClip(filmClip)
end
pfm.register_command("add_film_clip", Command)

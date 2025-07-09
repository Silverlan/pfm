-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandMoveFilmClip", pfm.Command)
function Command:Initialize(filmClip, moveToLeft)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("filmClip", udm.TYPE_STRING, pfm.get_unique_id(filmClip))
	data:SetValue("moveToLeft", udm.TYPE_BOOLEAN, moveToLeft)
	return true
end
function Command:DoExecute(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	local track = filmClip:GetTrack()
	if data:GetValue("moveToLeft", udm.TYPE_BOOLEAN) then
		track:MoveFilmClipToLeft(filmClip)
	else
		track:MoveFilmClipToRight(filmClip)
	end
end
function Command:DoUndo(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	local track = filmClip:GetTrack()
	if data:GetValue("moveToLeft", udm.TYPE_BOOLEAN) then
		track:MoveFilmClipToRight(filmClip)
	else
		track:MoveFilmClipToLeft(filmClip)
	end
end
pfm.register_command("move_film_clip", Command)

-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandDeleteFilmClip", pfm.Command)
function Command:Initialize(filmClip)
	pfm.Command.Initialize(self)
	local data = self:GetData()

	local fcData = data:Add("data")
	fcData:Merge(filmClip:GetUdmData(), udm.MERGE_FLAG_BIT_DEEP_COPY)

	local track = filmClip:GetTrack()
	data:SetValue("track", udm.TYPE_STRING, tostring(track:GetUniqueId()))
	data:SetValue("uuid", udm.TYPE_STRING, tostring(filmClip:GetUniqueId()))

	return true
end
function Command:DoExecute(data)
	local filmClipUuid = data:GetValue("uuid", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end

	local track = filmClip:GetTrack()
	track:ClearFilmClip(filmClip)
	return true
end
function Command:DoUndo(data)
	local trackUuid = data:GetValue("track", udm.TYPE_STRING)
	local track = pfm.dereference(trackUuid)
	if track == nil then
		self:LogFailure("Track '" .. trackUuid .. "' not found!")
		return false
	end

	local newFc = track:AddFilmClip()
	newFc:Reinitialize(data:Get("data"))
	track:CallChangeListeners("OnFilmClipAdded", newFc)

	return true
end
pfm.register_command("delete_film_clip", Command)

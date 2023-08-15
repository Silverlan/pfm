--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetFilmClipDuration", pfm.Command)
function Command:Initialize(filmClip, oldDuration, newDuration)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("filmClip", udm.TYPE_STRING, pfm.get_unique_id(filmClip))
	data:SetValue("oldDuration", udm.TYPE_FLOAT, oldDuration)
	data:SetValue("newDuration", udm.TYPE_FLOAT, newDuration)
	return true
end
function Command:ApplyDuration(data, keyName)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	filmClip:GetTimeFrame():SetDuration(data:GetValue(keyName, udm.TYPE_FLOAT))
	local track = filmClip:GetParent()
	track:UpdateFilmClipTimeFrames()
	return true
end
function Command:DoExecute(data)
	return self:ApplyDuration(data, "newDuration")
end
function Command:DoUndo(data)
	return self:ApplyDuration(data, "oldDuration")
end
pfm.register_command("set_film_clip_duration", Command)

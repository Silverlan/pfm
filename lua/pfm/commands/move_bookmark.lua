--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandMoveBookmark", pfm.Command)
function Command:Initialize(filmClip, bmSetName, timeOld, timeNew)
	pfm.Command.Initialize(self)

	local filmClipUuid = pfm.get_unique_id(filmClip)
	filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local bmSet = filmClip:FindBookmarkSet(bmSetName)
	if bmSet ~= nil then
		local bm = bmSet:FindBookmark(timeOld)
		if bm == nil then
			return pfm.Command.RESULT_NO_OP
		end
	end

	local data = self:GetData()
	data:SetValue("filmClip", udm.TYPE_STRING, filmClipUuid)
	data:SetValue("bookmarkSet", udm.TYPE_STRING, bmSetName)
	data:SetValue("oldTime", udm.TYPE_FLOAT, timeOld)
	data:SetValue("timeNew", udm.TYPE_FLOAT, timeNew)
	return pfm.Command.RESULT_SUCCESS
end
function Command:UpdateBookmark(data, oldTimeKey, newTimeKey)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return
	end
	local bmSetName = data:GetValue("bookmarkSet", udm.TYPE_STRING)
	local bmSet = filmClip:FindBookmarkSet(bmSetName)
	if bmSet == nil then
		self:LogFailure("Bookmark set '" .. bmSetName .. "' not found!")
		return
	end

	local oldTime = data:GetValue(oldTimeKey, udm.TYPE_FLOAT)
	local newTime = data:GetValue(newTimeKey, udm.TYPE_FLOAT)
	local bm = bmSet:FindBookmark(oldTime)
	if bm == nil then
		self:LogFailure("Bookmark at timestamp " .. oldTime .. " in bookmark set '" .. bmSetName .. "' not found!")
		return
	end
	bm:SetTime(newTime)
end
function Command:DoExecute(data)
	return self:UpdateBookmark(data, "oldTime", "newTime")
end
function Command:DoUndo(data)
	return self:UpdateBookmark(data, "newTime", "oldTime")
end
pfm.register_command("move_bookmark", Command)

--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateBookmark", pfm.Command)
function Command:Initialize(filmClip, bmSetName, timestamp)
	pfm.Command.Initialize(self)

	local filmClipUuid = pfm.get_unique_id(filmClip)
	filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	self:AddSubCommand("create_bookmark_set", filmClip, bmSetName)

	local bmSet = filmClip:FindBookmarkSet(bmSetName)
	if bmSet ~= nil then
		local bm = bmSet:FindBookmark(timestamp)
		if bm ~= nil then
			-- Bookmark already exists
			return pfm.Command.RESULT_NO_OP
		end
	end

	local data = self:GetData()
	data:SetValue("filmClip", udm.TYPE_STRING, filmClipUuid)
	data:SetValue("bookmarkSet", udm.TYPE_STRING, bmSetName)
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
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
	local t = data:GetValue("timestamp", udm.TYPE_FLOAT)
	pfm.log("Adding bookmark at timestamp " .. t, pfm.LOG_CATEGORY_PFM)
	return bmSet:AddBookmarkAtTimestamp(t)
end
function Command:DoUndo(data)
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
	local t = data:GetValue("timestamp", udm.TYPE_FLOAT)
	pfm.log("Removing bookmark at timestamp " .. t, pfm.LOG_CATEGORY_PFM)
	bmSet:RemoveBookmarkAtTimestamp(t)
end
pfm.register_command("create_bookmark", Command)

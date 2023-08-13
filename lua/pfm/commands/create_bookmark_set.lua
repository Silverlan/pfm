--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateBookmarkSet", pfm.Command)
function Command:Initialize(filmClip, bmSetName)
	pfm.Command.Initialize(self)

	local filmClipUuid = pfm.get_unique_id(filmClip)
	filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local bmSet = filmClip:FindBookmarkSet(bmSetName)
	if bmSet ~= nil then
		-- Bookmark set already exists
		return pfm.Command.RESULT_NO_OP
	end

	local data = self:GetData()
	data:SetValue("filmClip", udm.TYPE_STRING, filmClipUuid)
	data:SetValue("bookmarkSetName", udm.TYPE_STRING, bmSetName)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	local setName = data:GetValue("bookmarkSetName", udm.TYPE_STRING)
	local bmSet = filmClip:FindBookmarkSet(setName)
	if bmSet ~= nil then
		self:LogFailure("BookmarkSet " .. setName .. " already exists!")
		return false
	end
	local bmSet = filmClip:AddBookmarkSet()
	bmSet:SetName(setName)
	return true
end
function Command:DoUndo(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(data:GetValue("filmClip", udm.TYPE_STRING))
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end
	local setName = data:GetValue("bookmarkSetName", udm.TYPE_STRING)
	local setIndex = data:GetValue("bookmarkSetIndex", udm.TYPE_UINT32)
	local bmSet = filmClip:FindBookmarkSet(setIndex)
	if bmSet == nil then
		self:LogFailure("BookmarkSet " .. setName .. " doesn't exists!")
		return false
	end
	filmClip:RemoveBoomarkSet(bmSet)
	return true
end
pfm.register_command("create_bookmark_set", Command)

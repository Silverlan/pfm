-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("create_bookmark.lua")

local Command = util.register_class("pfm.DeleteCreateBookmark", pfm.CommandCreateBookmark)
function Command:Initialize(...)
	return pfm.CommandCreateBookmark.Initialize(self, ...)
end
function Command:DoExecute(...)
	return pfm.CommandCreateBookmark.DoUndo(self, ...)
end
function Command:DoUndo(...)
	return pfm.CommandCreateBookmark.DoExecute(self, ...)
end
pfm.register_command("delete_bookmark", Command)

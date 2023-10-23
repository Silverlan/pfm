--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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

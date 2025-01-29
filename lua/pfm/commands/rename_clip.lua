--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandRenameClip", pfm.Command)
function Command:Initialize(clip, oldName, newName)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("clip", udm.TYPE_STRING, pfm.get_unique_id(clip))
	data:SetValue("oldName", udm.TYPE_STRING, oldName)
	data:SetValue("newName", udm.TYPE_STRING, newName)
	return true
end
function Command:ApplyName(data, keyName)
	local clipUuid = data:GetValue("clip", udm.TYPE_STRING)
	local clip = pfm.dereference(clipUuid)
	if clip == nil then
		self:LogFailure("Clip '" .. clipUuid .. "' not found!")
		return false
	end
	clip:SetName(data:GetValue(keyName, udm.TYPE_STRING))
	return true
end
function Command:DoExecute(data)
	return self:ApplyName(data, "newName")
end
function Command:DoUndo(data)
	return self:ApplyName(data, "oldName")
end
pfm.register_command("rename_clip", Command)

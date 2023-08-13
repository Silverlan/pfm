--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandRenameCollection", pfm.Command)
function Command:Initialize(groupUuid, oldName, newName)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("group", udm.TYPE_STRING, pfm.get_unique_id(groupUuid))
	data:SetValue("oldName", udm.TYPE_STRING, oldName)
	data:SetValue("newName", udm.TYPE_STRING, newName)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local group = pfm.dereference(data:GetValue("group", udm.TYPE_STRING))
	if group == nil then
		return false
	end
	group:SetName(data:GetValue("newName", udm.TYPE_STRING))
end
function Command:DoUndo(data)
	local group = pfm.dereference(data:GetValue("group", udm.TYPE_STRING))
	if group == nil then
		return false
	end
	group:SetName(data:GetValue("oldName", udm.TYPE_STRING))
end
pfm.register_command("rename_collection", Command)

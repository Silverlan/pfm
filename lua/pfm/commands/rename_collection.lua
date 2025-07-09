-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
pfm.register_command("rename_actor", Command)

--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandMoveActorToCollection", pfm.Command)
function Command:Initialize(actor, oldCollection, newCollection)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, pfm.get_unique_id(actor))
	data:SetValue("oldCollection", udm.TYPE_STRING, pfm.get_unique_id(oldCollection))
	data:SetValue("newCollection", udm.TYPE_STRING, pfm.get_unique_id(newCollection))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	local oldCollection = pfm.dereference(data:GetValue("oldCollection", udm.TYPE_STRING))
	local newCollection = pfm.dereference(data:GetValue("newCollection", udm.TYPE_STRING))
	if actor == nil or oldCollection == nil or newCollection == nil then
		return false
	end
	return oldCollection:MoveActorTo(actor, newCollection)
end
function Command:DoUndo(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	local oldCollection = pfm.dereference(data:GetValue("oldCollection", udm.TYPE_STRING))
	local newCollection = pfm.dereference(data:GetValue("newCollection", udm.TYPE_STRING))
	if actor == nil or oldCollection == nil or newCollection == nil then
		return false
	end
	return newCollection:MoveActorTo(actor, oldCollection)
end
pfm.register_command("move_actor_to_collection", Command)

--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateComponent", pfm.Command)
function Command:Initialize(actor, componentType)
	pfm.Command.Initialize(self)

	local component = actor:FindComponent(componentType)
	if component ~= nil then
		-- Component already exists
		return pfm.Command.RESULT_NO_OP
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, pfm.get_unique_id(actor))
	data:SetValue("componentType", udm.TYPE_STRING, componentType)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	if actor == nil then
		return
	end
	return actor:AddComponentType(data:GetValue("componentType", udm.TYPE_STRING))
end
function Command:DoUndo(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	if actor == nil then
		return false
	end
	actor:GetFilmClip():RemoveActorComponent(actor, data:GetValue("componentType", udm.TYPE_STRING))
	return true
end
pfm.register_command("create_component", Command)

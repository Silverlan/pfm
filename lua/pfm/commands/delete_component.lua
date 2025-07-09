-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandDeleteComponent", pfm.Command)
function Command:Initialize(actor, componentType)
	pfm.Command.Initialize(self)

	actor = pfm.dereference(actor)
	local component = actor:FindComponent(componentType)
	if component == nil then
		-- Component doesn't exist
		return pfm.Command.RESULT_NO_OP
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, pfm.get_unique_id(actor))
	data:SetValue("componentType", udm.TYPE_STRING, componentType)
	data:SetValue("uuid", udm.TYPE_STRING, tostring(component:GetUniqueId()))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	if actor == nil then
		return false
	end
	actor:GetFilmClip():RemoveActorComponent(actor, data:GetValue("componentType", udm.TYPE_STRING))
	return true
end
function Command:DoUndo(data)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	if actor == nil then
		return
	end
	return actor:AddComponentType(
		data:GetValue("componentType", udm.TYPE_STRING),
		data:GetValue("uuid", udm.TYPE_STRING)
	)
end
pfm.register_command("delete_component", Command)

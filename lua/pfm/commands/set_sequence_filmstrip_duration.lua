-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetSequenceFilmstripDuration", pfm.Command)
function Command:Initialize(oldDuration, newDuration)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("oldDuration", udm.TYPE_FLOAT, oldDuration)
	data:SetValue("newDuration", udm.TYPE_FLOAT, newDuration)
	return true
end
function Command:ApplyTime(data, keyName)
    local timeFrame = pfm.get_project_manager():GetSession():GetTimeFrame()
    timeFrame:SetDuration(data:GetValue(keyName, udm.TYPE_FLOAT))
	return true
end
function Command:DoExecute(data)
	return self:ApplyTime(data, "newDuration")
end
function Command:DoUndo(data)
	return self:ApplyTime(data, "oldDuration")
end
pfm.register_command("set_sequence_filmstrip_duration", Command)

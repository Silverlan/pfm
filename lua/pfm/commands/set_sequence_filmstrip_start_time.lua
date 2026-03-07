-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetSequenceFilmstripStartTime", pfm.Command)
function Command:Initialize(oldStartTime, newStartTime)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("oldStartTime", udm.TYPE_FLOAT, oldStartTime)
	data:SetValue("newStartTime", udm.TYPE_FLOAT, newStartTime)
	return true
end
function Command:ApplyTime(data, keyName)
    local timeFrame = pfm.get_project_manager():GetSession():GetTimeFrame()
    timeFrame:SetStart(data:GetValue(keyName, udm.TYPE_FLOAT))
	return true
end
function Command:DoExecute(data)
	return self:ApplyTime(data, "newStartTime")
end
function Command:DoUndo(data)
	return self:ApplyTime(data, "oldStartTime")
end
pfm.register_command("set_sequence_filmstrip_start_time", Command)

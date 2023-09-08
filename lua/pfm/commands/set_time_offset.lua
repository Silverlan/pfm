--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetTimeOffset", pfm.Command)
function Command:Initialize(newTimeOffset, oldTimeOffset)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("newTimeOffset", udm.TYPE_FLOAT, newTimeOffset)
	data:SetValue("oldTimeOffset", udm.TYPE_FLOAT, oldTimeOffset)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local pm = self:GetProjectManager()
	pm:SetTimeOffset(data:GetValue("newTimeOffset", udm.TYPE_FLOAT))
end
function Command:DoUndo(data)
	local pm = self:GetProjectManager()
	pm:SetTimeOffset(data:GetValue("oldTimeOffset", udm.TYPE_FLOAT))
end
pfm.register_command("set_time_offset", Command)

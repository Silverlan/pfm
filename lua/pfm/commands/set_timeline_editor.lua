--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetTimelineEditor", pfm.Command)
function Command:Initialize(oldEditor, newEditor)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("oldEditor", udm.TYPE_UINT8, oldEditor)
	data:SetValue("newEditor", udm.TYPE_UINT8, newEditor)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local pm = self:GetProjectManager()
	local timeline = pm:GetTimeline()
	if util.is_valid(timeline) == false then
		return false
	end
	timeline:SetEditor(data:GetValue("newEditor", udm.TYPE_UINT8))
end
function Command:DoUndo(data)
	local pm = self:GetProjectManager()
	local timeline = pm:GetTimeline()
	if util.is_valid(timeline) == false then
		return false
	end
	timeline:SetEditor(data:GetValue("oldEditor", udm.TYPE_UINT8))
end
pfm.register_command("set_timeline_editor", Command)

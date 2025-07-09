-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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

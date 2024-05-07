--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetMotionEditorSelectionBounds", pfm.Command)
function Command:Initialize(origTimes, newTimes)
	pfm.Command.Initialize(self)

	local data = self:GetData()
	data:SetValue("origStartTime", udm.TYPE_FLOAT, origTimes[pfm.CommandApplyMotionTransform.MARKER_START_OUTER])
	data:SetValue("origInnerStartTime", udm.TYPE_FLOAT, origTimes[pfm.CommandApplyMotionTransform.MARKER_START_INNER])
	data:SetValue("origInnerEndTime", udm.TYPE_FLOAT, origTimes[pfm.CommandApplyMotionTransform.MARKER_END_INNER])
	data:SetValue("origEndTime", udm.TYPE_FLOAT, origTimes[pfm.CommandApplyMotionTransform.MARKER_END_OUTER])

	data:SetValue("startTime", udm.TYPE_FLOAT, newTimes[pfm.CommandApplyMotionTransform.MARKER_START_OUTER])
	data:SetValue("innerStartTime", udm.TYPE_FLOAT, newTimes[pfm.CommandApplyMotionTransform.MARKER_START_INNER])
	data:SetValue("innerEndTime", udm.TYPE_FLOAT, newTimes[pfm.CommandApplyMotionTransform.MARKER_END_INNER])
	data:SetValue("endTime", udm.TYPE_FLOAT, newTimes[pfm.CommandApplyMotionTransform.MARKER_END_OUTER])
	return pfm.Command.RESULT_SUCCESS
end
function Command:SetSelectionBounds(startTime, innerStartTime, innerEndTime, endTime)
	local pm = pfm.get_project_manager()
	local motionEditor = util.is_valid(pm) and pm:GetMotionEditor() or nil
	local elSelection = util.is_valid(motionEditor) and motionEditor:GetSelectionElement() or nil
	if util.is_valid(elSelection) == false then
		return
	end
	elSelection:SetStartTime(startTime)
	elSelection:SetInnerStartTime(innerStartTime)
	elSelection:SetInnerEndTime(innerEndTime)
	elSelection:SetEndTime(endTime)
	elSelection:UpdateSelectionBounds()
end
function Command:DoExecute(data)
	local startTime = data:GetValue("startTime", udm.TYPE_FLOAT)
	local innerStartTime = data:GetValue("innerStartTime", udm.TYPE_FLOAT)
	local innerEndTime = data:GetValue("innerEndTime", udm.TYPE_FLOAT)
	local endTime = data:GetValue("endTime", udm.TYPE_FLOAT)
	self:SetSelectionBounds(startTime, innerStartTime, innerEndTime, endTime)
end
function Command:DoUndo(data)
	local startTime = data:GetValue("origStartTime", udm.TYPE_FLOAT)
	local innerStartTime = data:GetValue("origInnerStartTime", udm.TYPE_FLOAT)
	local innerEndTime = data:GetValue("origInnerEndTime", udm.TYPE_FLOAT)
	local endTime = data:GetValue("origEndTime", udm.TYPE_FLOAT)
	self:SetSelectionBounds(startTime, innerStartTime, innerEndTime, endTime)
end
pfm.register_command("set_motion_editor_selection_bounds", Command)

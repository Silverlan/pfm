--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.CursorTracker", util.CallbackHandler)
function gui.CursorTracker:__init(cursorPos)
	util.CallbackHandler.__init(self)
	self.m_startPos = cursorPos or input.get_cursor_pos()
	self.m_curPos = self.m_startPos:Copy()
end

function gui.CursorTracker:GetTotalDeltaPosition()
	return self.m_curPos - self.m_startPos
end
function gui.CursorTracker:GetStartPos()
	return self.m_startPos
end
function gui.CursorTracker:GetCurPos()
	return self.m_curPos
end
function gui.CursorTracker:ResetCurPos()
	self.m_curPos = self.m_startPos:Copy()
end

function gui.CursorTracker:HasExceededMoveThreshold(threshold, axis)
	local dtAbs = self:GetTotalDeltaPosition()
	if axis ~= nil then
		if axis == math.AXIS_X then
			return math.abs(dtAbs.x) >= threshold
		end
		if axis == math.AXIS_Y then
			return math.abs(dtAbs.y) >= threshold
		end
		return false
	end
	return math.abs(dtAbs.x) >= threshold or math.abs(dtAbs.y) >= threshold
end
function gui.CursorTracker:Update(pos)
	pos = pos or input.get_cursor_pos()
	local dt = pos - self.m_curPos
	if dt.x == 0 and dt.y == 0 then
		return dt
	end
	self.m_curPos = pos
	self:CallCallbacks("OnCursorMoved", dt)
	return dt
end

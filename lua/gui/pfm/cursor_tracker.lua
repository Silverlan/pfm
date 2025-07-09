-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.CursorTracker", util.CallbackHandler)
function gui.CursorTracker:__init(cursorPos)
	util.CallbackHandler.__init(self)
	self.m_startPos = cursorPos or input.get_cursor_pos()
	self.m_origCursorPos = input.get_cursor_pos()
	self.m_accDelta = Vector2(0, 0)
	self.m_curPos = self.m_startPos:Copy()
end

function gui.CursorTracker:SetSticky(sticky)
	self.m_sticky = sticky
end

function gui.CursorTracker:IsSticky()
	return self.m_sticky or false
end

function gui.CursorTracker:GetTotalDeltaPosition()
	return self.m_accDelta
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
	self.m_accDelta = self.m_accDelta + dt
	if self:IsSticky() then
		self.m_startPos = self.m_startPos + dt
		input.set_cursor_pos(self.m_origCursorPos)
		self.m_curPos = self.m_origCursorPos:Copy()
	else
		self.m_curPos = self.m_curPos + dt
	end
	self:CallCallbacks("OnCursorMoved", dt)
	return dt
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMDataPointControl", gui.Base)
function gui.PFMDataPointControl:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(4, 4)
	local el = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_elPoint = el
	el:GetColorProperty():Link(self:GetColorProperty())

	self.m_selected = false
	self:SetMouseInputEnabled(true)
end
function gui.PFMDataPointControl:IsSelected()
	return self.m_selected
end
function gui.PFMDataPointControl:SetSelected(selected)
	if selected == self.m_selected then
		return
	end
	self.m_selected = selected
	self:SetColor(selected and Color.Red or Color.White)
	self:SetMoveModeEnabled(false)
	self:OnSelectionChanged(selected)
	self:CallCallbacks("OnSelectionChanged", selected)
end
function gui.PFMDataPointControl:OnSelectionChanged(selected) end
function gui.PFMDataPointControl:OnThink()
	if self.m_cursorTracker == nil then
		return
	end
	local dt = self.m_cursorTracker:Update()
	if dt.x == 0 and dt.y == 0 then
		return
	end
	if self.m_moveThreshold ~= nil then
		if not self.m_cursorTracker:HasExceededMoveThreshold(self.m_moveThreshold) then
			return
		end
		self.m_moveThreshold = nil
	end
	local newPos = self.m_moveModeStartPos + self.m_cursorTracker:GetTotalDeltaPosition()
	if input.is_shift_key_down() then
		newPos.x = self.m_moveModeStartPos.x
	end
	if input.is_alt_key_down() then
		newPos.y = self.m_moveModeStartPos.y
	end
	self:OnMoved(newPos)
	self:CallCallbacks("OnMoved", newPos)
end
function gui.PFMDataPointControl:OnMoved(newPos) end
function gui.PFMDataPointControl:IsMoveModeEnabled()
	return self.m_cursorTracker ~= nil
end
function gui.PFMDataPointControl:SetMoveModeEnabled(enabled, moveThreshold)
	if enabled then
		self.m_cursorTracker = gui.CursorTracker()
		self.m_moveModeStartPos = self:GetPos()
		self.m_moveThreshold = moveThreshold
		self:EnableThinking()
	else
		self.m_cursorTracker = nil
		self.m_moveModeStartPos = nil
		self.m_moveThreshold = nil
		self:DisableThinking()
	end
end
gui.register("WIPFMDataPointControl", gui.PFMDataPointControl)

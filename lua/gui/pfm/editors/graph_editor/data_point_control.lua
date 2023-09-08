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
function gui.PFMDataPointControl:OnRemove()
	self:SetMoveModeEnabled(false)
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
	if self.m_moveData == nil then
		return
	end
	local dt = self.m_moveData.cursorTracker:Update()
	if dt.x == 0 and dt.y == 0 then
		return
	end
	if self.m_moveData.moveThreshold ~= nil then
		if not self.m_moveData.cursorTracker:HasExceededMoveThreshold(self.m_moveData.moveThreshold) then
			return
		end
		self.m_moveData.moveThreshold = nil
	end
	local newPos = self.m_moveData.startPos + self.m_moveData.cursorTracker:GetTotalDeltaPosition()
	if input.is_shift_key_down() then
		newPos.x = self.m_moveData.startPos.x
	end
	if input.is_alt_key_down() then
		newPos.y = self.m_moveData.startPos.y
	end
	self:OnMoved(newPos)
	self:CallCallbacks("OnMoved", newPos)
end
function gui.PFMDataPointControl:OnMoved(newPos) end
function gui.PFMDataPointControl:OnMoveStarted() end
function gui.PFMDataPointControl:OnMoveComplete() end
function gui.PFMDataPointControl:IsMoveModeEnabled()
	return self.m_moveData ~= nil
end
function gui.PFMDataPointControl:SetMoveModeEnabled(enabled, moveThreshold)
	if enabled == self:IsMoveModeEnabled() then
		return
	end
	if enabled then
		self.m_moveData = {
			cursorTracker = gui.CursorTracker(),
			startPos = self:GetPos(),
			moveThreshold = moveThreshold,
			startData = {},
		}
		self:EnableThinking()
		self:OnMoveStarted(self.m_moveData.startData)
		self:CallCallbacks("OnMoveStarted", self.m_moveData.startData, self.m_moveData.startPos)
	else
		local startData = self.m_moveData.startData
		local startPos = self.m_moveData.startPos
		self.m_moveData = nil
		self:DisableThinking()
		self:OnMoveComplete()
		self:CallCallbacks("OnMoveComplete", startData, startPos)
	end
end
gui.register("WIPFMDataPointControl", gui.PFMDataPointControl)

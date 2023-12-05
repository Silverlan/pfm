--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("timeline_graph_base.lua")
include("/gui/pfm/partial_time_selection.lua")

util.register_class("gui.PFMTimelineMotion", gui.PFMTimelineGraphBase)

function gui.PFMTimelineMotion:OnInitialize()
	gui.PFMTimelineGraphBase.OnInitialize(self)
	--self.m_listContainer:SetVisible(false)
	--self.m_dataAxisStrip:SetVisible(false)
end
function gui.PFMTimelineMotion:OnRemove()
	gui.PFMTimelineGraphBase.OnRemove(self)
	util.remove(self.m_elSelection)
	util.remove(self.m_cbSelectionSizeUpdate)
end
function gui.PFMTimelineMotion:SetSelectionStart(t)
	self.m_selectionStart = t
end
function gui.PFMTimelineMotion:SetSelectionEnd(t)
	self.m_selectionEnd = t
	self:UpdateSelectionItem()
end
function gui.PFMTimelineMotion:UpdateCursorTracker(trackerData, tracker, timeLine)
	gui.PFMTimelineGraphBase.UpdateCursorTracker(self, trackerData, tracker, timeLine)

	local dtPos = tracker:GetTotalDeltaPosition()
	local cursorMode = self:GetCursorMode()
	local pos = self:GetCursorPos()
	local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
	self:SetSelectionEnd(t)
	self:UpdateSelectionItem()
	--[[if self.m_middleMouseDrag or cursorMode == gui.PFMTimelineGraphBase.CURSOR_MODE_PAN then
		timeLine
			:GetTimeAxis()
			:GetAxis()
			:SetStartOffset(trackerData.timeAxisStartOffset - timeLine:GetTimeAxis():GetAxis():XDeltaToValue(dtPos).x)
		timeLine
			:GetDataAxis()
			:GetAxis()
			:SetStartOffset(trackerData.dataAxisStartOffset + timeLine:GetDataAxis():GetAxis():XDeltaToValue(dtPos).y)
		timeLine:Update()
	elseif self.m_rightClickZoom or cursorMode == gui.PFMTimelineGraphBase.CURSOR_MODE_ZOOM then
		local dt = (dtPos.x + dtPos.y) / 20.0
		self:ZoomAxes(dt, true, true, true, tracker:GetStartPos())
		input.set_cursor_pos(tracker:GetStartPos())
		tracker:ResetCurPos()
	elseif cursorMode == gui.PFMTimelineGraphBase.CURSOR_MODE_SELECT then
	elseif cursorMode == gui.PFMTimelineGraphBase.CURSOR_MODE_MOVE then
	elseif cursorMode == gui.PFMTimelineGraphBase.CURSOR_MODE_SCALE then
	end]]
end
function gui.PFMTimelineMotion:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		local pos = self:GetCursorPos()
		local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
		if state == input.STATE_PRESS then
			self:SetSelectionStart(t)
			self:SetCursorTrackerEnabled(true)
		else
			self:SetSelectionEnd(t)
			self:SetCursorTrackerEnabled(false)
		end
		return util.EVENT_REPLY_HANDLED
	end
	return gui.PFMTimelineGraphBase.MouseCallback(self, button, state, mods)
end
function gui.PFMTimelineMotion:UpdateSelectionItem()
	if self.m_selectionStart == nil or self.m_selectionEnd == nil then
		return
	end
	local t0 = self.m_timeAxis:GetAxis():ValueToXOffset(self.m_selectionStart)
	self.m_elSelection:SetX(t0)

	local t1 = self.m_timeAxis:GetAxis():ValueToXOffset(self.m_selectionEnd)
	self.m_elSelection:SetWidth(t1 - t0)

	self.m_elSelection:UpdateCenterBar()
end
function gui.PFMTimelineMotion:SetTimelineContents(contents)
	util.remove(self.m_elSelection)
	local selection = gui.create("WIPFMPartialTimeSelection", contents)
	selection:SetY(contents:GetUpperTimelineStrip():GetTop())
	selection:SetHeight(contents:GetHeight() - selection:GetY())
	selection:SetInnerStartPosition(15)
	selection:SetInnerEndPosition(15)
	self.m_cbSelectionSizeUpdate = contents:AddCallback("SetSize", function()
		self.m_elSelection:SetHeight(contents:GetHeight() - selection:GetY())
	end)
	self.m_elSelection = selection
end
function gui.PFMTimelineMotion:InitializeBookmarks(graphData) end
gui.register("WIPFMTimelineMotion", gui.PFMTimelineMotion)

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
	self.m_elSelection:SetStartTime(t)
end
function gui.PFMTimelineMotion:SetSelectionEnd(t)
	self.m_elSelection:SetEndTime(t)
end
function gui.PFMTimelineMotion:SetInnerSelectionStart(t)
	self.m_elSelection:SetInnerStartTime(t)
end
function gui.PFMTimelineMotion:SetInnerSelectionEnd(t)
	self.m_elSelection:SetInnerEndTime(t)
end
function gui.PFMTimelineMotion:UpdateCursorTracker(trackerData, tracker, timeLine)
	gui.PFMTimelineGraphBase.UpdateCursorTracker(self, trackerData, tracker, timeLine)

	local pos = self:GetCursorPos()
	local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
	self:SetSelectionEnd(t)
	self:SetInnerSelectionEnd(t)
end
function gui.PFMTimelineMotion:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		local pos = self:GetCursorPos()
		local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
		if state == input.STATE_PRESS then
			if input.is_shift_key_down() then
				self.m_creatingSelection = true
				self:SetSelectionStart(t)
				self:SetInnerSelectionStart(t)
				self:SetCursorTrackerEnabled(true)
				return util.EVENT_REPLY_HANDLED
			end
		elseif self.m_creatingSelection then
			self.m_creatingSelection = false
			self:SetSelectionEnd(t)
			self:SetInnerSelectionEnd(t)
			self:SetCursorTrackerEnabled(false)
			return util.EVENT_REPLY_HANDLED
		end
	end
	return gui.Base.MouseCallback(self, button, state, mods)
end
function gui.PFMTimelineMotion:SetTimelineContents(contents)
	util.remove(self.m_elSelection)
	local selection = gui.create("WIPFMPartialTimeSelection", contents)
	selection:SetupTimelineMarkers(contents)
	selection:SetY(contents:GetUpperTimelineStrip():GetTop())
	selection:SetHeight(contents:GetHeight() - selection:GetY())
	selection:SetInnerStartPosition(0)
	selection:SetInnerEndPosition(0)
	self.m_cbSelectionSizeUpdate = contents:AddCallback("SetSize", function()
		self.m_elSelection:SetHeight(contents:GetHeight() - selection:GetY())
	end)
	self.m_elSelection = selection
end
function gui.PFMTimelineMotion:InitializeBookmarks(graphData) end
gui.register("WIPFMTimelineMotion", gui.PFMTimelineMotion)

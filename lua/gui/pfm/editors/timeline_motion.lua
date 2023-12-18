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
	if self.m_creatingSelection then
		local pos = self:GetCursorPos()
		local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
		self:SetSelectionEnd(t)
		self:SetInnerSelectionEnd(t)
		return
	end
	gui.PFMTimelineGraphBase.UpdateCursorTracker(self, trackerData, tracker, timeLine)
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
	return gui.PFMTimelineGraphBase.MouseCallback(self, button, state, mods)
end
function gui.PFMTimelineMotion:OnSelectionStartTransform()
	self.m_transformChannelCopies = {}
	for _, graphData in ipairs(self.m_graphs) do
		local channel = graphData.channel()
		channel = channel:GetPanimaChannel()
		local channelCpy = panima.Channel(channel)
		self.m_transformChannelCopies[graphData.targetPath] = channelCpy
	end
end
function gui.PFMTimelineMotion:OnSelectionEndTransform()
	self.m_transformChannelCopies = nil
end
function gui.PFMTimelineMotion:OnSelectionTransformUpdate(startTime, endTime, scaleFactor, shiftOffset)
	local cmd = pfm.create_command("composition")
	for _, graphData in ipairs(self.m_graphs) do
		local channelCpy = self.m_transformChannelCopies[graphData.targetPath]
		if channelCpy ~= nil then
			local res, subCmd
			if scaleFactor ~= nil then
				res, subCmd = cmd:AddSubCommand(
					"scale_animation_channel",
					graphData.actor,
					graphData.targetPath,
					startTime,
					endTime,
					scaleFactor
				)
			end
			if shiftOffset ~= nil then
				res, subCmd = cmd:AddSubCommand(
					"shift_animation_channel",
					graphData.actor,
					graphData.targetPath,
					startTime,
					endTime,
					shiftOffset
				)
			end

			local channel = subCmd:GetChannel()
			channel:ClearAnimationData()
			channel:MergeValues(channelCpy)
		end
	end
	cmd:Execute()
end
function gui.PFMTimelineMotion:SetTimelineContents(contents)
	util.remove(self.m_elSelection)
	local selection = gui.create("WIPFMPartialTimeSelection", contents)
	selection:GetVisibilityProperty():Link(self:GetVisibilityProperty())
	selection:SetupTimelineMarkers(contents)
	selection:SetY(contents:GetUpperTimelineStrip():GetTop())
	selection:SetHeight(contents:GetHeight() - selection:GetY())
	selection:SetInnerStartPosition(0)
	selection:SetInnerEndPosition(0)
	self.m_cbSelectionSizeUpdate = contents:AddCallback("SetSize", function()
		self.m_elSelection:SetHeight(contents:GetHeight() - selection:GetY())
	end)
	selection:AddCallback("OnTransformUpdate", function(selection, startTime, endTime, scaleFactor, shiftOffset)
		self:OnSelectionTransformUpdate(startTime, endTime, scaleFactor, shiftOffset)
	end)
	selection:AddCallback("OnStartTransform", function()
		self:OnSelectionStartTransform()
	end)
	selection:AddCallback("OnEndTransform", function()
		self:OnSelectionEndTransform()
	end)
	self.m_elSelection = selection
end
function gui.PFMTimelineMotion:InitializeBookmarks(graphData) end
gui.register("WIPFMTimelineMotion", gui.PFMTimelineMotion)

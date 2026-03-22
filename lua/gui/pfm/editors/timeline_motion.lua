-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("timeline_graph_base.lua")
include("/gui/pfm/timeline/partial_time_selection.lua")

local TimelineEditorMotion = util.register_class("gui.pfm.TimelineEditorMotion", gui.pfm.TimelineEditorGraphBase)

function TimelineEditorMotion:OnInitialize()
	gui.pfm.TimelineEditorGraphBase.OnInitialize(self)
	self:SetDataPointsSelectable(false)
	--self.m_listContainer:SetVisible(false)
	--self.m_dataAxisStrip:SetVisible(false)
end
function TimelineEditorMotion:OnRemove()
	gui.pfm.TimelineEditorGraphBase.OnRemove(self)
	util.remove(self.m_elSelection)
	util.remove(self.m_cbSelectionSizeUpdate)
end
function TimelineEditorMotion:GetSelectionElement()
	return self.m_elSelection
end
function TimelineEditorMotion:SetSelectionStart(t)
	self.m_elSelection:SetStartTime(t)
end
function TimelineEditorMotion:SetSelectionEnd(t)
	self.m_elSelection:SetEndTime(t)
end
function TimelineEditorMotion:SetInnerSelectionStart(t)
	self.m_elSelection:SetInnerStartTime(t)
end
function TimelineEditorMotion:SetInnerSelectionEnd(t)
	self.m_elSelection:SetInnerEndTime(t)
end
function TimelineEditorMotion:UpdateCursorTracker(trackerData, tracker, timeLine)
	if self.m_creatingSelection then
		self:UpdateSelectionBounds()
		return
	end
	gui.pfm.TimelineEditorGraphBase.UpdateCursorTracker(self, trackerData, tracker, timeLine)
end
function TimelineEditorMotion:UpdateSelectionBounds()
	local pos = self:GetCursorPos()
	local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
	local tMin = math.min(self.m_selectionStartTime, t)
	local tMax = math.max(self.m_selectionStartTime, t)
	self:SetSelectionStart(tMin)
	self:SetInnerSelectionStart(tMin)
	self:SetSelectionEnd(tMax)
	self:SetInnerSelectionEnd(tMax)
	self.m_elSelection:UpdateSelectionBounds()
end
function TimelineEditorMotion:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		local pos = self:GetCursorPos()
		local t = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
		if state == input.STATE_PRESS then
			if input.is_shift_key_down() then
				self.m_creatingSelection = true
				self.m_selectionStartTime = t
				self:UpdateSelectionBounds()
				self:SetCursorTrackerEnabled(true)
				return util.EVENT_REPLY_HANDLED
			end
		elseif self.m_creatingSelection then
			self:UpdateSelectionBounds()
			self.m_creatingSelection = false
			self.m_selectionStartTime = nil
			self:SetCursorTrackerEnabled(false)
			return util.EVENT_REPLY_HANDLED
		end
	end
	return gui.pfm.TimelineEditorGraphBase.MouseCallback(self, button, state, mods)
end
function TimelineEditorMotion:OnDragStart(shouldTransform)
	if shouldTransform then
		local targetActorChannels = {}
		for _, graphData in ipairs(self.m_graphs) do
			local actor = graphData.actor
			local targetPath = graphData.targetPath
			targetActorChannels[actor] = targetActorChannels[actor] or {}
			-- Target path may appear multiple times if this is a composite type (e.g. vec3),
			-- but we only want one reference
			if targetActorChannels[actor][targetPath] == nil then
				local channel = graphData.channel()
				if channel ~= nil then
					channel = channel:GetPanimaChannel()
					local channelCpy = panima.Channel(channel)

					local originalKeyframeData
					local animClip = graphData.animClip()
					local editorData = animClip:GetEditorData()
					local editorChannel = (editorData ~= nil) and editorData:FindChannel(targetPath) or nil
					local graphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
					if graphCurve ~= nil then
						originalKeyframeData = udm.create_element()
						pfm.CommandApplyMotionTransform.store_keyframe_data(originalKeyframeData, graphCurve)
					end

					targetActorChannels[actor][targetPath] = {
						channel = channel,
						channelCopy = channelCpy,
						originalKeyframeData = originalKeyframeData,
					}
				end
			end
		end
		self.m_targetActorChannels = targetActorChannels
	end

	self.m_selectionPreTransformBounds = self:GetSelectionBounds()
end
function TimelineEditorMotion:GetSelectionBounds()
	return {
		startTime = self.m_elSelection:GetStartTime(),
		innerStartTime = self.m_elSelection:GetInnerStartTime(),
		innerEndTime = self.m_elSelection:GetInnerEndTime(),
		endTime = self.m_elSelection:GetEndTime(),
	}
end
function TimelineEditorMotion:OnDragEnd()
	self.m_targetActorChannels = nil
	self.m_selectionPreTransformBounds = nil
end
function TimelineEditorMotion:OnDragUpdate(origSelTimes, newSelTimes, isFinal)
	local cmd = pfm.create_command("composition")
	if self.m_targetActorChannels ~= nil then
		for actor, channels in pairs(self.m_targetActorChannels) do
			for targetPath, channelData in pairs(channels) do
				local channel = channelData.channel
				local channelCpy = channelData.channelCopy

				-- Reset keyframes
				if channelData.originalKeyframeData ~= nil then
					local editorChannel, editorData, animClip = actor:FindEditorChannel(targetPath)
					local graphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
					if graphCurve ~= nil then
						pfm.CommandApplyMotionTransform.restore_keyframe_data(
							channelData.originalKeyframeData,
							graphCurve
						)
					end
				end

				-- Reset values from copy
				channel:ClearAnimationData()
				channel:MergeValues(channelCpy)

				local res, subCmd =
					cmd:AddSubCommand("apply_motion_transform", actor, targetPath, origSelTimes, newSelTimes)
			end
		end
	end
	if isFinal then
		local origBounds = self.m_selectionPreTransformBounds
		local newBounds = self:GetSelectionBounds()
		cmd:AddSubCommand(
			"set_motion_editor_selection_bounds",
			{ origBounds.startTime, origBounds.innerStartTime, origBounds.innerEndTime, origBounds.endTime },
			{ newBounds.startTime, newBounds.innerStartTime, newBounds.innerEndTime, newBounds.endTime }
		)
		local name
		if self.m_targetActorChannels ~= nil then
			name = "transform_animation_data"
		else
			name = "change_motion_editor_selection_bounds"
		end
		pfm.undoredo.push(name, cmd)()
	else
		cmd:Execute()
	end
end
function TimelineEditorMotion:SetTimelineContents(contents)
	util.remove(self.m_elSelection)
	local selection = gui.create("pfm_partial_time_selection", contents)
	selection:GetVisibilityProperty():Link(self:GetVisibilityProperty())
	selection:SetupTimelineMarkers(contents)
	selection:SetY(contents:GetUpperTimelineStrip():GetTop())
	selection:SetHeight(contents:GetHeight() - selection:GetY())
	selection:SetInnerStartPosition(0)
	selection:SetInnerEndPosition(0)
	self.m_cbSelectionSizeUpdate = contents:AddCallback("OnSizeChanged", function()
		self.m_elSelection:SetHeight(contents:GetHeight() - selection:GetY())
	end)

	selection:AddCallback("OnDragUpdate", function(selection, origSelTimes, newSelTimes, isFinal)
		self:OnDragUpdate(origSelTimes, newSelTimes, isFinal)
	end)
	selection:AddCallback("OnDragStart", function(selection, shouldTransform)
		self:OnDragStart(shouldTransform)
	end)
	selection:AddCallback("OnDragEnd", function()
		self:OnDragEnd()
	end)
	self.m_elSelection = selection
end
function TimelineEditorMotion:InitializeBookmarks(graphData) end
gui.register("pfm_timeline_editor_motion", TimelineEditorMotion)

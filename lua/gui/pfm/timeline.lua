-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("button.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/timeline.lua")
include("editors")

util.register_class("gui.PFMTimeline", gui.Base)

gui.PFMTimeline.EDITOR_CLIP = 0
gui.PFMTimeline.EDITOR_MOTION = 1
gui.PFMTimeline.EDITOR_GRAPH = 2
function gui.PFMTimeline:__init()
	gui.Base.__init(self)
end
function gui.PFMTimeline:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 128)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:AddStyleClass("background2")
	self.m_bg:SetName("timeline_background")

	self.m_contents = gui.create("WIVBox", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents:SetName("timeline_contents")
	self:InitializeToolbar()
	gui.create("WIBase", self.m_contents):SetSize(1, 7) -- Gap

	self.m_timeline = gui.create("WITimeline", self.m_contents)
	self.m_timeline:SetName("timeline_strip")

	self.m_timeline:SetZoomLevel(0.0)
	self.m_timeline:SetStartOffset(1.0)
	self.m_timeline:Update()

	self.m_timeline:AddCallback("OnUserInputStarted", function()
		self:CallCallbacks("OnUserInputStarted")
	end)
	self.m_timeline:AddCallback("OnUserInputEnded", function()
		self:CallCallbacks("OnUserInputEnded")
	end)
	self.m_timeline:AddCallback("OnTimelineUpdate", function()
		self:OnTimelineUpdate()
	end)
	self.m_timelineClips = {}

	local contents = self.m_timeline:GetContents()

	self.m_timelineClip =
		gui.create("WIPFMTimelineClip", contents, 0, 0, contents:GetWidth(), contents:GetHeight(), 0, 0, 1, 1)
	self.m_timelineClip:SetName("timeline_clip_editor")

	self.m_timelineMotion =
		gui.create("WIPFMTimelineMotion", contents, 0, 0, contents:GetWidth(), contents:GetHeight(), 0, 0, 1, 1)
	self.m_timelineMotion:SetName("timeline_motion_editor")
	self.m_timelineMotion:SetTimelineContents(self.m_timeline)
	self.m_timelineMotion:SetTimeAxis(self.m_timeline:GetTimeAxis())
	self.m_timelineMotion:SetDataAxis(self.m_timeline:GetDataAxis())
	self.m_timelineMotion:SetTimeline(self)

	self.m_timelineGraph =
		gui.create("WIPFMTimelineGraph", contents, 0, 0, contents:GetWidth(), contents:GetHeight(), 0, 0, 1, 1)
	self.m_timelineGraph:SetName("timeline_graph_editor")
	self.m_timelineGraph:SetTimeAxis(self.m_timeline:GetTimeAxis())
	self.m_timelineGraph:SetDataAxis(self.m_timeline:GetDataAxis())
	self.m_timelineGraph:SetTimeline(self)

	self.m_contents:SetAutoFillContentsToHeight(true)
	self.m_contents:SetAutoFillContentsToWidth(true)
	self.m_contents:SetSize(self:GetSize())
	self.m_contents:Update()

	self:OnTimelineUpdate()

	self.m_editorType = gui.PFMTimeline.EDITOR_GRAPH
	self:SetEditor(gui.PFMTimeline.EDITOR_CLIP)
end
function gui.PFMTimeline:SetTimeRange(startTime, endTime, margin, offset)
	local contents = self.m_timeline:GetContents()
	local w = contents:GetWidth()
	offset = offset or 0
	w = w - offset
	local timeLine = self:GetTimeline()
	local axisTime = timeLine:GetTimeAxis():GetAxis()
	axisTime:SetRange(startTime, endTime, w)

	margin = margin or 0.0
	local marginT = axisTime:XDeltaToValue(margin)
	startTime = startTime - marginT
	endTime = endTime + marginT

	-- Need to update a second time to account for the margin
	axisTime:SetRange(startTime, endTime, w)

	axisTime:SetStartOffset(axisTime:GetStartOffset() - axisTime:XDeltaToValue(offset))
	timeLine:Update()
end
function gui.PFMTimeline:SetDataRange(startVal, endVal, margin)
	local contents = self.m_timeline:GetContents()
	local h = contents:GetHeight()
	local timeLine = self:GetTimeline()
	local axisData = timeLine:GetDataAxis():GetAxis()

	axisData:SetRange(startVal, endVal, h)

	margin = margin or 0.0
	local marginV = axisData:XDeltaToValue(margin)
	startVal = startVal - marginV
	endVal = endVal + marginV

	-- Need to update a second time to account for the margin
	axisData:SetRange(startVal, endVal, h)

	timeLine:Update()
end
function gui.PFMTimeline:GetSelectedClip()
	return self.m_selectedClip
end
function gui.PFMTimeline:InitializeClip(clip, fOnSelected)
	clip:AddCallback("OnSelected", function(el)
		if self:IsValid() == false then
			return
		end
		if util.is_valid(self.m_selectedClip) and self.m_selectedClip ~= clip then
			self.m_selectedClip:SetSelected(false)
		end
		self.m_selectedClip = clip

		self:CallCallbacks("OnClipSelected", clip)
		if fOnSelected ~= nil then
			fOnSelected(clip)
		end
	end)
	clip:AddCallback("OnDeselected", function(el)
		if self:IsValid() == false then
			return
		end
	end)
	table.insert(self.m_timelineClips, clip)
end
function gui.PFMTimeline:RemoveClip(clip)
	for i, c in ipairs(self.m_timelineClips) do
		if c:IsValid() and util.is_same_object(c:GetClipData(), clip) then
			c:Remove()
			table.remove(self.m_timelineClips, i)
			break
		end
	end
end
function gui.PFMTimeline:AddFilmClip(filmStrip, filmClip, fOnSelected)
	local elClip = gui.create("WIFilmClip", filmStrip.m_container)
	table.insert(filmStrip.m_filmClips, elClip)

	elClip:SetClipData(filmClip)
	filmStrip:ScheduleUpdate()

	self:InitializeClip(elClip, fOnSelected)
	return elClip
end
function gui.PFMTimeline:AddAudioClip(group, audioClip, fOnSelected)
	local elClip = gui.create("WIGenericClip")
	elClip:SetClipData(audioClip)
	elClip:AddStyleClass("timeline_clip_audio")
	group:AddElement(elClip)
	elClip:SetText(audioClip:GetName())

	self.m_timeline:AddTimelineItem(elClip, audioClip:GetTimeFrame())

	self:InitializeClip(elClip, fOnSelected)

	local function update_clip_data()
		elClip:UpdateClipData()
	end
	audioClip:AddChangeListener("name", update_clip_data)

	elClip:SetMouseInputEnabled(true)
	elClip:AddCallback("OnMouseEvent", function(subGroup, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu(self)
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem("Remove", function()
				pfm.undoredo.push("delete_audio_clip", pfm.create_command("delete_audio_clip", audioClip))()
			end)
			-- TODO: Move PopulateClipContextMenu to gui.PFMTimeline
			tool.get_filmmaker():PopulateClipContextMenu(audioClip, pContext)
			pContext:AddItem("Set Start", function()
				local oldStart = audioClip:GetTimeFrame():GetStart()
				local p = pfm.open_single_value_edit_window(locale.get_text("duration"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						local newStart = tonumber(val)
						if newStart ~= nil then
							pfm.undoredo.push(
								"set_clip_start",
								pfm.create_command("set_clip_start", audioClip, oldStart, newStart)
							)()
						end
					end
				end, tostring(oldStart))
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	return elClip
end
function gui.PFMTimeline:AddOverlayClip(group, overlayClip, fOnSelected)
	local elClip = gui.create("WIGenericClip")
	elClip:SetClipData(overlayClip)
	elClip:AddStyleClass("timeline_clip_overlay")
	group:AddElement(elClip)
	elClip:SetText(overlayClip:GetName())
	self.m_timeline:AddTimelineItem(elClip, overlayClip:GetTimeFrame())

	self:InitializeClip(elClip, fOnSelected)
	return elClip
end
function gui.PFMTimeline:GetEditorTimelineElement(type)
	if type == gui.PFMTimeline.EDITOR_CLIP then
		return self.m_timelineClip
	end
	if type == gui.PFMTimeline.EDITOR_MOTION then
		return self.m_timelineMotion
	end
	if type == gui.PFMTimeline.EDITOR_GRAPH then
		return self.m_timelineGraph
	end
end
function gui.PFMTimeline:OnTimelineUpdate()
	if util.is_valid(self.m_timeline) == false then
		return
	end
	for _, graph in ipairs({ self.m_timelineGraph, self.m_timelineMotion }) do
		if util.is_valid(graph) then
			local posTimeline = self.m_timeline:GetAbsolutePos()
			local posGraph = graph:GetAbsolutePos()
			local timeAxis = self.m_timeline:GetTimeAxis():GetAxis()
			local dataAxis = self.m_timeline:GetDataAxis():GetAxis()
			graph:UpdateAxisRanges(
				timeAxis:GetStartOffset(),
				timeAxis:GetZoomLevel(),
				dataAxis:GetStartOffset(),
				dataAxis:GetZoomLevel()
			)
		end
	end
end
function gui.PFMTimeline:GetEditor()
	return self.m_editorType
end
function gui.PFMTimeline:SetEditor(type)
	if type == self:GetEditor() then
		return
	end
	self.m_lastEditorType = self.m_editorType
	self.m_editorType = type
	if util.is_valid(self.m_clipControls) then
		self.m_clipControls:SetVisible(type == gui.PFMTimeline.EDITOR_CLIP)
	end

	if util.is_valid(self.m_motionControls) then
		self.m_motionControls:SetVisible(type == gui.PFMTimeline.EDITOR_MOTION)
	end

	if util.is_valid(self.m_entryFields) then
		self.m_entryFields:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH)
	end
	if util.is_valid(self.m_controls) then
		self.m_controls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH)
	end
	if util.is_valid(self.m_tangentControls) then
		self.m_tangentControls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH)
	end
	if util.is_valid(self.m_miscGraphControls) then
		self.m_miscGraphControls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH)
	end

	if util.is_valid(self.m_btClipEditor) then
		self.m_btClipEditor:SetActivated(type == gui.PFMTimeline.EDITOR_CLIP)
	end
	if util.is_valid(self.m_btMotionEditor) then
		self.m_btMotionEditor:SetActivated(type == gui.PFMTimeline.EDITOR_MOTION)
	end
	if util.is_valid(self.m_btGraphEditor) then
		self.m_btGraphEditor:SetActivated(type == gui.PFMTimeline.EDITOR_GRAPH)
	end

	if util.is_valid(self.m_btClipEditor) then
		self.m_btClipEditor:SetActivated(type == gui.PFMTimeline.EDITOR_CLIP)
	end

	if util.is_valid(self.m_timelineClip) then
		self.m_timelineClip:SetVisible(type == gui.PFMTimeline.EDITOR_CLIP)
	end
	if util.is_valid(self.m_timelineMotion) then
		self.m_timelineMotion:SetVisible(type == gui.PFMTimeline.EDITOR_MOTION)
	end
	if util.is_valid(self.m_timelineGraph) then
		self.m_timelineGraph:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH)
	end

	self:UpdateEditorButtonInactiveMaterial(
		gui.PFMTimeline.EDITOR_CLIP,
		"gui/pfm/icon_mode_timeline",
		"gui/pfm/icon_mode_timeline_preselected"
	)
	self:UpdateEditorButtonInactiveMaterial(
		gui.PFMTimeline.EDITOR_MOTION,
		"gui/pfm/icon_mode_motioneditor",
		"gui/pfm/icon_mode_motioneditor_preselected"
	)
	self:UpdateEditorButtonInactiveMaterial(
		gui.PFMTimeline.EDITOR_GRAPH,
		"gui/pfm/icon_mode_grapheditor",
		"gui/pfm/icon_mode_grapheditor_preselected"
	)

	local pm = tool.get_filmmaker()
	pm:UpdateBookmarks()
end
function gui.PFMTimeline:UpdateEditorButtonInactiveMaterial(editorType, matRegular, matPreselected)
	local bt = ((editorType == gui.PFMTimeline.EDITOR_CLIP) and self.m_btClipEditor)
		or ((editorType == gui.PFMTimeline.EDITOR_MOTION) and self.m_btMotionEditor)
		or ((editorType == gui.PFMTimeline.EDITOR_GRAPH) and self.m_btGraphEditor)
	if util.is_valid(bt) == false then
		return
	end
	bt:SetUnpressedMaterial((self.m_lastEditorType == editorType) and matPreselected or matRegular)
end
function gui.PFMTimeline:GetClipEditor()
	return self.m_timelineClip
end
function gui.PFMTimeline:GetMotionEditor()
	return self.m_timelineMotion
end
function gui.PFMTimeline:GetGraphEditor()
	return self.m_timelineGraph
end
function gui.PFMTimeline:GetActiveEditor()
	local type = self:GetEditor()
	if type == gui.PFMTimeline.EDITOR_CLIP then
		return self:GetClipEditor()
	end
	if type == gui.PFMTimeline.EDITOR_MOTION then
		return self:GetMotionEditor()
	end
	if type == gui.PFMTimeline.EDITOR_GRAPH then
		return self:GetGraphEditor()
	end
end
function gui.PFMTimeline:GetTimeline()
	return self.m_timeline
end
function gui.PFMTimeline:GetPlayhead()
	return util.is_valid(self.m_timeline) and self.m_timeline:GetPlayhead() or nil
end
function gui.PFMTimeline:GetTimeOffset()
	return self.m_timeline:GetPlayhead():GetTimeOffset()
end
function gui.PFMTimeline:SetGraphCursorMode(cursorMode)
	local buttons = {
		[gui.PFMTimelineGraph.CURSOR_MODE_SELECT] = self.m_btCtrlSelect,
		[gui.PFMTimelineGraph.CURSOR_MODE_MOVE] = self.m_btCtrlMove,
		[gui.PFMTimelineGraph.CURSOR_MODE_PAN] = self.m_btCtrlPan,
		[gui.PFMTimelineGraph.CURSOR_MODE_SCALE] = self.m_btCtrlScale,
		[gui.PFMTimelineGraph.CURSOR_MODE_ZOOM] = self.m_btCtrlZoom,
	}
	for btCursorMode, bt in pairs(buttons) do
		if bt:IsValid() then
			bt:SetActivated(btCursorMode == cursorMode)
		end
	end
	self.m_timelineGraph:SetCursorMode(cursorMode)
end
function gui.PFMTimeline:GetBookmarks()
	return self.m_timeline:GetBookmarks()
end
function gui.PFMTimeline:AddBookmark(bm)
	return self.m_timeline:AddBookmark(bm)
end
function gui.PFMTimeline:AddBookmarkSet(bms, timeFrame)
	return self.m_timeline:AddBookmarkSet(bms, timeFrame)
end
function gui.PFMTimeline:RemoveBookmarkSet(bms)
	return self.m_timeline:RemoveBookmarkSet(bms)
end
function gui.PFMTimeline:ClearBookmarks()
	self.m_timeline:ClearBookmarks()
end
function gui.PFMTimeline:InitializeToolbar()
	local toolbar = gui.create("WIBase", self.m_contents, 0, 0, self:GetWidth(), 0)
	toolbar:SetName("timeline_toolbar")
	local toolbarLeft = gui.create("WIHBox", toolbar, 0, 0)
	toolbarLeft:SetName("timeline_toolbar_left")
	local btGroup = gui.PFMButtonGroup(toolbarLeft)
	self.m_btClipEditor = btGroup:AddIconButton("film", function()
		pfm.undoredo.push(
			"set_timeline_editor",
			pfm.create_command("set_timeline_editor", self:GetEditor(), gui.PFMTimeline.EDITOR_CLIP)
		)()
		return true
	end)
	self.m_btClipEditor:SetName("clip_editor")
	self.m_btClipEditor:SetTooltip(
		locale.get_text("pfm_clip_editor", { pfm.get_key_binding("pfm_action select_editor clip") })
	)
	self.m_btMotionEditor = btGroup:AddIconButton("", function()
		self:SetEditor(gui.PFMTimeline.EDITOR_MOTION)
		return true
	end)
	self.m_btMotionEditor:SetTooltip(
		locale.get_text("pfm_motion_editor", { pfm.get_key_binding("pfm_action select_editor motion") })
	)
	self.m_btGraphEditor = btGroup:AddIconButton("graph-up", function()
		pfm.undoredo.push(
			"set_timeline_editor",
			pfm.create_command("set_timeline_editor", self:GetEditor(), gui.PFMTimeline.EDITOR_GRAPH)
		)()
		return true
	end)
	self.m_btGraphEditor:SetName("graph_editor")
	self.m_btGraphEditor:SetTooltip(
		locale.get_text("pfm_graph_editor", { pfm.get_key_binding("pfm_action select_editor graph") })
	)
	gui.create("WIBase", toolbarLeft):SetSize(32, 1) -- Gap

	self.m_controlButtons = {}
	local btBookmark = gui.PFMButtonGroup(toolbarLeft)
	self.m_btBookmarkKey = btBookmark:AddIconButton("bookmark-fill", function()
		tool.get_filmmaker():AddBookmark()
	end)
	self.m_btBookmarkKey:SetName("bookmark")
	self.m_controlButtons["bookmark"] = self.m_btBookmarkKey

	self.m_entryFields = gui.create("WIHBox", toolbarLeft)
	self.m_entryFields:SetName("kf_fields")
	self.m_entryFrame = gui.create("WITextEntry", self.m_entryFields, 0, 6, 60, 20)
	self.m_entryFrame:SetName("frame")
	self.m_entryValue = gui.create("WITextEntry", self.m_entryFields, 0, 6, 60, 20)
	self.m_entryValue:SetName("value")
	self.m_entryFrame:SetTooltip(locale.get_text("pfm_graph_editor_frame_field"))
	self.m_entryValue:SetTooltip(locale.get_text("pfm_graph_editor_frame_value"))

	self.m_entryFrame:AddCallback("OnTextEntered", function(el)
		local dps = self.m_timelineGraph:GetSelectedDataPoints(false, true)
		if #dps ~= 1 then
			return
		end
		local pm = pfm.get_project_manager()
		local t = pm:FrameOffsetToTimeOffset(el:GetText())
		dps[1]:ChangeDataValue(t, nil)
	end)
	self.m_entryValue:AddCallback("OnTextEntered", function(el)
		local dps = self.m_timelineGraph:GetSelectedDataPoints(false, true)
		if #dps ~= 1 then
			return
		end
		local pm = pfm.get_project_manager()
		local v = tonumber(el:GetText())
		dps[1]:ChangeDataValue(nil, v)
	end)

	self.m_controls = gui.create("WIHBox", toolbarLeft)
	self.m_controls:SetName("timeline_controls")

	local btGroupCtrls = gui.PFMButtonGroup(self.m_controls)
	self.m_btCtrlSelect = btGroupCtrls:AddIconButton("cursor-fill", function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SELECT)
		return true
	end)
	self.m_btCtrlSelect:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tool_select",
			{ pfm.get_key_binding("pfm_graph_editor_action select select") }
		)
	)
	self.m_controlButtons["select"] = self.m_btCtrlSelect

	self.m_btCtrlMove = btGroupCtrls:AddIconButton("arrows-move", function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_MOVE)
		return true
	end)
	self.m_btCtrlMove:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tool_move",
			{ pfm.get_key_binding("pfm_graph_editor_action select move"), locale.get_text("mouse_middle") }
		)
	)
	self.m_controlButtons["move"] = self.m_btCtrlMove

	self.m_btCtrlPan = btGroupCtrls:AddIconButton("pan", function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_PAN)
		return true
	end)
	self.m_btCtrlPan:SetTooltip(locale.get_text("pfm_graph_editor_tool_pan", {
		pfm.get_key_binding("pfm_graph_editor_action select pan"),
		locale.get_text("key_alt") .. " + " .. locale.get_text("mouse_middle"),
	}))
	self.m_controlButtons["pan"] = self.m_btCtrlPan

	self.m_btCtrlScale = btGroupCtrls:AddIconButton("grapheditor_scale_activated", function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SCALE)
		return true
	end)
	self.m_btCtrlScale:SetTooltip(locale.get_text("pfm_graph_editor_tool_scale", {
		pfm.get_key_binding("pfm_graph_editor_action select scale"),
		locale.get_text("key_ctrl") .. " + " .. locale.get_text("mouse_right"),
	}))
	self.m_controlButtons["scale"] = self.m_btCtrlScale

	self.m_btCtrlZoom = btGroupCtrls:AddIconButton("grapheditor_zoom_activated", function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_ZOOM)
		return true
	end)
	self.m_btCtrlZoom:SetTooltip(locale.get_text("pfm_graph_editor_tool_zoom", {
		pfm.get_key_binding("pfm_graph_editor_action select zoom"),
		locale.get_text("key_alt") .. " + " .. locale.get_text("mouse_right"),
	}))
	self.m_controlButtons["zoom"] = self.m_btCtrlZoom

	gui.create("WIBase", self.m_controls):SetSize(18, 1) -- Gap

	self.m_tangentControls = gui.create("WIHBox", toolbarLeft)
	self.m_tangentControls:SetName("timeline_tangent_controls")

	self.m_btTangentLinear = gui.PFMButton.create(self.m_tangentControls, "grapheditor_linear_activated", function()
		self:SetInterpolationMode(pfm.udm.INTERPOLATION_LINEAR)
	end)
	self.m_btTangentLinear:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_linear",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_linear") }
		)
	)
	self.m_controlButtons["tangent_linear"] = self.m_btTangentLinear

	self.m_btTangentFlat = gui.PFMButton.create(self.m_tangentControls, "tangents/flat-tangents", function()
		self:SetInterpolationMode(pfm.udm.INTERPOLATION_CONSTANT)
	end)
	self.m_btTangentFlat:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_flat",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_flat") }
		)
	)
	self.m_controlButtons["tangent_flat"] = self.m_btTangentFlat

	self.m_btTangentSpline = gui.PFMButton.create(self.m_tangentControls, "grapheditor_spline_activated", function()
		self:SetInterpolationMode(pfm.udm.INTERPOLATION_BEZIER)
	end)
	self.m_btTangentSpline:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_spline",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_spline") }
		)
	)
	self.m_controlButtons["tangent_spline"] = self.m_btTangentSpline

	self.m_btTangentStep = gui.PFMButton.create(self.m_tangentControls, "grapheditor_step_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btTangentStep:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_step",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_step") }
		)
	)
	self.m_controlButtons["tangent_step"] = self.m_btTangentStep

	self.m_btTangentUnified = gui.PFMButton.create(self.m_tangentControls, "grapheditor_unified_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btTangentUnified:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_unified",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_unify") }
		)
	)
	self.m_controlButtons["tangent_unify"] = self.m_btTangentUnified

	self.m_btTangentEqualize = gui.PFMButton.create(
		self.m_tangentControls,
		"grapheditor_isometric_activated",
		function()
			print("TODO: NOT YET IMPLEMENTED")
		end
	)
	self.m_btTangentEqualize:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_isometric",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_equalize") }
		)
	)
	self.m_controlButtons["tangent_equalize"] = self.m_btTangentEqualize

	self.m_btTangentWeighted = gui.PFMButton.create(self.m_tangentControls, "grapheditor_weighted_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btTangentWeighted:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_weighted",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_weighted") }
		)
	)
	self.m_controlButtons["tangent_weighted"] = self.m_btTangentWeighted

	self.m_btTangentUnweighted = gui.PFMButton.create(
		self.m_tangentControls,
		"grapheditor_unweighted_activated",
		function()
			print("TODO: NOT YET IMPLEMENTED")
		end
	)
	self.m_btTangentUnweighted:SetTooltip(
		locale.get_text(
			"pfm_graph_editor_tangent_unweighted",
			{ pfm.get_key_binding("pfm_graph_editor_action select tangent_unweighted") }
		)
	)
	self.m_controlButtons["tangent_unweighted"] = self.m_btTangentUnweighted

	gui.create("WIBase", self.m_tangentControls):SetSize(18, 1) -- Gap

	self.m_miscGraphControls = gui.create("WIHBox", toolbarLeft)

	self.m_btOffsetMode = gui.PFMButton.create(self.m_miscGraphControls, "grapheditor_offset_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btOffsetMode:SetName("offset_mode")
	self.m_btOffsetMode:SetTooltip(locale.get_text("pfm_graph_editor_offset_mode"))

	self.m_btAutoFrame = gui.PFMButton.create(self.m_miscGraphControls, "grapheditor_autoframe_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btAutoFrame:SetName("auto_frame")
	self.m_btAutoFrame:SetTooltip(locale.get_text("pfm_graph_editor_autoframe_mode"))

	self.m_btUnitize = gui.PFMButton.create(self.m_miscGraphControls, "grapheditor_unitize_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btUnitize:SetName("unitize")
	self.m_btUnitize:SetTooltip(locale.get_text("pfm_graph_editor_unitize_mode"))

	self.m_motionControls = gui.create("WIHBox", toolbarLeft)
	self.m_btTimeSelectionMode = gui.PFMButton.create(self.m_motionControls, "timeselectionmode_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btTimeSelectionMode:SetName("time_selection_mode")
	gui.create("WIBase", self.m_motionControls):SetSize(18, 1) -- Gap
	self.m_keyMode = gui.PFMButton.create(self.m_motionControls, "cp_keymode_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_keyMode:SetName("key_mode")

	gui.create("WIBase", toolbarLeft):SetSize(6, 1) -- Gap
	self.m_clipControls = gui.create("WIHBox", toolbarLeft)
	self.m_btAddTrackGroup = gui.PFMButton.create(self.m_clipControls, "cp_plus_drop_activated")
	self.m_btAddTrackGroup:SetName("track_group")
	self.m_btAddTrackGroup:SetupContextMenu(function(pContext)
		pContext:AddItem(locale.get_text("pfm_add_film_clip"), function()
			local filmmaker = tool.get_filmmaker()
			filmmaker:AddFilmClip()
		end)
	end, true)
	gui.create("WIBase", self.m_clipControls):SetSize(18, 1) -- Gap
	self.m_btUp = gui.PFMButton.create(self.m_clipControls, "timeline_up_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btUp:SetName("timeline_up")
	toolbarLeft:SetHeight(self.m_btClipEditor:GetHeight())

	local toolbarRight = gui.create("WIHBox", toolbar, 0, 0)
	toolbarRight:SetName("timeline_toolbar_right")
	self.m_btLockPlayhead = gui.PFMButton.create(toolbarRight, "timeline_head_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btLockPlayhead:SetName("lock_playhead")
	gui.create("WIBase", toolbarRight):SetSize(6, 1) -- Gap

	self.m_btSnap = gui.PFMButton.create(toolbarRight, "snap_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_controlButtons["snap"] = self.m_btSnap

	gui.create("WIBase", toolbarRight):SetSize(6, 1) -- Gap
	self.m_btSnapFrame = gui.PFMButton.create(toolbarRight, "snap_frame_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_controlButtons["snap_frame"] = self.m_btSnapFrame

	gui.create("WIBase", toolbarRight):SetSize(18, 1) -- Gap
	self.m_btPlayOnce = gui.PFMButton.create(toolbarRight, "cp_play_once_activated", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btPlayOnce:SetName("play_once")
	gui.create("WIBase", toolbarRight):SetSize(6, 1) -- Gap
	self.m_btMute = gui.PFMButton.create(toolbarRight, "volume-off-fill", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_controlButtons["mute"] = self.m_btMute

	gui.create("WIBase", toolbarRight):SetSize(6, 1) -- Gap
	self.m_btTools = gui.PFMButton.create(toolbarRight, "gear-fill", function()
		print("TODO: NOT YET IMPLEMENTED")
	end)
	self.m_btTools:SetName("tools")
	self.m_btTools:SetupContextMenu(function(pContext)
		pContext:AddItem(locale.get_text("pfm_fit_view_to_data"), function()
			self:GetGraphEditor():FitViewToDataRange()
		end)
	end, true)

	for name, el in pairs(self.m_controlButtons) do
		el:SetName(name)
	end

	toolbarRight:SetHeight(self.m_btLockPlayhead:GetHeight())
	toolbarRight:Update()
	toolbarRight:SetX(toolbar:GetWidth() - toolbarRight:GetWidth())
	toolbarRight:SetAnchor(1, 0, 1, 0)
	toolbar:SetHeight(toolbarLeft:GetHeight())
	toolbar:SetAnchor(0, 0, 1, 0)
end
function gui.PFMTimeline:GetControlButton(identifier)
	return self.m_controlButtons[identifier]
end
function gui.PFMTimeline:GroupDataPointsByCurve(dps)
	local map = {}
	for _, dp in ipairs(dps) do
		local curve = dp:GetGraphCurve()
		if curve:IsValid() then
			local curveIndex = curve:GetCurveIndex()
			if map[curveIndex] == nil then
				map[curveIndex] = {
					curve = curve,
					dataPoints = {},
				}
			end
			table.insert(map[curveIndex].dataPoints, dp)
		end
	end
	return map
end
function gui.PFMTimeline:CreateCurveCompositionCommand(cmd, curve)
	local animClip = curve:GetAnimationClip()
	local actor = animClip:GetActor()
	local propertyPath = curve:GetTargetPath()
	local baseIndex = curve:GetTypeComponentIndex()
	local res, subCmd =
		cmd:AddSubCommand("keyframe_property_composition", tostring(actor:GetUniqueId()), propertyPath, baseIndex)
	return subCmd
end
function gui.PFMTimeline:SetInterpolationMode(mode)
	local dps = self.m_timelineGraph:GetSelectedDataPoints(false, true)
	local cmd = pfm.create_command("composition")
	for curveIndex, curveInfo in pairs(self:GroupDataPointsByCurve(dps)) do
		local subCmd = self:CreateCurveCompositionCommand(cmd, curveInfo.curve)
		local animClip = curveInfo.curve:GetAnimationClip()
		for _, dp in ipairs(curveInfo.dataPoints) do
			local editorKey, keyIndex = dp:GetEditorKeys()
			if editorKey ~= nil then
				local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
				local keyIndex = dp:GetKeyIndex()
				local baseIndex = dp:GetTypeComponentIndex()
				subCmd:AddSubCommand(
					"set_keyframe_interpolation_mode",
					tostring(actor:GetUniqueId()),
					targetPath,
					animClip:ToClipTime(editorKey:GetTime(keyIndex)),
					editorKey:GetInterpolationMode(keyIndex),
					mode,
					baseIndex
				)
			end
		end
	end
	pfm.undoredo.push("set_keyframe_interpolation_mode", cmd)()
end
function gui.PFMTimeline:SetEasingMode(mode)
	local dps = self.m_timelineGraph:GetSelectedDataPoints(false, true)
	local cmd = pfm.create_command("composition")
	for curveIndex, curveInfo in pairs(self:GroupDataPointsByCurve(dps)) do
		local subCmd = self:CreateCurveCompositionCommand(cmd, curveInfo.curve)
		local animClip = curveInfo.curve:GetAnimationClip()
		for _, dp in ipairs(curveInfo.dataPoints) do
			local editorKey, keyIndex = dp:GetEditorKeys()
			if editorKey ~= nil then
				local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
				local keyIndex = dp:GetKeyIndex()
				local baseIndex = dp:GetTypeComponentIndex()
				subCmd:AddSubCommand(
					"set_keyframe_easing_mode",
					tostring(actor:GetUniqueId()),
					targetPath,
					animClip:ToClipTime(editorKey:GetTime(keyIndex)),
					editorKey:GetEasingMode(keyIndex),
					mode,
					baseIndex
				)
			end
		end
	end
	pfm.undoredo.push("set_keyframe_easing_mode", cmd)()
end
function gui.PFMTimeline:SetHandleType(type)
	local dps = self.m_timelineGraph:GetSelectedDataPoints(false, true)
	local cmd = pfm.create_command("composition")
	for curveIndex, curveInfo in pairs(self:GroupDataPointsByCurve(dps)) do
		local subCmd = self:CreateCurveCompositionCommand(cmd, curveInfo.curve)
		local animClip = curveInfo.curve:GetAnimationClip()
		for _, dp in ipairs(curveInfo.dataPoints) do
			local editorKey, keyIndex = dp:GetEditorKeys()
			if editorKey ~= nil then
				local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
				local keyIndex = dp:GetKeyIndex()
				local baseIndex = dp:GetTypeComponentIndex()
				for _, handleId in ipairs({
					pfm.udm.EditorGraphCurveKeyData.HANDLE_IN,
					pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT,
				}) do
					subCmd:AddSubCommand(
						"set_keyframe_handle_type",
						tostring(actor:GetUniqueId()),
						targetPath,
						animClip:ToClipTime(editorKey:GetTime(keyIndex)),
						editorKey:GetHandleType(keyIndex, handleId),
						type,
						baseIndex,
						handleId
					)
				end
			end
		end
	end
	pfm.undoredo.push("set_keyframe_handle_type", cmd)()
end
function gui.PFMTimeline:SetDataValue(t, v)
	self.m_entryFrame:SetText(tostring(t))
	self.m_entryValue:SetText(tostring(v))
end
gui.register("WIPFMTimeline", gui.PFMTimeline)

console.register_command("pfm_graph_editor_action", function(pl, ...)
	local pm = tool.get_filmmaker()
	local timeline = util.is_valid(pm) and pm:GetTimeline() or nil
	if util.is_valid(timeline) == false then
		return
	end
	local args = { ... }
	if args[1] == "select" then
		local tool = args[2]
		local bt = timeline:GetControlButton(tool or "")
		if bt ~= nil then
			bt:InjectMouseInput(bt:GetCursorPos(), input.MOUSE_BUTTON_LEFT, input.STATE_PRESS, input.MOD_NONE)
			time.create_simple_timer(0.1, function()
				if bt:IsValid() then
					bt:InjectMouseInput(bt:GetCursorPos(), input.MOUSE_BUTTON_LEFT, input.STATE_RELEASE, input.MOD_NONE)
				end
			end)
		end
	end
end)

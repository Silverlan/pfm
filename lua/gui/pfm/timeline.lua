--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/timeline.lua")
include("editors")

util.register_class("gui.PFMTimeline",gui.Base)

gui.PFMTimeline.EDITOR_CLIP = 0
gui.PFMTimeline.EDITOR_MOTION = 1
gui.PFMTimeline.EDITOR_GRAPH = 2
function gui.PFMTimeline:__init()
	gui.Base.__init(self)
end
function gui.PFMTimeline:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,128)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))
	self.m_bg:SetName("timeline_background")

	self.m_contents = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetName("timeline_contents")
	self:InitializeToolbar()
	gui.create("WIBase",self.m_contents):SetSize(1,7) -- Gap

	self.m_timeline = gui.create("WITimeline",self.m_contents)
	self.m_timeline:SetName("timeline_strip")

	self.m_timeline:SetZoomLevel(0.0)
	self.m_timeline:SetStartOffset(1.0)
	self.m_timeline:Update()

	self.m_timeline:AddCallback("OnTimelineUpdate",function()
		self:OnTimelineUpdate()
	end)
	self.m_timelineClips = {}

	local contents = self.m_timeline:GetContents()
	self.m_timelineClip = gui.create("WIPFMTimelineClip",contents,0,0,contents:GetWidth(),contents:GetHeight(),0,0,1,1)
	self.m_timelineClip:SetName("timeline_clip_editor")
	self.m_timelineMotion = gui.create("WIPFMTimelineMotion",contents,0,0,contents:GetWidth(),contents:GetHeight(),0,0,1,1)
	self.m_timelineMotion:SetName("timeline_motion_editor")
	self.m_timelineGraph = gui.create("WIPFMTimelineGraph",contents,0,0,contents:GetWidth(),contents:GetHeight(),0,0,1,1)
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
function gui.PFMTimeline:GetSelectedClip() return self.m_selectedClip end
function gui.PFMTimeline:InitializeClip(clip,fOnSelected)
	clip:AddCallback("OnSelected",function(el)
		if(self:IsValid() == false) then return end
		if(util.is_valid(self.m_selectedClip)) then self.m_selectedClip:SetSelected(false) end
		self.m_selectedClip = clip

		self:CallCallbacks("OnClipSelected",clip)
		if(fOnSelected ~= nil) then fOnSelected(clip) end
	end)
	clip:AddCallback("OnDeselected",function(el)
		if(self:IsValid() == false) then return end
		
	end)
	table.insert(self.m_timelineClips,clip)
end
function gui.PFMTimeline:AddFilmClip(filmStrip,filmClip,fOnSelected)
	local elClip = gui.create("WIFilmClip",filmStrip.m_container)
	table.insert(filmStrip.m_filmClips,elClip)

	elClip:SetFilmClipData(filmClip)
	filmStrip:ScheduleUpdate()

	self:InitializeClip(elClip,fOnSelected)
	return elClip
end
function gui.PFMTimeline:AddAudioClip(group,audioClip,fOnSelected)
	local elClip = gui.create("WIGenericClip")
	elClip:AddStyleClass("timeline_clip_audio")
	group:AddElement(elClip)
	elClip:SetText(audioClip:GetName())

	self.m_timeline:AddTimelineItem(elClip,audioClip:GetTimeFrame())

	self:InitializeClip(elClip,fOnSelected)
	return elClip
end
function gui.PFMTimeline:AddOverlayClip(group,overlayClip,fOnSelected)
	local elClip = gui.create("WIGenericClip")
	elClip:AddStyleClass("timeline_clip_overlay")
	group:AddElement(elClip)
	elClip:SetText(overlayClip:GetName())
	self.m_timeline:AddTimelineItem(elClip,overlayClip:GetTimeFrame())

	self:InitializeClip(elClip,fOnSelected)
	return elClip
end
function gui.PFMTimeline:GetEditorTimelineElement(type)
	if(type == gui.PFMTimeline.EDITOR_CLIP) then return self.m_timelineClip end
	if(type == gui.PFMTimeline.EDITOR_MOTION) then return self.m_timelineMotion end
	if(type == gui.PFMTimeline.EDITOR_GRAPH) then return self.m_timelineGraph end
end
function gui.PFMTimeline:OnTimelineUpdate()
	if(util.is_valid(self.m_timeline) == false) then return end
	if(util.is_valid(self.m_timelineGraph)) then
		local posTimeline = self.m_timeline:GetAbsolutePos()
		local posGraph = self.m_timelineGraph:GetAbsolutePos()
		local axis = self.m_timeline:GetTimeAxis():GetAxis()
		local startTime = axis:XOffsetToValue(posGraph.x -posTimeline.x)
		local endTime = axis:XOffsetToValue(posGraph.x +self.m_timelineGraph:GetWidth() -posTimeline.x)
		self.m_timelineGraph:SetTimeRange(startTime,endTime,axis:GetStartOffset(),axis:GetZoomLevel())
	end
end
function gui.PFMTimeline:GetEditor() return self.m_editorType end
function gui.PFMTimeline:SetEditor(type)
	if(type == self:GetEditor()) then return end
	self.m_lastEditorType = self.m_editorType
	self.m_editorType = type
	if(util.is_valid(self.m_clipControls)) then self.m_clipControls:SetVisible(type == gui.PFMTimeline.EDITOR_CLIP) end

	if(util.is_valid(self.m_motionControls)) then self.m_motionControls:SetVisible(type == gui.PFMTimeline.EDITOR_MOTION) end

	if(util.is_valid(self.m_entryFields)) then self.m_entryFields:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH) end
	if(util.is_valid(self.m_controls)) then self.m_controls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH) end
	if(util.is_valid(self.m_tangentControls)) then self.m_tangentControls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH) end
	if(util.is_valid(self.m_miscGraphControls)) then self.m_miscGraphControls:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH) end

	if(util.is_valid(self.m_btClipEditor)) then self.m_btClipEditor:SetActivated(type == gui.PFMTimeline.EDITOR_CLIP) end
	if(util.is_valid(self.m_btMotionEditor)) then self.m_btMotionEditor:SetActivated(type == gui.PFMTimeline.EDITOR_MOTION) end
	if(util.is_valid(self.m_btGraphEditor)) then self.m_btGraphEditor:SetActivated(type == gui.PFMTimeline.EDITOR_GRAPH) end

	if(util.is_valid(self.m_btClipEditor)) then self.m_btClipEditor:SetActivated(type == gui.PFMTimeline.EDITOR_CLIP) end

	if(util.is_valid(self.m_timelineClip)) then self.m_timelineClip:SetVisible(type == gui.PFMTimeline.EDITOR_CLIP) end
	if(util.is_valid(self.m_timelineMotion)) then self.m_timelineMotion:SetVisible(type == gui.PFMTimeline.EDITOR_MOTION) end
	if(util.is_valid(self.m_timelineGraph)) then self.m_timelineGraph:SetVisible(type == gui.PFMTimeline.EDITOR_GRAPH) end

	self:UpdateEditorButtonInactiveMaterial(gui.PFMTimeline.EDITOR_CLIP,"gui/pfm/icon_mode_timeline","gui/pfm/icon_mode_timeline_preselected")
	self:UpdateEditorButtonInactiveMaterial(gui.PFMTimeline.EDITOR_MOTION,"gui/pfm/icon_mode_motioneditor","gui/pfm/icon_mode_motioneditor_preselected")
	self:UpdateEditorButtonInactiveMaterial(gui.PFMTimeline.EDITOR_GRAPH,"gui/pfm/icon_mode_grapheditor","gui/pfm/icon_mode_grapheditor_preselected")
end
function gui.PFMTimeline:UpdateEditorButtonInactiveMaterial(editorType,matRegular,matPreselected)
	local bt = ((editorType == gui.PFMTimeline.EDITOR_CLIP) and self.m_btClipEditor) or
		((editorType == gui.PFMTimeline.EDITOR_MOTION) and self.m_btMotionEditor) or
		((editorType == gui.PFMTimeline.EDITOR_GRAPH) and self.m_btGraphEditor)
	if(util.is_valid(bt) == false) then return end
	bt:SetUnpressedMaterial((self.m_lastEditorType == editorType) and matPreselected or matRegular)
end
function gui.PFMTimeline:GetClipEditor() return self.m_timelineClip end
function gui.PFMTimeline:GetMotionEditor() return self.m_timelineMotion end
function gui.PFMTimeline:GetGraphEditor() return self.m_timelineGraph end
function gui.PFMTimeline:GetTimeline() return self.m_timeline end
function gui.PFMTimeline:GetPlayhead() return util.is_valid(self.m_timeline) and self.m_timeline:GetPlayhead() or nil end
function gui.PFMTimeline:SetGraphCursorMode(cursorMode)
	local buttons = {
		[gui.PFMTimelineGraph.CURSOR_MODE_SELECT] = self.m_btCtrlSelect,
		[gui.PFMTimelineGraph.CURSOR_MODE_MOVE] = self.m_btCtrlMove,
		[gui.PFMTimelineGraph.CURSOR_MODE_PAN] = self.m_btCtrlPan,
		[gui.PFMTimelineGraph.CURSOR_MODE_SCALE] = self.m_btCtrlScale,
		[gui.PFMTimelineGraph.CURSOR_MODE_ZOOM] = self.m_btCtrlZoom,
	}
	for btCursorMode,bt in pairs(buttons) do
		if(bt:IsValid()) then
			bt:SetActivated(btCursorMode == cursorMode)
		end
	end
end
function gui.PFMTimeline:InitializeToolbar()
	local toolbar = gui.create("WIBase",self.m_contents,0,0,self:GetWidth(),0)
	toolbar:SetName("timeline_toolbar")
	local toolbarLeft = gui.create("WIHBox",toolbar,0,0)
	toolbarLeft:SetName("timeline_toolbar_left")
	self.m_btClipEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_timeline","gui/pfm/icon_mode_timeline_activated",function()
		self:SetEditor(gui.PFMTimeline.EDITOR_CLIP)
		return true
	end)
	self.m_btClipEditor:SetTooltip(locale.get_text("pfm_clip_editor",{pfm.get_key_binding("clip_editor")}))
	self.m_btMotionEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_motioneditor","gui/pfm/icon_mode_motioneditor_activated",function()
		self:SetEditor(gui.PFMTimeline.EDITOR_MOTION)
		return true
	end)
	self.m_btMotionEditor:SetTooltip(locale.get_text("pfm_motion_editor",{pfm.get_key_binding("motion_editor")}))
	self.m_btGraphEditor = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_mode_grapheditor","gui/pfm/icon_mode_grapheditor_activated",function()
		self:SetEditor(gui.PFMTimeline.EDITOR_GRAPH)
		return true
	end)
	self.m_btGraphEditor:SetTooltip(locale.get_text("pfm_graph_editor",{pfm.get_key_binding("graph_editor")}))
	gui.create("WIBase",toolbarLeft):SetSize(32,1) -- Gap
	self.m_btBookmarkKey = gui.PFMButton.create(toolbarLeft,"gui/pfm/icon_bookmark","gui/pfm/icon_bookmark_activated",function()
		print("TODO")
	end)

	self.m_entryFields = gui.create("WIHBox",toolbarLeft)
	self.m_entryFrame = gui.create("WITextEntry",self.m_entryFields,0,6,60,20)
	self.m_entryValue = gui.create("WITextEntry",self.m_entryFields,0,6,60,20)

	self.m_controls = gui.create("WIHBox",toolbarLeft)
	self.m_controls:SetName("timeline_controls")
	self.m_btCtrlSelect = gui.PFMButton.create(self.m_controls,"gui/pfm/icon_grapheditor_select","gui/pfm/icon_grapheditor_select_activated",function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SELECT)
		return true
	end)
	self.m_btCtrlMove = gui.PFMButton.create(self.m_controls,"gui/pfm/icon_manipulator_move","gui/pfm/icon_manipulator_move_activated",function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_MOVE)
		return true
	end)
	self.m_btCtrlPan = gui.PFMButton.create(self.m_controls,"gui/pfm/icon_grapheditor_pan","gui/pfm/icon_grapheditor_pan_activated",function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_PAN)
		return true
	end)
	self.m_btCtrlScale = gui.PFMButton.create(self.m_controls,"gui/pfm/icon_grapheditor_scale","gui/pfm/icon_grapheditor_scale_activated",function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SCALE)
		return true
	end)
	self.m_btCtrlZoom = gui.PFMButton.create(self.m_controls,"gui/pfm/icon_grapheditor_zoom","gui/pfm/icon_grapheditor_zoom_activated",function()
		self:SetGraphCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_ZOOM)
		return true
	end)
	gui.create("WIBase",self.m_controls):SetSize(18,1) -- Gap

	self.m_tangentControls = gui.create("WIHBox",toolbarLeft)
	self.m_tangentControls:SetName("timeline_tangent_controls")
	self.m_btTangentLinear = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_linear","gui/pfm/icon_grapheditor_linear_activated",function()
		print("TODO")
	end)
	self.m_btTangentFlat = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_flat","gui/pfm/icon_grapheditor_flat_activated",function()
		print("TODO")
	end)
	self.m_btTangentSpline = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_spline","gui/pfm/icon_grapheditor_spline_activated",function()
		print("TODO")
	end)
	self.m_btTangentStep = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_step","gui/pfm/icon_grapheditor_step_activated",function()
		print("TODO")
	end)
	self.m_btTangentUnified = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_unified","gui/pfm/icon_grapheditor_unified_activated",function()
		print("TODO")
	end)
	self.m_btTangentEqualize = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_isometric","gui/pfm/icon_grapheditor_isometric_activated",function()
		print("TODO")
	end)
	self.m_btTangentWeighted = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_weighted","gui/pfm/icon_grapheditor_weighted_activated",function()
		print("TODO")
	end)
	self.m_btTangentWeighted = gui.PFMButton.create(self.m_tangentControls,"gui/pfm/icon_grapheditor_unweighted","gui/pfm/icon_grapheditor_unweighted_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",self.m_tangentControls):SetSize(18,1) -- Gap

	self.m_miscGraphControls = gui.create("WIHBox",toolbarLeft)
	self.m_btOffsetMode = gui.PFMButton.create(self.m_miscGraphControls,"gui/pfm/icon_grapheditor_offset","gui/pfm/icon_grapheditor_offset_activated",function()
		print("TODO")
	end)
	self.m_btAutoFrame = gui.PFMButton.create(self.m_miscGraphControls,"gui/pfm/icon_grapheditor_autoframe","gui/pfm/icon_grapheditor_autoframe_activated",function()
		print("TODO")
	end)
	self.m_btUnitize = gui.PFMButton.create(self.m_miscGraphControls,"gui/pfm/icon_grapheditor_unitize","gui/pfm/icon_grapheditor_unitize_activated",function()
		print("TODO")
	end)

	self.m_motionControls = gui.create("WIHBox",toolbarLeft)
	self.m_btTimeSelectionMode = gui.PFMButton.create(self.m_motionControls,"gui/pfm/icon_timeselectionmode","gui/pfm/icon_timeselectionmode_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",m_motionControls):SetSize(18,1) -- Gap
	self.m_keyMode = gui.PFMButton.create(self.m_motionControls,"gui/pfm/icon_cp_keymode","gui/pfm/icon_cp_keymode_activated",function()
		print("TODO")
	end)

	gui.create("WIBase",toolbarLeft):SetSize(6,1) -- Gap
	self.m_clipControls = gui.create("WIHBox",toolbarLeft)
	self.m_btAddTrackGroup = gui.PFMButton.create(self.m_clipControls,"gui/pfm/icon_cp_plus_drop","gui/pfm/icon_cp_plus_drop_activated")
	self.m_btAddTrackGroup:SetupContextMenu(function(pContext)
		pContext:AddItem(locale.get_text("pfm_add_film_clip"),function()
			local filmmaker = tool.get_filmmaker()
			local session = filmmaker:GetSession()
			session:AddFilmClip()
		end)
	end,true)
	gui.create("WIBase",self.m_clipControls):SetSize(18,1) -- Gap
	self.m_btUp = gui.PFMButton.create(self.m_clipControls,"gui/pfm/icon_timeline_up","gui/pfm/icon_timeline_up_activated",function()
		print("TODO")
	end)
	toolbarLeft:SetHeight(self.m_btClipEditor:GetHeight())

	local toolbarRight = gui.create("WIHBox",toolbar,0,0)
	toolbarRight:SetName("timeline_toolbar_right")
	self.m_btLockPlayhead = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_timeline_head","gui/pfm/icon_timeline_head_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btSnap = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_snap","gui/pfm/icon_snap_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btSnapFrame = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_snap_frame","gui/pfm/icon_snap_frame_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",toolbarRight):SetSize(18,1) -- Gap
	self.m_btPlayOnce = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_cp_play_once","gui/pfm/icon_cp_play_once_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btMute = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_mute","gui/pfm/icon_mute_activated",function()
		print("TODO")
	end)
	gui.create("WIBase",toolbarRight):SetSize(6,1) -- Gap
	self.m_btTools = gui.PFMButton.create(toolbarRight,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("TODO")
	end)
	toolbarRight:SetHeight(self.m_btLockPlayhead:GetHeight())
	toolbarRight:Update()
	toolbarRight:SetX(toolbar:GetWidth() -toolbarRight:GetWidth())
	toolbarRight:SetAnchor(1,0,1,0)
	toolbar:SetHeight(toolbarLeft:GetHeight())
	toolbar:SetAnchor(0,0,1,0)
end
gui.register("WIPFMTimeline",gui.PFMTimeline)

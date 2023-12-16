--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.PFMTriangle", gui.Base)
Element.POSITION_TOP_LEFT = 0
Element.POSITION_TOP_RIGHT = 1
Element.POSITION_BOTTOM_LEFT = 2
Element.POSITION_BOTTOM_RIGHT = 3
local g_triangleBuffers = {}
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	local elShape = gui.create("WIShape", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elShape:GetColorProperty():Link(self:GetColorProperty())
	self.m_elShape = elShape
end
function Element:SetTrianglePos(pos)
	self:InitializeBuffer(pos)
end
function Element:InitializeBuffer(pos)
	local buf = g_triangleBuffers[pos]
	if buf ~= nil then
		self.m_elShape:SetBuffer(buf, 3)
		return
	end
	local verts = {}
	if pos == Element.POSITION_TOP_LEFT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, -1))
	elseif pos == Element.POSITION_TOP_RIGHT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(1, 1))
		table.insert(verts, Vector2(1, -1))
	elseif pos == Element.POSITION_BOTTOM_LEFT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, 1))
	elseif pos == Element.POSITION_BOTTOM_RIGHT then
		table.insert(verts, Vector2(1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, 1))
	end
	self.m_elShape:ClearVertices()
	for _, v in ipairs(verts) do
		self.m_elShape:AddVertex(v)
	end
	self.m_elShape:Update()
	g_triangleBuffers[pos] = self.m_elShape:GetBuffer()
end
gui.register("WIPFMTriangle", Element)

local Element = util.register_class("gui.PFMPartialTimeSelectionBar", gui.Base)
Element.POSITION_LEFT = 0
Element.POSITION_RIGHT = 1
local lineOffset = 16
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64 + lineOffset * 2)

	self.m_triTop = gui.create("WIPFMTriangle", self, 0, 0, self:GetWidth(), lineOffset, 0, 0, 1, 0)
	self.m_triBottom =
		gui.create("WIPFMTriangle", self, 0, self:GetHeight() - lineOffset, self:GetWidth(), lineOffset, 0, 1, 1, 1)

	self.m_centerBar = gui.create("WIRect", self, 0, lineOffset, 64, self:GetHeight() - lineOffset * 2, 0, 0, 1, 1)

	self.m_triTop:GetColorProperty():Link(self:GetColorProperty())
	self.m_triBottom:GetColorProperty():Link(self:GetColorProperty())
	self.m_centerBar:GetColorProperty():Link(self:GetColorProperty())

	local lineInner = gui.create("WIRect", self)
	lineInner:SetColor(Color.Black)
	self.m_lineInner = lineInner

	local lineOuter = gui.create("WIRect", self)
	lineOuter:SetColor(Color.White)
	self.m_lineOuter = lineOuter
end
function Element:SetBarPosition(pos)
	if pos == Element.POSITION_LEFT then
		self.m_triTop:SetTrianglePos(gui.PFMTriangle.POSITION_BOTTOM_RIGHT)
		self.m_triBottom:SetTrianglePos(gui.PFMTriangle.POSITION_TOP_RIGHT)

		self.m_lineInner:ClearAnchor()
		self.m_lineInner:SetPos(0, lineOffset)
		self.m_lineInner:SetSize(1, self:GetHeight() - lineOffset * 2)
		self.m_lineInner:SetAnchor(0, 0, 0, 1)

		self.m_lineOuter:ClearAnchor()
		self.m_lineOuter:SetPos(self:GetRight() - 1, 0)
		self.m_lineOuter:SetSize(1, self:GetHeight())
		self.m_lineOuter:SetAnchor(1, 0, 1, 1)
	elseif pos == Element.POSITION_RIGHT then
		self.m_triTop:SetTrianglePos(gui.PFMTriangle.POSITION_BOTTOM_LEFT)
		self.m_triBottom:SetTrianglePos(gui.PFMTriangle.POSITION_TOP_LEFT)

		self.m_lineInner:ClearAnchor()
		self.m_lineInner:SetPos(self:GetWidth() - 1, lineOffset)
		self.m_lineInner:SetSize(1, self:GetHeight() - lineOffset * 2)
		self.m_lineInner:SetAnchor(1, 0, 1, 1)

		self.m_lineOuter:ClearAnchor()
		self.m_lineOuter:SetPos(0, 0)
		self.m_lineOuter:SetSize(1, self:GetHeight())
		self.m_lineOuter:SetAnchor(0, 0, 0, 1)
	end
end
gui.register("WIPFMPartialTimeSelectionBar", Element)

local Element = util.register_class("gui.PFMPartialTimeSelection", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256, 256)

	local function add_drag_callback(el, i, getTargetMarkers)
		el:SetMouseInputEnabled(true)
		el:SetCursor(gui.CURSOR_SHAPE_CROSSHAIR)
		el:AddCallback("OnMouseEvent", function(el, button, state, mods)
			if self:MouseCallback(button, state, mods) == util.EVENT_REPLY_HANDLED then
				return util.EVENT_REPLY_HANDLED
			end
			if button == input.MOUSE_BUTTON_LEFT then
				if state == input.STATE_PRESS then
					self:StartDragMode(i, (getTargetMarkers ~= nil) and getTargetMarkers() or { i + 1 })
				else
					self:StopDragMode()
				end
				return util.EVENT_REPLY_HANDLED
			end
		end)
	end

	self.m_leftBar = gui.create("WIPFMPartialTimeSelectionBar", self)
	self.m_leftBar:SetBarPosition(gui.PFMPartialTimeSelectionBar.POSITION_LEFT)
	self.m_leftBar:SetSize(64, self:GetHeight())
	--self.m_leftBar:SetAnchor(0, 0, 0, 1)
	add_drag_callback(self.m_leftBar, 0)

	self.m_rightBar = gui.create("WIPFMPartialTimeSelectionBar", self)
	self.m_rightBar:SetBarPosition(gui.PFMPartialTimeSelectionBar.POSITION_RIGHT)
	self.m_rightBar:SetSize(64, self:GetHeight())
	self.m_rightBar:SetX(self:GetWidth() - 64)
	--self.m_rightBar:SetAnchor(1, 0, 1, 1)
	add_drag_callback(self.m_rightBar, 2)

	self.m_centerBar = gui.create(
		"WIRect",
		self,
		self.m_leftBar:GetRight(),
		0,
		(self.m_rightBar:GetLeft() - self.m_leftBar:GetRight()),
		self:GetHeight()
	)
	self.m_centerBar:SetAnchor(0, 0, 1, 1)
	add_drag_callback(self.m_centerBar, 1, function()
		local targetMarkers = { 2 }
		if self:IsInnerStartPositionLocked() then
			table.insert(targetMarkers, 0)
		end
		if self:IsInnerEndPositionLocked() then
			table.insert(targetMarkers, 3)
		end
		return targetMarkers
	end)

	local col = Color(0, 64, 0, 255)
	self.m_leftBar:SetColor(col)
	self.m_rightBar:SetColor(col)
	self.m_centerBar:SetColor(col)
	self:SetAlpha(128)

	self.m_timelineMarkers = {}

	self:SetMouseInputEnabled(true)
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			if input.is_shift_key_down() then
				if util.is_valid(self.m_timeline) == false then
					return
				end
				self.m_creatingInnerSelection = true
				local axis = self.m_timeline:GetTimeAxis():GetAxis()
				local pos = self.m_timeline:GetCursorPos()
				local t = axis:XOffsetToValue(pos.x)
				self:SetInnerStartTime(t)
				self.m_timelineMarkers[3]:SetCursorMoveModeEnabled(true)
				return util.EVENT_REPLY_HANDLED
			end
		elseif self.m_creatingInnerSelection then
			self.m_creatingInnerSelection = false
			self.m_timelineMarkers[3]:SetCursorMoveModeEnabled(false)
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_HANDLED
	end
	return gui.PFMTimelineGraphBase.MouseCallback(self, button, state, mods)
end
function Element:StartDragMode(i, targetMarkers)
	if util.is_valid(self.m_timelineMarkers[i + 1]) == false then
		return
	end
	self.m_timelineMarkers[i + 1]:SetCursorMoveModeEnabled(true, true)
	self.m_dragMarker = i
	self.m_dragTargetMarkers = targetMarkers
end
function Element:StopDragMode()
	if self.m_dragMarker == nil then
		return
	end
	if util.is_valid(self.m_timelineMarkers[self.m_dragMarker + 1]) then
		self.m_timelineMarkers[self.m_dragMarker + 1]:SetCursorMoveModeEnabled(false)
	end
	self.m_dragTargetMarkers = nil
	self.m_dragMarker = nil
end
function Element:OnRemove()
	util.remove({ self.m_timelineMarkers, self.m_cbOnTimelineSizeChanged })
end
function Element:OnMarkerDragUpdate(i)
	if self.m_dragTargetMarkers == nil then
		return
	end
	local marker = self.m_timelineMarkers[self.m_dragMarker + 1]
	if util.is_valid(marker) == false then
		return
	end
	local function update_relative_position(isrc, idst)
		local offset = self.m_dragTimelineMarkerTimes[idst] - self.m_dragTimelineMarkerTimes[isrc]
		local t = self.m_timelineMarkers[isrc]:GetTimeOffset() + offset
		self.m_timelineMarkers[idst]:SetTimeOffset(t)
	end
	for _, iTargetMarker in ipairs(self.m_dragTargetMarkers) do
		update_relative_position(self.m_dragMarker + 1, iTargetMarker + 1)
	end
end
function Element:SetupTimelineMarkers(timeline)
	local function add_marker(i)
		local el = gui.create("WITimelineMarker", timeline)
		el:SetWidth(10)
		el:SetHeight(timeline:GetHeight())
		el:SetAxis(timeline:GetTimeAxis():GetAxis())
		timeline:AddTimelineElement(el)

		el:AddCallback("OnAxisPositionUpdated", function()
			self:UpdateSelectionBounds()
		end)
		el:AddCallback("OnDragStart", function()
			self.m_dragTimelineMarkerTimes = {}
			for _, el in ipairs(self.m_timelineMarkers) do
				local t = 0
				if el:IsValid() then
					t = el:GetTimeOffset()
				end
				table.insert(self.m_dragTimelineMarkerTimes, t)
			end
		end)
		el:AddCallback("OnDragUpdate", function()
			self:OnMarkerDragUpdate(i)
		end)
		return el
	end

	self.m_timeline = timeline
	util.remove({ self.m_timelineMarkers, self.m_cbOnTimelineSizeChanged })
	self.m_cbOnTimelineSizeChanged = timeline:AddCallback("SetSize", function(timeline)
		for _, el in ipairs(self.m_timelineMarkers) do
			el:SetHeight(timeline:GetHeight())
		end
	end)
	self.m_timelineMarkers = {}
	for i = 1, 4 do
		table.insert(self.m_timelineMarkers, add_marker(i - 1))
	end
end
function Element:ClampTimes()
	local m0 = self.m_timelineMarkers[1]
	local m1 = self.m_timelineMarkers[2]
	local m2 = self.m_timelineMarkers[3]
	local m3 = self.m_timelineMarkers[4]
	local t0 = m0:GetTimeOffset()
	local t1 = m1:GetTimeOffset()
	local t2 = m2:GetTimeOffset()
	local t3 = m3:GetTimeOffset()

	if t3 < t0 then
		m3:SetTimeOffset(t0)
	end
	if t1 < t0 then
		m1:SetTimeOffset(t0)
	end
	if t2 < t1 then
		m2:SetTimeOffset(t1)
	end
	if t2 > t3 then
		m2:SetTimeOffset(t3)
	end
end
function Element:GetStartTime()
	return self.m_timelineMarkers[1]:GetTimeOffset()
end
function Element:GetInnerStartTime()
	return self.m_timelineMarkers[2]:GetTimeOffset()
end
function Element:GetInnerEndTime()
	return self.m_timelineMarkers[3]:GetTimeOffset()
end
function Element:GetEndTime()
	return self.m_timelineMarkers[4]:GetTimeOffset()
end
function Element:SetStartTime(t)
	self.m_timelineMarkers[1]:SetTimeOffset(t)
end
function Element:SetInnerStartTime(t)
	self.m_timelineMarkers[2]:SetTimeOffset(t)
end
function Element:SetInnerEndTime(t)
	self.m_timelineMarkers[3]:SetTimeOffset(t)
end
function Element:SetEndTime(t)
	self.m_timelineMarkers[4]:SetTimeOffset(t)
end
function Element:UpdateSelectionBounds()
	if self.m_dragTimelineMarkerTimes == nil or #self.m_dragTimelineMarkerTimes == 0 then
		return
	end
	self:ClampTimes()
	if util.is_valid(self.m_timeline) == false then
		return
	end
	local axis = self.m_timeline:GetTimeAxis():GetAxis()
	local xValues = {
		math.round(axis:ValueToXOffset(self:GetStartTime())),
		math.round(axis:ValueToXOffset(self:GetInnerStartTime())),
		math.round(axis:ValueToXOffset(self:GetInnerEndTime())),
		math.round(axis:ValueToXOffset(self:GetEndTime())),
	}
	self:SetX(xValues[1])
	self:SetInnerStartPosition(xValues[2] - xValues[1])
	self:SetInnerEndPosition(xValues[4] - xValues[3])
	self:SetWidth(xValues[4] - xValues[1])

	self:UpdateCenterBar()
end
function Element:SetInnerStartPosition(pos)
	pos = math.max(pos, 0)
	self.m_leftBar:SetWidth(pos)
	self:UpdateCenterBar()
end
function Element:SetInnerEndPosition(pos)
	pos = math.max(pos, 0)
	self.m_rightBar:SetWidth(pos)
	self:UpdateCenterBar()
end
function Element:IsInnerStartPositionLocked()
	return self.m_leftBar:GetWidth() == 0
end
function Element:IsInnerEndPositionLocked()
	return self.m_rightBar:GetWidth() == 0
end
function Element:UpdateCenterBar()
	self.m_centerBar:SetX(self.m_leftBar:GetRight())
	self.m_centerBar:SetWidth(self:GetWidth() - (self.m_leftBar:GetWidth() + self.m_rightBar:GetWidth()))
	self.m_centerBar:SetHeight(self:GetHeight())
	self.m_rightBar:SetX(self.m_centerBar:GetRight())
	self.m_leftBar:SetHeight(self:GetHeight())
	self.m_rightBar:SetHeight(self:GetHeight())
end
gui.register("WIPFMPartialTimeSelection", Element)

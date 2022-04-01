--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/timelinestrip.lua")
include("/gui/playhead.lua")
include("/gui/vbox.lua")
include("/gui/collapsiblegroup.lua")
include("/gui/pfm/bookmark.lua")
include("/gui/pfm/axis.lua")

util.register_class("gui.Timeline",gui.Base)
function gui.Timeline:__init()
	gui.Base.__init(self)
end
function gui.Timeline:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,64)
	local onTimelineMouseEvent = function(el,mouseButton,keyState,mods)
		if(util.is_valid(self.m_playhead) == false) then return util.EVENT_REPLY_UNHANDLED end
		if(mouseButton == input.MOUSE_BUTTON_LEFT) then
			if(keyState == input.STATE_PRESS) then
				local pos = self:GetCursorPos()
				local timeOffset = self:GetTimeAxis():GetAxis():XOffsetToValue(pos.x)
				self.m_playhead:SetTimeOffset(timeOffset)
			end
			self.m_playhead:SetCursorMoveModeEnabled(keyState == input.STATE_PRESS)
		end
		return util.EVENT_REPLY_HANDLED
	end

	self.m_bookmarkBar = gui.create("WIBase",self,0,0,self:GetWidth(),16,0,0,1,0)
	self.m_bookmarks = {}
	self.m_bookmarkSets = {}

	self.m_timelineStripUpper = gui.create("WILabelledTimelineStrip",self,0,self.m_bookmarkBar:GetBottom(),self:GetWidth(),16,0,0,1,0)
	self.m_timelineStripUpper:SetMouseInputEnabled(true)
	self.m_timelineStripUpper:SetHorizontal(true)
	self.m_timelineStripUpper:SetFlipped(false)
	self.m_timelineStripUpper:AddCallback("OnMouseEvent",onTimelineMouseEvent)

	self.m_timelineStripLower = gui.create("WILabelledTimelineStrip",self,0,self:GetBottom() -16,self:GetWidth(),16,0,1,1,1)
	self.m_timelineStripLower:SetMouseInputEnabled(true)
	self.m_timelineStripLower:SetHorizontal(true)
	self.m_timelineStripLower:SetFlipped(true)
	self.m_timelineStripLower:AddCallback("OnMouseEvent",onTimelineMouseEvent)

	self.m_contents = gui.create("WIBase",self,
		0,self.m_timelineStripUpper:GetBottom(),
		self:GetWidth(),self.m_timelineStripLower:GetTop() -self.m_timelineStripUpper:GetBottom(),
		0,0,1,1
	)

	self.m_playhead = gui.create("WIPlayhead",self,0,self.m_bookmarkBar:GetBottom())
	self.m_playhead:SetHeight(self:GetHeight())
	self.m_playhead:GetTimeOffsetProperty():AddCallback(function()
		self:OnTimelinePropertiesChanged(true,true)
	end)

	self.m_timeAxis = gui.create("WIAxis",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_dataAxis = gui.create("WIAxis",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)

	self:SetTimeAxis(util.GraphAxis())
	self:SetDataAxis(util.GraphAxis())

	self:SetScrollInputEnabled(true)
	self:SetZoomLevel(1)
	self:SetStartOffset(0.0)
	self:Update()

	-- TODO
	self:SetMouseInputEnabled(true)
end
function gui.Timeline:OnRemove()
	if(util.is_valid(self.m_cbTimeAxisPropertiesChanged)) then self.m_cbTimeAxisPropertiesChanged:Remove() end
end
function gui.Timeline:SetTimeAxis(axis)
	self.m_timeAxis:SetAxis(axis,true)
	if(util.is_valid(self.m_timelineStripLower)) then self.m_timelineStripLower:SetAxis(axis) end
	if(util.is_valid(self.m_timelineStripUpper)) then self.m_timelineStripUpper:SetAxis(axis) end
	if(util.is_valid(self.m_playhead)) then self.m_playhead:SetAxis(axis) end

	if(util.is_valid(self.m_cbTimeAxisPropertiesChanged)) then self.m_cbTimeAxisPropertiesChanged:Remove() end
	self.m_cbTimeAxisPropertiesChanged = axis:AddCallback("OnPropertiesChanged",function()
		self:OnTimelinePropertiesChanged(true,false)
	end)
end
function gui.Timeline:SetDataAxis(axis) self.m_dataAxis:SetAxis(axis,false) end
function gui.Timeline:GetTimeAxis() return self.m_timeAxis end
function gui.Timeline:GetDataAxis() return self.m_dataAxis end
function gui.Timeline:AddTimelineItem(el,timeFrame)
	self.m_timeAxis:AttachElementToRange(el,timeFrame)
end
function gui.Timeline:MouseCallback(mouseButton,state,mods)
	--[[if(mouseButton == input.MOUSE_BUTTON_LEFT) then
		self:SetCursorMoveModeEnabled(state == input.STATE_PRESS)
		return util.EVENT_REPLY_HANDLED
	end]]
	return util.EVENT_REPLY_UNHANDLED
end
function gui.Timeline:SetCursorMoveModeEnabled(enabled)
	if(enabled) then
		self:SetCursorMovementCheckEnabled(true)
		if(util.is_valid(self.m_cbMove) == false) then
			local axis = self:GetTimeAxis():GetAxis()
			local dataAxis = self:GetDataAxis():GetAxis()
			local startPos = self:GetCursorPos()
			local offset = axis:GetStartOffset()
			local dataOffset = dataAxis:GetStartOffset()
			self.m_cbMove = self:AddCallback("OnCursorMoved",function(el,x,y)
				x = x -startPos.x
				y = y -startPos.y

				x = axis:XDeltaToValue(x)
				y = dataAxis:XDeltaToValue(y)
				axis:SetStartOffset(offset -x)
				dataAxis:SetStartOffset(dataOffset -y)
				self:Update()
				--local pos = self:GetParent():GetCursorPos()
				--self:SetTimeOffset(self.m_timeline:XOffsetToValue(pos.x))

				--self.m_timelineGraph
			end)
		end
	else
		self:SetCursorMovementCheckEnabled(false)
		if(util.is_valid(self.m_cbMove)) then self.m_cbMove:Remove() end
	end
end
function gui.Timeline:GetContents() return self.m_contents end
function gui.Timeline:GetPlayhead() return self.m_playhead end
function gui.Timeline:GetUpperTimelineStrip() return self.m_timelineStripUpper end
function gui.Timeline:GetLowerTimelineStrip() return self.m_timelineStripLower end
function gui.Timeline:GetEndOffset() return self:GetTimeAxis():GetAxis():XOffsetToValue(self:GetRight()) end
function gui.Timeline:OnTimelinePropertiesChanged(updatePlayhead,updateAxis)
	if(self.m_skipPlayheadUpdate) then return end
	if(util.is_valid(self.m_playhead)) then
		if(self.m_skipUpdatePlayOffset ~= true) then
			self.m_skipUpdatePlayOffset = true
			local timeOffset = self.m_playhead:GetTimeOffset()
			local axis = self:GetTimeAxis():GetAxis()
			local x = axis:ValueToXOffset(timeOffset)
			if(updatePlayhead) then self.m_playhead:SetPlayOffset(x) end
			self.m_skipUpdatePlayOffset = nil

			if(timeOffset < axis:GetStartOffset()) then
				if(updateAxis) then axis:SetStartOffset(timeOffset) end
				self:Update()
			elseif(timeOffset > self:GetEndOffset()) then
				if(updateAxis) then axis:SetStartOffset(axis:GetStartOffset() +(timeOffset -self:GetEndOffset())) end
				self:Update()
			end
		end
	end
end
function gui.Timeline:ScrollCallback(x,y)
	self:SetZoomLevel(self:GetTimeAxis():GetAxis():GetZoomLevel() -(y /20.0))
	self:Update()
	return util.EVENT_REPLY_HANDLED
end
function gui.Timeline:OnSizeChanged(w,h)
	if(util.is_valid(self.m_playhead)) then self.m_playhead:SetHeight(h -self.m_bookmarkBar:GetBottom()) end
end
function gui.Timeline:RemoveBookmarkSet(bms)
	for i,d in ipairs(self.m_bookmarkSets) do
		if(util.is_same_object(d.bookmarkSet,bms)) then
			util.remove(d.elements)
			util.remove(d.listener)
			table.remove(self.m_bookmarkSets,i)
			break
		end
	end
end
function gui.Timeline:AddBookmarkSet(bms)
	for _,d in ipairs(self.m_bookmarkSets) do
		if(util.is_same_object(d.bookmarkSet,bms)) then
			return -- Bookmark set was already added
		end
	end
	local t = {
		elements = {},
		bookmarkSet = bms
	}
	table.insert(self.m_bookmarkSets,t)
	local listener = bms:AddChangeListener("bookmarks",function(c,i,ev,oldVal)
		if(ev == udm.BaseSchemaType.ARRAY_EVENT_ADD) then
			local el = self:AddBookmark(c:GetBookmark(i))
			table.insert(t.elements,el)
		elseif(ev == udm.BaseSchemaType.ARRAY_EVENT_REMOVE) then
			local i = 1
			while(i <= #self.m_bookmarks) do
				local bmOther = self.m_bookmarks[i]
				if(bmOther:IsValid() and util.is_same_object(bmOther.m_bookmark,oldVal)) then
					bmOther:Remove()
				end

				if(bmOther:IsValid() == false) then table.remove(self.m_bookmarks,i)
				else i = i +1 end
			end
		end
	end)
	t.listener = listener

	for _,bm in ipairs(bms:GetBookmarks()) do
		local el = self:AddBookmark(bm)
		table.insert(t.elements,el)
	end
end
function gui.Timeline:AddBookmark(bm)
	if(util.is_valid(self.m_timelineStripUpper) == false) then return end
	local p = gui.create("WIPFMBookmark",self,0,5)
	p.m_bookmark = bm
	self.m_timeAxis:AttachElementToValueWithUdmProperty(p,bm,"time")
	table.insert(self.m_bookmarks,p)
	return p
end
function gui.Timeline:ClearBookmarks()
	util.remove(self.m_bookmarks)
	for _,d in ipairs(self.m_bookmarkSets) do
		util.remove(d.elements)
		util.remove(d.listener)
	end

	self.m_bookmarks = {}
	self.m_bookmarkSets = {}
end
function gui.Timeline:SetZoomLevel(zoomLevel)
	-- TODO: Use SetZoomLevel from GraphAxis class
	if(util.is_valid(self.m_timelineStripUpper) == false) then return end
	local xOffsetPlayhead
	local timeOffset
	local axis = self:GetTimeAxis():GetAxis()
	if(util.is_valid(self.m_playhead)) then
		xOffsetPlayhead = axis:ValueToXOffset2(self.m_playhead:GetTimeOffset())
		timeOffset = self.m_playhead:GetTimeOffset()
	end
	axis:SetZoomLevel(zoomLevel)

	if(util.is_valid(self.m_playhead)) then
		-- We want the playhead to stay in place, so we have to change the start offset accordingly
		local newXOffsetPlayhead = axis:ValueToXOffset2(self.m_playhead:GetTimeOffset())
		local startOffset = axis:GetStartOffset() -axis:XDeltaToValue(xOffsetPlayhead -newXOffsetPlayhead)
		--local startOffset = timeOffset -axis:XDeltaToValue(axis:ValueToXOffset(timeOffset) -xOffsetPlayhead)
		axis:SetStartOffset(startOffset)--startOffset)

		-- Changing the start offset can change the playhead offset if it's out of range,
		-- so we'll reset its position here.
		self.m_skipPlayheadUpdate = true
		self.m_playhead:SetTimeOffset(timeOffset)
		self.m_skipPlayheadUpdate = nil

		self.m_playhead:SetPlayOffset(axis:ValueToXOffset(timeOffset))
	end
end
function gui.Timeline:SetStartOffset(offset)
	local axis = self:GetTimeAxis():GetAxis()
	if(util.is_valid(self.m_playhead)) then
		local startOffset = offset
		local endOffset = startOffset +(self:GetEndOffset() -axis:GetStartOffset())
		local playheadOffset = math.clamp(self.m_playhead:GetTimeOffset(),startOffset,endOffset)
		if(playheadOffset ~= self.m_playhead:GetTimeOffset()) then
			self.m_playhead:SetTimeOffset(playheadOffset)
		end
	end
	axis:SetStartOffset(offset)
end
function gui.Timeline:GetStartOffset() return self:GetTimeAxis():GetAxis():GetStartOffset() end
function gui.Timeline:OnUpdate()
	if(util.is_valid(self.m_timelineStripUpper)) then self.m_timelineStripUpper:Update() end
	if(util.is_valid(self.m_timelineStripLower)) then self.m_timelineStripLower:Update() end
	self:CallCallbacks("OnTimelineUpdate")
end
gui.register("WITimeline",gui.Timeline)

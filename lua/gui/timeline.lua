--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/timelinestrip.lua")
include("/gui/playhead.lua")
include("/gui/vbox.lua")
include("/gui/collapsiblegroup.lua")

util.register_class("gui.Timeline",gui.Base)
function gui.Timeline:__init()
	gui.Base.__init(self)
end
function gui.Timeline:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,64)
	self.m_timelineStripUpper = gui.create("WILabelledTimelineStrip",self,0,0,self:GetWidth(),16,0,0,1,0)

	self.m_timelineStripLower = gui.create("WILabelledTimelineStrip",self,0,self:GetBottom() -16,self:GetWidth(),16,0,1,1,1)
	self.m_timelineStripLower:SetFlipped(true)
	self.m_contentsScroll = gui.create("WIScrollContainer",self,
		0,self.m_timelineStripUpper:GetBottom(),
		self:GetWidth(),self.m_timelineStripLower:GetTop() -self.m_timelineStripUpper:GetBottom(),
		0,0,1,1
	)
	self.m_contents = gui.create("WIVBox",self.m_contentsScroll,0,0,self:GetWidth(),0)
	self.m_playhead = gui.create("WIPlayhead",self)
	self.m_playhead:SetHeight(self:GetHeight())
	self.m_playhead:GetTimeOffsetProperty():AddCallback(function()
		self:OnTimelinePropertiesChanged()
	end)
	self.m_playhead:LinkToTimeline(self)

	self.m_timelineStripLower:GetStartOffsetProperty():Link(self.m_timelineStripUpper:GetStartOffsetProperty())
	self.m_timelineStripLower:GetZoomLevelProperty():Link(self.m_timelineStripUpper:GetZoomLevelProperty())

	self.m_timelineStripUpper:AddCallback("OnTimelinePropertiesChanged",function()
		self:OnTimelinePropertiesChanged()
	end)

	self:SetScrollInputEnabled(true)
	self:SetZoomLevel(1)
	self:SetStartOffset(0.0)
	self:Update()
end
function gui.Timeline:GetPlayhead() return self.m_playhead end
function gui.Timeline:GetUpperTimelineStrip() return self.m_timelineStripUpper end
function gui.Timeline:GetLowerTimelineStrip() return self.m_timelineStripLower end
function gui.Timeline:OnTimelinePropertiesChanged()
	if(self.m_skipPlayheadUpdate) then return end
	if(util.is_valid(self.m_playhead)) then
		if(self.m_skipUpdatePlayOffset ~= true) then
			self.m_skipUpdatePlayOffset = true
			local timeOffset = self.m_playhead:GetTimeOffset()
			local x = self:TimeOffsetToXOffset(timeOffset)
			self.m_playhead:SetPlayOffset(x)
			self.m_skipUpdatePlayOffset = nil

			if(timeOffset < self:GetStartOffset()) then
				self:SetStartOffset(timeOffset)
				self:Update()
			elseif(timeOffset > self:GetEndOffset()) then
				self:SetStartOffset(self:GetStartOffset() +(timeOffset -self:GetEndOffset()))
				self:Update()
			end
		end
	end
end
function gui.Timeline:ScrollCallback(x,y)
	self:SetZoomLevel(self:GetZoomLevel() -(y /20.0))
	self:Update()
	return util.EVENT_REPLY_HANDLED
end
function gui.Timeline:OnSizeChanged(w,h)
	if(util.is_valid(self.m_playhead)) then self.m_playhead:SetHeight(h) end
	if(util.is_valid(self.m_contents)) then self.m_contents:SetWidth(w) end
end
function gui.Timeline:AddTimelineItem(el,timeFrame)
	if(util.is_valid(self.m_contents) == false) then return end
	local elWrapper = el:Wrap("WITimelineItem")
	if(elWrapper == nil) then return end
	elWrapper:LinkToTimeline(self,timeFrame)
	return elWrapper
end
function gui.Timeline:AddTrackGroup(groupName)
	if(util.is_valid(self.m_contents) == false) then return end
	local p = gui.create("WICollapsibleGroup",self.m_contents)
	p:SetWidth(self.m_contents:GetWidth())
	p:SetAnchor(0,0,1,0)
	p:SetGroupName(groupName)
	return p
end
function gui.Timeline:SetZoomLevel(zoomLevel)
	if(util.is_valid(self.m_timelineStripUpper) == false) then return end
	local xOffsetPlayhead
	local timeOffset
	if(util.is_valid(self.m_playhead)) then
		xOffsetPlayhead = self:TimeOffsetToXOffset(self.m_playhead:GetTimeOffset())
		timeOffset = self.m_playhead:GetTimeOffset()
	end
	self.m_timelineStripUpper:SetZoomLevel(zoomLevel)

	if(util.is_valid(self.m_playhead)) then
		-- We want the playhead to stay in place, so we have to change the start offset accordingly
		local startOffset = timeOffset -xOffsetPlayhead /self:GetStridePerUnit() *self:GetZoomLevelMultiplier()
		self:SetStartOffset(startOffset)

		-- Changing the start offset can change the playhead offset if it's out of range,
		-- so we'll reset its position here.
		self.m_skipPlayheadUpdate = true
		self.m_playhead:SetTimeOffset(timeOffset)
		self.m_skipPlayheadUpdate = nil

		self.m_playhead:SetPlayOffset(self:TimeOffsetToXOffset(timeOffset))
	end
end
function gui.Timeline:GetZoomLevel()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return 1 end
	return self.m_timelineStripUpper:GetZoomLevel()
end
function gui.Timeline:GetZoomLevelProperty()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return end
	return self.m_timelineStripUpper:GetZoomLevelProperty()
end
function gui.Timeline:GetZoomLevelMultiplier()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return 1.0 end
	return self.m_timelineStripUpper:GetZoomLevelMultiplier()
end
function gui.Timeline:SetStartOffset(offset)
	if(util.is_valid(self.m_playhead)) then
		local startOffset = offset
		local endOffset = startOffset +(self:GetEndOffset() -self:GetStartOffset())
		local playheadOffset = math.clamp(self.m_playhead:GetTimeOffset(),startOffset,endOffset)
		if(playheadOffset ~= self.m_playhead:GetTimeOffset()) then
			self.m_playhead:SetTimeOffset(playheadOffset)
		end
	end
	if(util.is_valid(self.m_timelineStripUpper)) then
		self.m_timelineStripUpper:SetStartOffset(offset)
	end
end
function gui.Timeline:GetStartOffset()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return 0.0 end
	return self.m_timelineStripUpper:GetStartOffset()
end
function gui.Timeline:GetStartOffsetProperty()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return end
	return self.m_timelineStripUpper:GetStartOffsetProperty()
end
function gui.Timeline:GetEndOffset()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return 0.0 end
	return self.m_timelineStripUpper:XOffsetToTimeOffset(self:GetRight())
end
function gui.Timeline:GetStridePerUnit()
	if(util.is_valid(self.m_timelineStripUpper) == false) then return 0.0 end
	return self.m_timelineStripUpper:GetStridePerUnit()
end
function gui.Timeline:TimeOffsetToXOffset(timeInSeconds)
	timeInSeconds = timeInSeconds -self:GetStartOffset()
	return (timeInSeconds /self:GetZoomLevelMultiplier()) *self:GetStridePerUnit()
end
function gui.Timeline:XOffsetToTimeOffset(x)
	x = x /self:GetStridePerUnit() *self:GetZoomLevelMultiplier()
	return x +self:GetStartOffset()
end
function gui.Timeline:Update()
	if(util.is_valid(self.m_timelineStripUpper)) then self.m_timelineStripUpper:Update() end
	if(util.is_valid(self.m_timelineStripLower)) then self.m_timelineStripLower:Update() end
	self:CallCallbacks("OnTimelineUpdate")
end
gui.register("WITimeline",gui.Timeline)

-------------

util.register_class("gui.TimelineItem",gui.Base)
function gui.TimelineItem:__init()
	gui.Base.__init(self)
end
function gui.TimelineItem:OnRemove()
	self:UnlinkFromTimeline()
end
function gui.TimelineItem:LinkToTimeline(timeline,timeFrame)
	self:UnlinkFromTimeline()
	self.m_timeline = timeline
	self.m_timeFrame = timeFrame
	self.m_cbUpdate = timeline:AddCallback("OnTimelineUpdate",function()
		self:Update()
	end)
	self:Update()
end
function gui.TimelineItem:UnlinkFromTimeline()
	self.m_timeline = nil
	self.m_timeFrame = nil
	if(util.is_valid(self.m_cbUpdate)) then self.m_cbUpdate:Remove() end
end
function gui.TimelineItem:Update()
	if(util.is_valid(self.m_timeline) == false) then return end
	local startOffset = self.m_timeFrame:GetStart()
	local endOffset = self.m_timeFrame:GetEnd()
	local xStart = self.m_timeline:TimeOffsetToXOffset(startOffset)
	local xEnd = self.m_timeline:TimeOffsetToXOffset(endOffset)
	local w = xEnd -xStart

	xStart = self.m_timeline:GetAbsolutePos().x +xStart
	local pos = self:GetAbsolutePos()
	pos.x = xStart
	self:SetAbsolutePos(pos)
	self:SetWidth(w)
end
gui.register("WITimelineItem",gui.TimelineItem)

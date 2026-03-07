-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("film_clip.lua")
include("sequence_film_strip.lua")
include("/gui/drag_handle.lua")

local FilmStrip = util.register_class("gui.FilmStrip", gui.Base)
function FilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)

	self:InitializeDragHandle()

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")
	self.m_container = gui.create("WIContainer", self)
	self:GetSizeProperty():Link(self.m_container:GetSizeProperty())
	self.m_filmClips = {}
	self.m_listeners = {}

	self:InitializeSequenceFilmStrip()
end
function FilmStrip:OnRemove() util.remove(self.m_listeners) end
function FilmStrip:InitializeDragHandle()
	local dragHandle = gui.create("drag_handle", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	local initialStartOffset
	dragHandle:AddCallback("OnDragStart", function(dragHandle)
		local timeLine = self:GetTimeline()
		initialStartOffset = timeLine:GetStartOffset()
	end)
	dragHandle:AddCallback("OnDrag", function(dragHandle, xdelta, ydelta, x, y)
		local timeLine = self:GetTimeline()
		local axisTime = timeLine:GetTimeAxis():GetAxis()
		timeLine:SetStartOffset(initialStartOffset -axisTime:XDeltaToValue(xdelta))
		timeLine:Update()
	end)
end
function FilmStrip:AddFilmClip(filmClip)
	local elClip = gui.create("film_clip", self.m_container)
	elClip:SetY(self.m_seqFilmStrip:GetHeight() /2 -elClip:GetHeight() /2)
	table.insert(self.m_filmClips, elClip)

	elClip:SetClipData(filmClip)
	elClip:SetFilmStrip(self)
	self:ScheduleUpdate()

	local timeFrame = filmClip:GetTimeFrame()
	table.insert(self.m_listeners, timeFrame:AddChangeListener("start", function() self:ScheduleUpdate() end))
	table.insert(self.m_listeners, timeFrame:AddChangeListener("offset", function() self:ScheduleUpdate() end))
	table.insert(self.m_listeners, timeFrame:AddChangeListener("duration", function() self:ScheduleUpdate() end))

	return elClip
end
function FilmStrip:UpdateFilmClipUi()
	local filmClips = {}
	for _,elFilmClip in ipairs(self.m_filmClips) do
		if(elFilmClip:IsValid()) then
			table.insert(filmClips, elFilmClip)
		end
	end
	table.sort(filmClips, function(a, b)
		return a:GetClipData():GetTimeFrame():GetStart() < b:GetClipData():GetTimeFrame():GetStart()
	end)

	local halfFrameDur = self.m_session:GetFrameDuration() /2.0
	for i=1,#filmClips do
		local filmClip = filmClips[i]
		local filmClipNext = filmClips[i +1]
		local neighbored = false
		if(filmClipNext ~= nil) then
			local timeFrame = filmClip:GetClipData():GetTimeFrame()
			local timeFrameNext = filmClipNext:GetClipData():GetTimeFrame()
			if(math.abs(timeFrameNext:GetStart() -timeFrame:GetEnd()) < halfFrameDur) then
				neighbored = true
			end
		end

		filmClip:SetNextNeighbor(neighbored and filmClipNext or nil)
		if(filmClipNext ~= nil) then
			filmClipNext:SetPreviousNeighbor(neighbored and filmClip or nil)
		end
	end
end
function FilmStrip:InitializeSequenceFilmStrip()
	local seqFilmStrip = gui.create("sequence_film_strip", self.m_container)
	seqFilmStrip:SetZPos(-5)
	seqFilmStrip:GetTimeFrame():SetStart(-2)
	seqFilmStrip:GetTimeFrame():SetDuration(40)
	self.m_seqFilmStrip = seqFilmStrip
end
function FilmStrip:Setup(session, timeline)
	local seqFilmStrip = self.m_seqFilmStrip
	seqFilmStrip:SetTimeFrame(session:GetTimeFrame())
	timeline:AddTimelineItem(seqFilmStrip, seqFilmStrip:GetTimeFrame(), seqFilmStrip:GetLeftMargin(), seqFilmStrip:GetRightMargin())
	self.m_timeline = timeline
	self.m_session = session
	
	seqFilmStrip:SetFilmStrip(self)
end
function FilmStrip:GetTimeline() return self.m_timeline end
function FilmStrip:GetSession() return self.m_session end
function FilmStrip:GetSequenceFilmStrip() return self.m_seqFilmStrip end
function FilmStrip:GetTimeFrame()
	return self.m_timeFrame
end
function FilmStrip:GetFilmClips()
	return self.m_filmClips
end
function FilmStrip:FindFilmClipElement(fc)
	for _, el in ipairs(self.m_filmClips) do
		if el:IsValid() then
			local filmClipData = el:GetClipData()
			if util.is_same_object(filmClipData, fc) then
				return el
			end
		end
	end
end
function FilmStrip:OnUpdate()
	local timeFrame
	-- Calculate total time frame
	for _, el in ipairs(self.m_filmClips) do
		if el:IsValid() then
			local filmClipData = el:GetClipData()
			local timeFrameClip = filmClipData:GetTimeFrame()
			if timeFrame == nil then
				timeFrame = timeFrameClip:Copy()
			else
				timeFrame = timeFrame:Max(timeFrameClip)
			end
		end
	end
	self.m_timeFrame = timeFrame or udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")
	self:UpdateFilmClipUi()
end
gui.register("film_strip", FilmStrip)

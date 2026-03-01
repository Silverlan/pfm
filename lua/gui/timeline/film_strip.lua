-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("film_clip.lua")
include("sequence_film_strip.lua")

local FilmStrip = util.register_class("gui.FilmStrip", gui.Base)
function FilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")
	self.m_container = gui.create("WIContainer", self)
	self:GetSizeProperty():Link(self.m_container:GetSizeProperty())
	self.m_filmClips = {}

	self:InitializeSequenceFilmStrip()
end
function FilmStrip:AddFilmClip(filmClip)
	local elClip = gui.create("film_clip", self.m_container)
	elClip:SetY(self.m_seqFilmStrip:GetHeight() /2 -elClip:GetHeight() /2)
	table.insert(self.m_filmClips, elClip)

	elClip:SetClipData(filmClip)
	self:ScheduleUpdate()
	return elClip
end
function FilmStrip:InitializeSequenceFilmStrip()
	local seqFilmStrip = gui.create("sequence_film_strip", self.m_container)
	seqFilmStrip:SetFilmStrip(self)
	seqFilmStrip:SetZPos(-5)
	seqFilmStrip:GetTimeFrame():SetStart(-2)
	seqFilmStrip:GetTimeFrame():SetDuration(40)
	self.m_seqFilmStrip = seqFilmStrip
end
function FilmStrip:Setup(session, timeline)
	self.m_seqFilmStrip:SetTimeFrame(session:GetTimeFrame())
	timeline:AddTimelineItem(self.m_seqFilmStrip, self.m_seqFilmStrip:GetTimeFrame())
	self.m_timeline = timeline
end
function FilmStrip:GetTimeline() return self.m_timeline end
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
end
gui.register("film_strip", FilmStrip)

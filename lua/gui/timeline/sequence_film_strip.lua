-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/drag_handle.lua")
include("/gui/pfm/repeated_textured_rect.lua")

local SequenceFilmStrip = util.register_class("gui.SequenceFilmStrip", gui.Base)
function SequenceFilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")

	self:SetSize(128, 93)

	local elBg = gui.create("WI9SliceRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elBg:SetColor(Color(62, 62, 107))
	elBg:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_background")

	local elBgPattern = gui.create("pfm_repeated_textured_rect", elBg)
	elBgPattern:SetColor(Color(46, 46, 54, 255))
	elBgPattern:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_pattern")
	elBg:AddCallback("SetSize", function(p)
		local offset = 11
		local wPatternDot = 4
		elBgPattern:SetX(offset)

		local w = elBg:GetWidth() -offset *2
		w = w -math.floor(w %wPatternDot)
		elBgPattern:SetWidth(w)
		elBgPattern:SetHeight(elBg:GetHeight())
	end)

	local leftDragHandle = self:CreateDragHandle(true, 0, 0, 12, self:GetHeight(), 0, 0, 0, 0)
	local rightDragHandle = self:CreateDragHandle(false, self:GetRight() -12, 0, 12, self:GetHeight(), 1, 0, 1, 0)
	self.m_leftDragHandle = leftDragHandle
	self.m_rightDragHandle = rightDragHandle

	local blackBar = gui.create("WIRect", self, 12, self:GetHeight() /2.0 -(27 /2.0), self:GetWidth() -(12 +12), 27, 0, 0, 1, 1)
	blackBar:SetColor(Color.Black)

	local sessionName = gui.create("WIText", self)
	sessionName:SetColor(Color.Black)
	sessionName:SetText("session")
	sessionName:SetFont("pfm_small")
	sessionName:SizeToContents()
	sessionName:SetPos(blackBar:GetX() +2, 13)
end
function SequenceFilmStrip:CreateDragHandle(startHandle, x, y, w, h, ax, ay, aw, ah)
	local dragHandle = gui.create("drag_handle", self, x, y, w, h, ax, ay, aw, ah)
	dragHandle:AddCallback("OnDrag", function(dragHandle, xdelta, ydelta, x, y)
		if(util.is_valid(self.m_filmStrip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		if(util.is_valid(timeLine) == false) then return end
		if(startHandle == false) then
			x = x +dragHandle:GetWidth()
		end
		local axisTime = timeLine:GetTimeAxis():GetAxis()
		local time = axisTime:XOffsetToValue(x)
		local timeFrame = self:GetTimeFrame()
		if(startHandle) then
			local endTime = timeFrame:GetEnd()
			timeFrame:SetStart(time)
			timeFrame:SetDuration(endTime -time)
		else
			timeFrame:SetDuration(time -timeFrame:GetStart())
		end
	end)
	return dragHandle
end
function SequenceFilmStrip:SetTimeFrame(timeFrame) self.m_timeFrame = timeFrame end
function SequenceFilmStrip:GetTimeFrame() return self.m_timeFrame end
function SequenceFilmStrip:SetFilmStrip(filmStrip)
	self.m_leftDragHandle:SetReferenceElement(filmStrip:GetTimeline())
	self.m_rightDragHandle:SetReferenceElement(filmStrip:GetTimeline())
	self.m_filmStrip = filmStrip
end
gui.register("sequence_film_strip", SequenceFilmStrip)

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
	elBg:AddStyleClass("timeline_film_strip")
	elBg:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_background")
	self.m_elBg = elBg

	local elBgPattern = gui.create("pfm_repeated_textured_rect", elBg)
	elBgPattern:AddStyleClass("timeline_film_strip_dots")
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
	self.m_sessionName = sessionName
end
function SequenceFilmStrip:OnRemove() util.remove(self.m_nameChangeListener) end
function SequenceFilmStrip:GetLeftMargin()
	local w = self.m_elBg:GetSegmentSize(gui.NineSliceRect.SEGMENT_LEFT_EDGE)
	return w
end
function SequenceFilmStrip:GetRightMargin()
	local w = self.m_elBg:GetSegmentSize(gui.NineSliceRect.SEGMENT_RIGHT_EDGE)
	return w
end
function SequenceFilmStrip:CreateDragHandle(startHandle, x, y, w, h, ax, ay, aw, ah)
	local function clamp_to_frame_rate(time, clampToAtLeastOneFrame)
		return self.m_filmStrip:GetSession():ClampTimeOffsetToFrameRate(time, clampToAtLeastOneFrame)
	end

	local dragHandle = gui.create("drag_handle", self, x, y, w, h, ax, ay, aw, ah)
	dragHandle:SetCursor(gui.CURSOR_SHAPE_HRESIZE)
	local initialStartTime
	local initialDuration
	dragHandle:AddCallback("OnDragStart", function(dragHandle)
		local timeFrame = self:GetTimeFrame()
		initialStartTime = timeFrame:GetStart()
		initialDuration = timeFrame:GetDuration()
	end)
	dragHandle:AddCallback("OnDragEnd", function(dragHandle)
		local cmd = pfm.create_command("composition")
		local halfFrameDur = self.m_filmStrip:GetSession():GetFrameDuration()
		local activeClip = self.m_filmStrip:GetSession():GetActiveClip()
		local hasChanges = false
		local timeFrame = self:GetTimeFrame()

		local oldTimeOffset = initialStartTime
		local newTimeOffset = timeFrame:GetStart()
		if(math.abs(newTimeOffset -oldTimeOffset) > halfFrameDur) then
			cmd:AddSubCommand("set_clip_start", activeClip, oldTimeOffset, newTimeOffset)
			hasChanges = true
		end

		local oldDuration = initialDuration
		local newDuration = timeFrame:GetDuration()
		if(math.abs(newDuration -oldDuration) > halfFrameDur) then
			cmd:AddSubCommand("set_clip_duration", activeClip, oldDuration, newDuration)
			hasChanges = true
		end

		initialStartTime = nil
		initialDuration = nil

		if(hasChanges == false) then return end
		pfm.undoredo.push("update_sequence_filmstrip", cmd)()
	end)
	dragHandle:AddCallback("OnDrag", function(dragHandle, xdelta, ydelta, x, y)
		if(util.is_valid(self.m_filmStrip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		if(util.is_valid(timeLine) == false) then return end
		if(startHandle) then
			x = x +self:GetLeftMargin()
		else
			x = x +dragHandle:GetWidth() -self:GetRightMargin()
		end
		local axisTime = timeLine:GetTimeAxis():GetAxis()
		local time = axisTime:XOffsetToValue(x)
		local timeFrame = self:GetTimeFrame()
		if(startHandle) then
			local endTime = timeFrame:GetEnd()
			local newStart = clamp_to_frame_rate(time)
			newStart = math.min(newStart, endTime -self.m_filmStrip:GetSession():GetFrameDuration())
			timeFrame:SetStart(newStart)
			timeFrame:SetOffset(newStart)
			timeFrame:SetDuration(clamp_to_frame_rate(endTime -time, true))
		else
			timeFrame:SetDuration(clamp_to_frame_rate(time -timeFrame:GetStart(), true))
		end
	end)

	local elTex = gui.create("WITexturedRect", dragHandle)
	elTex:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_grab_handle")
	elTex:SetColor(Color(81, 86, 147))
	elTex:SetSize(3, 23)
	elTex:CenterToParent()
	elTex:SetAnchor(0.5, 0.5, 0.5, 0.5)

	return dragHandle
end
function SequenceFilmStrip:SetTimeFrame(timeFrame) self.m_timeFrame = timeFrame end
function SequenceFilmStrip:GetTimeFrame() return self.m_timeFrame end
function SequenceFilmStrip:SetFilmStrip(filmStrip)
	self.m_leftDragHandle:SetReferenceElement(filmStrip:GetTimeline())
	self.m_rightDragHandle:SetReferenceElement(filmStrip:GetTimeline())
	self.m_filmStrip = filmStrip

	local session = filmStrip:GetSession()
	local activeClip = session:GetActiveClip()
	self.m_sessionName:SetText(activeClip:GetName())
	self.m_sessionName:SizeToContents()
	self.m_nameChangeListener = activeClip:AddChangeListener("name", function(activeClip, newName)
		self.m_sessionName:SetText(newName)
		self.m_sessionName:SizeToContents()
	end)
end
gui.register("sequence_film_strip", SequenceFilmStrip)

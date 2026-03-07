-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/ui/fonts.lua")
include("/pfm/util/clip_edit.lua")
include("/gui/base_clip.lua")
include("/gui/drag_handle.lua")
include("playhead.lua")

local FilmClip = util.register_class("gui.FilmClip", gui.BaseClip)
function FilmClip:OnInitialize()
	gui.BaseClip.OnInitialize(self)

	self:SetHeight(45)
	local w = self:GetWidth()
	local h = self:GetHeight()

	self.m_textDetails = gui.create("WIText", self, 4, h - 14, w - 8, 14, 0, 1, 1, 1)
	self.m_textDetails:SetFont("pfm_small")
	self.m_textDetails:SetColor(Color(202, 202, 222))

	local leftDragHandle = self:CreateDragHandle(true, 0, 0, 12, self:GetHeight(), 0, 0, 0, 0)
	local rightDragHandle = self:CreateDragHandle(false, self:GetRight() -12, 0, 12, self:GetHeight(), 1, 0, 1, 0)
	self.m_leftDragHandle = leftDragHandle
	self.m_rightDragHandle = rightDragHandle

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed", function()
		self:SetSelected(not self:IsSelected())
		return util.EVENT_REPLY_HANDLED
	end)

	self:AddStyleClass("timeline_clip_film")
end
function FilmClip:OnRemove()
	util.remove(self.m_onChangeListeners, self.m_reviewPlayhead)
end
function FilmClip:SetFilmStrip(filmStrip)
	local timeLine = filmStrip:GetTimeline()
	self.m_leftDragHandle:SetReferenceElement(timeLine)
	self.m_rightDragHandle:SetReferenceElement(timeLine)
	self.m_filmStrip = filmStrip
end
function FilmClip:GetSession() return self.m_filmStrip:GetSession() end
function FilmClip:CreateDragHandle(startHandle, x, y, w, h, ax, ay, aw, ah)
	local dragHandle = gui.create("drag_handle", self, x, y, w, h, ax, ay, aw, ah)
	dragHandle:SetCursor(gui.CURSOR_SHAPE_HRESIZE)
	
	local clipEditContext
	dragHandle:AddCallback("OnDragStart", function(dragHandle)
		if(util.is_valid(self.m_filmStrip, self.m_filmClip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()

		--[[util.remove(self.m_reviewPlayhead)
		self.m_reviewPlayhead = timeLine:CreatePlayhead()
		self.m_reviewPlayhead:AddStyleClass("timeline_playhead_review")

		local w2 = self.m_reviewPlayhead:GetWidth() /2
		timeLine:AddTimelineItem(self.m_reviewPlayhead, reviewTimeFrame, w2, w2)]]

		local filmClips = {}
		for _, fc in ipairs(self.m_filmStrip:GetFilmClips()) do
			table.insert(filmClips, fc:GetClipData())
		end
		local timeLineTime = util.FloatProperty(timeLine:GetStartOffset())
		timeLineTime:AddCallback(function(oldOffset, newOffset)
			timeLine:SetStartOffset(newOffset)
		end)
		clipEditContext = pfm.ClipEditContext(self:GetSession(), filmClips, timeLineTime)

	end)
	dragHandle:AddCallback("OnDragEnd", function(dragHandle)
		-- util.remove(self.m_reviewPlayhead)

		clipEditContext:PushUndoRedoCommand()
		clipEditContext = nil
	end)
	dragHandle:AddCallback("OnDrag", function(dragHandle, xdelta, ydelta, x, y)
		if(util.is_valid(self.m_filmStrip, self.m_filmClip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		if(util.is_valid(timeLine) == false) then return end

		local axisTime = timeLine:GetTimeAxis():GetAxis()

		local altKeyDown = input.is_alt_key_down()
		local ctrlKeyDown = input.is_ctrl_key_down()
		local shiftKeyDown = input.is_shift_key_down()

		local op
		if(startHandle) then
			if(altKeyDown) then op = "RippleTrimIn"
			elseif(ctrlKeyDown) then op = "RippleSlide"
			elseif(shiftKeyDown) then op = "SlipTrimIn"
			else op = "RippleSlipTrimIn" end
		else
			if(altKeyDown) then op = "RippleSlipTrimOut"
			elseif(ctrlKeyDown) then op = "BackRippleSlide"
			elseif(shiftKeyDown) then op = "TrimOut"
			else op = "RippleTrimOut" end
		end

		clipEditContext:ClearOperations()
		clipEditContext:AddOperation(op)
		clipEditContext:Update(self.m_filmClip, axisTime:XDeltaToValue(xdelta))

		timeLine:Update()
	end)
	return dragHandle
end
function FilmClip:UpdateClipData()
	self:SetClipData(self.m_filmClip)
end
function FilmClip:OnUpdate()
	self:UpdateFilmClipInfo()
end
function FilmClip:UpdateFilmClipInfo()
	local filmClip = self.m_filmClip
	self:SetText(filmClip:GetName())

	local timeFrame = filmClip:GetTimeFrame()
	local offset = timeFrame:GetOffset()
	local duration = timeFrame:GetDuration()
	offset = util.get_pretty_time(offset)
	duration = util.get_pretty_time(duration)
	if self.m_textDetails:IsValid() then
		self.m_textDetails:SetText(
			"scale " .. util.round_string(timeFrame:GetScale(), 2) .. " offset " .. offset .. " duration " .. duration
		)
	end

	local t = "\t\t"
	self:SetTooltip(
		locale.get_text("pfm_film_clip")
			.. ":\n"
			.. filmClip:GetName()
			.. "\n"
			.. locale.get_text("start")
			.. ":"
			.. t
			.. util.get_pretty_time(timeFrame:GetStart())
			.. "\n"
			.. locale.get_text("end")
			.. ":"
			.. t
			.. util.get_pretty_time(timeFrame:GetEnd())
			.. "\n"
			.. locale.get_text("duration")
			.. ":"
			.. util.get_pretty_time(timeFrame:GetDuration())
			.. "\n"
			.. locale.get_text("offset")
			.. ":"
			.. t
			.. util.get_pretty_time(timeFrame:GetOffset())
			.. "\n"
			.. locale.get_text("scale")
			.. ":"
			.. t
			.. timeFrame:GetScale()
	)
end
function FilmClip:SetClipData(filmClip)
	if(filmClip == self.m_filmClip) then return end
	self.m_filmClip = filmClip

	local timeFrame = filmClip:GetTimeFrame()
	local onChange = function() self:ScheduleUpdate() end
	local listeners = {}
	table.insert(listeners, timeFrame:AddChangeListener("start", onChange))
	table.insert(listeners, timeFrame:AddChangeListener("duration", onChange))
	table.insert(listeners, timeFrame:AddChangeListener("offset", onChange))
	table.insert(listeners, timeFrame:AddChangeListener("scale", onChange))
	util.remove(self.m_onChangeListeners)
	self.m_onChangeListeners = listeners

	self:UpdateFilmClipInfo()
end
function FilmClip:GetClipData()
	return self.m_filmClip
end
function FilmClip:GetTimeFrame()
	return self.m_filmClip:GetTimeFrame()
end
gui.register("film_clip", FilmClip)

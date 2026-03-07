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

	local leftDragHandle = self:CreateDragHandle(true, 0, 0, 14, self:GetHeight(), 0, 0, 0, 0)
	local rightDragHandle = self:CreateDragHandle(false, self:GetRight() -14, 0, 14, self:GetHeight(), 1, 0, 1, 0)
	self.m_leftDragHandle = leftDragHandle
	self.m_rightDragHandle = rightDragHandle

	local leftInnerDragHandle = self:CreateInnerDragHandle(true, 0, 0, 6, self:GetHeight(), 0, 0, 0, 0)
	local rightInnerDragHandle = self:CreateInnerDragHandle(false, self:GetRight() -6, 0, 6, self:GetHeight(), 1, 0, 1, 0)
	leftInnerDragHandle:SetVisible(false)
	rightInnerDragHandle:SetVisible(false)
	self.m_leftInnerDragHandle = leftInnerDragHandle
	self.m_rightInnerDragHandle = rightInnerDragHandle

	self:SetMouseInputEnabled(true)

	self:AddStyleClass("timeline_clip_film")
	gui.mark_as_drag_and_drop_target(self, "film_clip")
end
function FilmClip:SwapWithFilmClip(filmClip)
	local thisFilmClip = self:GetClipData()
	if(util.is_same_object(thisFilmClip, filmClip)) then return end -- Nothing to do
	local filmClips = self.m_filmStrip:GetSortedFilmClips()
	local idxThis
	local idxOther
	local origTimeFrames = {}
	for i, fc in ipairs(filmClips) do
		if(util.is_same_object(fc:GetClipData(), self:GetClipData())) then idxThis = i
		elseif(util.is_same_object(fc:GetClipData(), filmClip)) then idxOther = i end
	end
	assert(idxThis ~= nil and idxOther ~= nil)
	
	local function swap_film_clips(idx0, idx1)
		local fc0 = filmClips[idx0]:GetClipData()
		local fc1 = filmClips[idx1]:GetClipData()
		local tf0 = fc0:GetTimeFrame()
		local tf1 = fc1:GetTimeFrame()

		origTimeFrames[fc0] = origTimeFrames[fc0] or tf0:Copy()
		origTimeFrames[fc1] = origTimeFrames[fc1] or tf1:Copy()

		local tf0Cpy = tf0:Copy()
		tf0:SetStart(tf1:GetStart())
		tf0:SetDuration(tf1:GetDuration())
		tf0:SetOffset(tf1:GetOffset())
		
		tf1:SetStart(tf0Cpy:GetStart())
		tf1:SetDuration(tf0Cpy:GetDuration())
		tf1:SetOffset(tf0Cpy:GetOffset())

		local tmpFc0 = filmClips[idx0]
		filmClips[idx0] = filmClips[idx1]
		filmClips[idx1] = tmpFc0
	end

	local cmd = pfm.create_command("composition")
	local function add_film_clip_command(filmClip)
		cmd:AddSubCommand("set_clip_start", filmClip, origTimeFrames[filmClip]:GetStart(), filmClip:GetTimeFrame():GetStart())
		cmd:AddSubCommand("set_clip_duration", filmClip, origTimeFrames[filmClip]:GetDuration(), filmClip:GetTimeFrame():GetDuration())
	end

	if(idxOther > idxThis) then
		for i=idxThis, idxOther -1 do
			swap_film_clips(i, i +1)
			add_film_clip_command(filmClips[i]:GetClipData())
		end
	else
		for i=idxThis, idxOther +1, -1 do
			swap_film_clips(i, i -1)
			add_film_clip_command(filmClips[i]:GetClipData())
		end
	end
	add_film_clip_command(filmClips[idxOther]:GetClipData())
	pfm.undoredo.push("swap_film_clips", cmd)()
end
function FilmClip:MouseCallback(mouseButton, state, mods)
	if mouseButton == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			util.remove(self.m_dragGhost)
			local p = gui.create("drag_ghost")
			self.m_dragGhost = p
			p:SetTargetElement(self, self:GetCursorPos(), "film_clip")
			p:AddCallback("OnDragDropped", function(p, dropElement)
				if(self:IsValid()) then self:SwapWithFilmClip(dropElement:GetClipData()) end
			end)
		else
			if(util.is_valid(self.m_dragGhost) and self.m_dragGhost:IsDragging() == false) then
				self:SetSelected(not self:IsSelected())
			end
			util.remove(self.m_dragGhost)
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function FilmClip:OnRemove()
	util.remove(self.m_onChangeListeners, self.m_reviewPlayhead, self.m_dragGhost)
end
function FilmClip:SetFilmStrip(filmStrip)
	local timeLine = filmStrip:GetTimeline()
	self.m_leftDragHandle:SetReferenceElement(timeLine)
	self.m_rightDragHandle:SetReferenceElement(timeLine)
	
	self.m_leftInnerDragHandle:SetReferenceElement(timeLine)
	self.m_rightInnerDragHandle:SetReferenceElement(timeLine)
	self.m_filmStrip = filmStrip
end
function FilmClip:GetSession() return self.m_filmStrip:GetSession() end
function FilmClip:CreateInnerDragHandle(startHandle, x, y, w, h, ax, ay, aw, ah)
	local dragHandle = gui.create("drag_handle", self, x, y, w, h, ax, ay, aw, ah)
	dragHandle:SetCursor(gui.CURSOR_SHAPE_CROSSHAIR)
	
	local clipEditContext
	dragHandle:AddCallback("OnDragStart", function(dragHandle)
		if(util.is_valid(self.m_filmStrip, self.m_filmClip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()

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

		clipEditContext:ClearOperations()
		clipEditContext:AddOperation("RollSlip", not startHandle)
		clipEditContext:Update(self.m_filmClip, axisTime:XDeltaToValue(xdelta))

		timeLine:Update()
	end)
	return dragHandle
end
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
function FilmClip:SetNextNeighbor(el)
	self.m_nextNeighbor = el

	self.m_rightInnerDragHandle:SetVisible(el ~= nil)
end
function FilmClip:SetPreviousNeighbor(el)
	self.m_previousNeighbor = el

	self.m_leftInnerDragHandle:SetVisible(el ~= nil)
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

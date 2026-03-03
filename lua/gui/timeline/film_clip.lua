-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/ui/fonts.lua")
include("/gui/base_clip.lua")
include("/gui/drag_handle.lua")

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
	util.remove(self.m_onChangeListeners)
end
function FilmClip:SetFilmStrip(filmStrip)
	local timeLine = filmStrip:GetTimeline()
	self.m_leftDragHandle:SetReferenceElement(timeLine)
	self.m_rightDragHandle:SetReferenceElement(timeLine)
	self.m_filmStrip = filmStrip
end
function FilmClip:CreateDragHandle(startHandle, x, y, w, h, ax, ay, aw, ah)
	local dragHandle = gui.create("drag_handle", self, x, y, w, h, ax, ay, aw, ah)
	
	local dragInfo
	dragHandle:AddCallback("OnDragStart", function(dragHandle)
		if(util.is_valid(self.m_filmStrip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		local timeFrame = self.m_filmClip:GetTimeFrame()
		dragInfo = {
			initialTimeLineStartOffset = timeLine:GetStartOffset(),
			initialStart = timeFrame:GetStart(),
			initialDuration = timeFrame:GetDuration(),
			initialOffset = timeFrame:GetOffset(),

			updateStart = false,
			updateDuration = false,
			updateOffset = false
		}
	end)
	dragHandle:AddCallback("OnDragEnd", function(dragHandle)
		if(dragInfo.updateStart or dragInfo.updateDuration or dragInfo.updateOffset) then
			local timeFrame = self.m_filmClip:GetTimeFrame()

			local clip = self.m_filmClip
			local cmd = pfm.create_command("composition")
			if(dragInfo.updateStart) then
				cmd:AddSubCommand("set_clip_start", clip, dragInfo.initialStart, timeFrame:GetStart())
			end
			if(dragInfo.updateDuration) then
				cmd:AddSubCommand("set_clip_duration", clip, dragInfo.initialDuration, timeFrame:GetDuration())
			end
			if(dragInfo.updateOffset) then
				cmd:AddSubCommand("set_clip_offset", clip, dragInfo.initialOffset, timeFrame:GetOffset())
			end
			pfm.undoredo.push("update_clip", cmd)()
		end

		dragInfo = nil
	end)
	dragHandle:AddCallback("OnDrag", function(dragHandle, xdelta, ydelta, x, y)
		if(util.is_valid(self.m_filmStrip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		if(util.is_valid(timeLine) == false) then return end

		local axisTime = timeLine:GetTimeAxis():GetAxis()
		local altKeyDown = input.is_alt_key_down()
		local ctrlKeyDown = input.is_ctrl_key_down()
		local shiftKeyDown = input.is_shift_key_down()

		local start = dragInfo.initialStart
		local duration = dragInfo.initialDuration
		local offset = dragInfo.initialOffset
		dragInfo.updateStart = false
		dragInfo.updateDuration = false
		dragInfo.updateOffset = false
		local function set_start(v)
			dragInfo.updateStart = true
			start = v
		end
		local function set_duration(v)
			dragInfo.updateDuration = true
			duration = v
		end
		local function set_offset(v)
			dragInfo.updateOffset = true
			offset = v
		end

		if(ctrlKeyDown) then
			set_start(dragInfo.initialStart +axisTime:XDeltaToValue(xdelta))
		else
			if(startHandle) then
				if not altKeyDown then
					set_offset(dragInfo.initialOffset +axisTime:XDeltaToValue(xdelta))
				end
				set_duration(dragInfo.initialDuration -axisTime:XDeltaToValue(xdelta))

				if shiftKeyDown then
					set_start(dragInfo.initialStart +axisTime:XDeltaToValue(xdelta))
				else
					timeLine:SetStartOffset(dragInfo.initialTimeLineStartOffset -axisTime:XDeltaToValue(xdelta))
				end
			else
				if altKeyDown then
					set_offset(dragInfo.initialOffset -axisTime:XDeltaToValue(xdelta))
				end
				set_duration(dragInfo.initialDuration +axisTime:XDeltaToValue(xdelta))
			end
		end

		local timeFrame = self.m_filmClip:GetTimeFrame()
		timeFrame:SetStart(start)
		timeFrame:SetDuration(duration)
		timeFrame:SetOffset(offset)

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

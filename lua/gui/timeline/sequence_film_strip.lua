-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/drag_handle.lua")
include("/gui/pfm/repeated_textured_rect.lua")

local SequenceFilmStrip = util.register_class("gui.SequenceFilmStrip", gui.Base)
function SequenceFilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")

	self:SetSize(128, 93)

	local contents = gui.create_hbox(self)
		:AddStyleClass("sequence-filmstrip__content-area")
	self.m_contents = contents

	local leftDragHandle = self:CreateDragHandle(true)
		:AddStyleClass("sequence-filmstrip__drag-handle")
	local innerContents = gui.create("WIBase", self.m_contents)
		:AddStyleClass("sequence-filmstrip__contents")
	local rightDragHandle = self:CreateDragHandle(false)
		:AddStyleClass("sequence-filmstrip__drag-handle")
	self.m_leftDragHandle = leftDragHandle
	self.m_rightDragHandle = rightDragHandle

	local vertContents = gui.create_vbox(innerContents)
		:AddStyleClass("sequence-filmstrip__contents-vbox")
	local upper = gui.create_vbox(vertContents)
		:AddStyleClass("sequence-filmstrip__row")
		:AddStyleClass("sequence-filmstrip__row--top")
	self.m_upper = upper

	local upperPerforations = gui.create("pfm_repeated_textured_rect", upper)
		:AddStyleClass("sequence-filmstrip__perforations")
	upperPerforations:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_pattern")
	self.m_upperPerforations = upperPerforations

	local blackBar = gui.create("WIBase", vertContents)
		:AddStyleClass("sequence-filmstrip__background-bar")
	local lower = gui.create_vbox(vertContents)
		:AddStyleClass("sequence-filmstrip__row")
		:AddStyleClass("sequence-filmstrip__row--bottom")

	local lowerPerforations = gui.create("pfm_repeated_textured_rect", lower)
		:AddStyleClass("sequence-filmstrip__perforations")
	lowerPerforations:SetMaterial("gui/pfm/editors/clip_editor/sequence_filmstrip_pattern")
	self.m_lowerPerforations = lowerPerforations

	local sessionName = gui.create("WIText", upper)
	sessionName:SetText("session")
	self.m_sessionName = sessionName

	self:AddStyleClass("sequence-filmstrip")
end
function SequenceFilmStrip:OnSizeChanged(w, h)
	if(util.is_valid(self.m_upperPerforations) == false) then return end
	local w = self.m_upper:GetWidth()
	w = w -math.floor(w %self.m_upper:GetHeight())
	self.m_upperPerforations:SetWidth(w)
	self.m_lowerPerforations:SetWidth(w)
end
function SequenceFilmStrip:OnRemove() util.remove(self.m_nameChangeListener) end
function SequenceFilmStrip:GetLeftMargin() return self.m_leftDragHandle:GetWidth() end
function SequenceFilmStrip:GetRightMargin() return self.m_rightDragHandle:GetWidth() end
function SequenceFilmStrip:CreateDragHandle(startHandle)
	local function clamp_to_frame_rate(time, clampToAtLeastOneFrame)
		return self.m_filmStrip:GetSession():ClampTimeOffsetToFrameRate(time, clampToAtLeastOneFrame)
	end

	local dragHandle = gui.create("drag_handle", self.m_contents)
	dragHandle:AddStyleClass("drag_handle")
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
	self.m_nameChangeListener = activeClip:AddChangeListener("name", function(activeClip, newName)
		self.m_sessionName:SetText(newName)
	end)
end
gui.register("sequence_film_strip", SequenceFilmStrip)

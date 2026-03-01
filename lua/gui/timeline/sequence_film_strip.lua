-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local SequenceFilmStrip = util.register_class("gui.SequenceFilmStrip", gui.Base)
function SequenceFilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")

	self:SetSize(128, 93)

	local elBg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elBg:SetColor(Color(62, 62, 107))

	local leftDragHandle = self:CreateDragHandle(true, 0, 0, 12, self:GetHeight(), 0, 0, 0, 0)
	local rightDragHandle = self:CreateDragHandle(false, self:GetRight() -12, 0, 12, self:GetHeight(), 1, 0, 1, 0)

	local middleBar = gui.create("WIRect", self, 12, 0, self:GetWidth() -(12 +12), self:GetHeight(), 0, 0, 1, 1)
	middleBar:SetColor(Color.White)

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
	local dragHandle = gui.create("WIRect", self, x, y, w, h, ax, ay, aw, ah)
	dragHandle:SetColor(Color.Red)
	dragHandle:SetCursor(gui.CURSOR_SHAPE_HAND)

	dragHandle:SetMouseInputEnabled(true)
	dragHandle:AddCallback("OnMouseEvent", function(dragHandle, mouseButton, state, mods)
		if mouseButton == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				dragHandle:SetCursorMovementCheckEnabled(true)
				self.m_dragInitialXOffset = dragHandle:GetCursorPos().x
				if(startHandle) then
					self.m_dragInitialEnd = self:GetTimeFrame():GetEnd()
				end
			elseif state == input.STATE_RELEASE then
				dragHandle:SetCursorMovementCheckEnabled(false)
				self.m_dragInitialXOffset = nil
				if(startHandle) then
					self.m_dragInitialEnd = nil
				end
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	dragHandle:AddCallback("OnCursorMoved", function(dragHandle, x, y)
		if(util.is_valid(self.m_filmStrip) == false) then return end
		local timeLine = self.m_filmStrip:GetTimeline()
		if(util.is_valid(timeLine) == false) then return end
		x = x -self.m_dragInitialXOffset
		local axisTime = timeLine:GetTimeAxis():GetAxis()
		local xDragHandle = dragHandle:GetAbsolutePos().x
		if(startHandle == false) then
			xDragHandle = xDragHandle +dragHandle:GetWidth()
		end
		local time = axisTime:XOffsetToValue(xDragHandle +x -timeLine:GetAbsolutePos().x)
		if(startHandle) then
			self:GetTimeFrame():SetStart(time)
			self:GetTimeFrame():SetDuration(self.m_dragInitialEnd -time)
		else
			self:GetTimeFrame():SetDuration(time -self:GetTimeFrame():GetStart())
		end
	end)
	return dragHandle
end
function SequenceFilmStrip:SetTimeFrame(timeFrame) self.m_timeFrame = timeFrame end
function SequenceFilmStrip:GetTimeFrame() return self.m_timeFrame end
function SequenceFilmStrip:SetFilmStrip(filmStrip) self.m_filmStrip = filmStrip end
function SequenceFilmStrip:Test()
	if(not util.is_valid(self.m_filmStrip)) then return end
	local xLeft
	local xRight
	for _,el in ipairs(self.m_filmStrip:GetFilmClips()) do
		if(el:IsValid()) then
			if(xLeft == nil) then
				xLeft = el:GetLeft()
				xRight = el:GetRight()
			else
				xLeft = math.min(xLeft, el:GetLeft())
				xRight = math.max(xRight, el:GetRight())
			end
		end
	end

	local yTop = 0
	local yBottom = 80

	xLeft = xLeft -20
	xRight = xRight +20

	local x = xLeft
	local y = yTop
	local w = xRight -xLeft
	local h = yBottom -yTop
	self:SetSize(w, h)
	self:SetPos(x, y)
end
gui.register("sequence_film_strip", SequenceFilmStrip)

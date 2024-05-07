--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/graph_axis.lua")

local Element = util.register_class("gui.TimelineMarker", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetTimeOffsetProperty(util.FloatProperty(0.0))

	self:SetSize(1, 1)

	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HRESIZE)
end
function Element:OnRemove()
	util.remove(self.m_cbOnTimeOffsetChanged)
end
function Element:SetAxis(axis)
	self.m_axis = axis
end
function Element:GetAxis()
	return self.m_axis
end
function Element:SetTimeOffset(offset)
	self.m_timeOffset:Set(offset)
end
function Element:GetTimeOffset()
	return self.m_timeOffset:Get()
end
function Element:GetTimeOffsetProperty()
	return self.m_timeOffset
end
function Element:SetTimeOffsetProperty(prop)
	self.m_timeOffset = prop
	util.remove(self.m_cbOnTimeOffsetChanged)
	self.m_cbOnTimeOffsetChanged = prop:AddCallback(function()
		self:UpdateAxisPosition()
	end)
end
-- TODO: Get frame rate from project settings
function Element:SetFrameRate(frameRate)
	self.m_frameRate = frameRate
end
function Element:ClampTimeOffsetToFrameRate(offset)
	if self.m_frameRate ~= nil then
		-- Clamp to frame rate
		offset = offset * self.m_frameRate
		offset = math.round(offset)
		offset = offset / self.m_frameRate
	end
	return offset
end
function Element:UpdateTimeOffset()
	local pos = self:GetParent():GetCursorPos()
	if self.m_cursorMoveStartOffset ~= nil then
		pos = pos + self.m_cursorMoveStartOffset
	end
	local offset = self:GetAxis():XOffsetToValue(pos.x)

	if not input.is_alt_key_down() then
		offset = self:ClampTimeOffsetToFrameRate(offset)
	end

	self:SetTimeOffset(offset)
end
function Element:SetCursorMoveModeEnabled(enabled, relativeToCursor)
	if enabled then
		self:SetCursorMovementCheckEnabled(true)
		if util.is_valid(self.m_cbMove) == false then
			if relativeToCursor then
				self.m_cursorMoveStartOffset = (self:GetPos() + (self:GetSize() / 2)) - self:GetParent():GetCursorPos()
			else
				self.m_cursorMoveStartOffset = nil
			end
			self.m_cbMove = self:AddCallback("OnCursorMoved", function(el, x, y)
				self:UpdateTimeOffset()
				self:CallCallbacks("OnDragUpdate")
			end)
		end
	else
		self:SetCursorMovementCheckEnabled(false)
		self.m_cursorMoveStartOffset = nil
		if util.is_valid(self.m_cbMove) then
			self.m_cbMove:Remove()
		end
	end
end
function Element:IsDragging()
	return util.is_valid(self.m_cbMove)
end
function Element:StartDrag()
	if self:IsDragging() then
		return
	end
	self:SetCursorMoveModeEnabled(true)
	self:CallCallbacks("OnDragStart")
end
function Element:EndDrag()
	if not self:IsDragging() then
		return
	end
	self:SetCursorMoveModeEnabled(false)
	self:CallCallbacks("OnDragEnd")
end
function Element:MouseCallback(mouseButton, state, mods)
	if mouseButton == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:StartDrag()
		else
			self:EndDrag()
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function Element:UpdateAxisPosition()
	local x = self:GetAxis():ValueToXOffset(self:GetTimeOffset())
	x = x - self:GetWidth() * 0.5
	self:SetX(x)

	self:CallCallbacks("OnAxisPositionUpdated")
end
gui.register("WITimelineMarker", Element)

local Element = util.register_class("gui.TimelineMarkerLine", gui.TimelineMarker)
function Element:OnInitialize()
	gui.TimelineMarker.OnInitialize(self)

	self:SetSize(11, 128)
	local color = Color(94, 112, 132)
	self.m_line = gui.create("WIRect", self, 0, 0, 1, self:GetHeight())
	self.m_line:SetColor(color)

	self:UpdateLineEndPos()
end
function Element:UpdateLineEndPos()
	if util.is_valid(self.m_line) == false then
		return
	end
	self.m_line:SetHeight(self:GetHeight())
end
function Element:OnSizeChanged(w, h)
	self:UpdateLineEndPos()
end
gui.register("WITimelineMarkerLine", Element)

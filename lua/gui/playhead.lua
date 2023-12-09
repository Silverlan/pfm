--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/graph_axis.lua")

util.register_class("gui.Playhead", gui.Base)

function gui.Playhead:__init()
	gui.Base.__init(self)
end
function gui.Playhead:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeOffset = util.FloatProperty(0.0)

	self:SetSize(11, 128)
	local color = Color(94, 112, 132)
	self.m_line = gui.create("WIRect", self, 5, 8, 1, self:GetHeight() - 8 * 2)
	self.m_top = gui.create("WITexturedRect", self, 0, 0, 11, 16)
	self.m_top:SetMaterial("gui/pfm/timeline_upper_playhead")
	self.m_bottom = gui.create("WITexturedRect", self, 0, self:GetBottom() - 16, 11, 16, 0, 1, 0, 1)
	self.m_bottom:SetMaterial("gui/pfm/timeline_lower_playhead")

	self.m_line:SetColor(color)

	self:UpdateLineEndPos()

	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HRESIZE)
end
function gui.Playhead:SetAxis(axis)
	self.m_axis = axis
end
function gui.Playhead:GetAxis()
	return self.m_axis
end
function gui.Playhead:SetTimeOffset(offset)
	self.m_timeOffset:Set(offset)
end
function gui.Playhead:GetTimeOffset()
	return self.m_timeOffset:Get()
end
function gui.Playhead:GetTimeOffsetProperty()
	return self.m_timeOffset
end
function gui.Playhead:SetTimeOffsetProperty(prop)
	self.m_timeOffset = prop
end
function gui.Playhead:SetFrameRate(frameRate)
	self.m_frameRate = frameRate
end
function gui.Playhead:ClampTimeOffsetToFrameRate(offset)
	if self.m_frameRate ~= nil then
		-- Clamp to frame rate
		offset = offset * self.m_frameRate
		offset = math.round(offset)
		offset = offset / self.m_frameRate
	end
	return offset
end
function gui.Playhead:UpdateTimeOffset()
	local pos = self:GetParent():GetCursorPos()
	local offset = self:GetAxis():XOffsetToValue(pos.x)

	if not input.is_alt_key_down() then
		offset = self:ClampTimeOffsetToFrameRate(offset)
	end

	self:SetTimeOffset(offset)
end
function gui.Playhead:SetCursorMoveModeEnabled(enabled)
	if enabled then
		self:SetCursorMovementCheckEnabled(true)
		if util.is_valid(self.m_cbMove) == false then
			self.m_cbMove = self:AddCallback("OnCursorMoved", function(el, x, y)
				self:UpdateTimeOffset()
			end)
		end
	else
		self:SetCursorMovementCheckEnabled(false)
		if util.is_valid(self.m_cbMove) then
			self.m_cbMove:Remove()
		end
	end
end
function gui.Playhead:MouseCallback(mouseButton, state, mods)
	if mouseButton == input.MOUSE_BUTTON_LEFT then
		self:SetCursorMoveModeEnabled(state == input.STATE_PRESS)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.Playhead:SetPlayOffset(x)
	x = x - self:GetWidth() * 0.5
	self:SetX(x)
end
function gui.Playhead:UpdateLineEndPos()
	if util.is_valid(self.m_line) == false then
		return
	end
	self.m_line:SetHeight(self:GetHeight() - 8 * 2)
end
function gui.Playhead:OnSizeChanged(w, h)
	self:UpdateLineEndPos()
end
gui.register("WIPlayhead", gui.Playhead)

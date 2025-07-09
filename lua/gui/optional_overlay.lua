-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("trim_text.lua")

local Element = util.register_class("gui.OptionalOverlay", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 18)

	local bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bg:SetColor(Color(32, 32, 32))

	local bgOutline = gui.create("WIOutlinedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bgOutline:SetColor(Color.Black)

	local elText = gui.create("WITrimText", self)
	elText:SetFont("pfm_medium")
	elText:SetColor(Color.White)
	elText:SetX(5)
	elText:SetWidth(self:GetWidth() - 10)
	elText:SetHeight(self:GetHeight())
	elText:SetAnchor(0, 0, 1, 1)
	self.m_elText = elText

	self:SetMouseInputEnabled(true)
	self:SetCursor(gui.CURSOR_SHAPE_HAND)
end
function Element:SetText(text)
	self.m_elText:SetText(text .. ": Click to enable")
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:CallCallbacks("OnClicked")
		end
		return util.EVENT_REPLY_HANDLED
	end
end
gui.register("WIOptionalOverlay", Element)

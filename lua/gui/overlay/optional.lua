-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/trim_text.lua")

local Element = util.register_class("gui.OptionalOverlay", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(128, 18)

	local elText = gui.create("trim_text", self)
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
gui.register("optional_overlay", Element)

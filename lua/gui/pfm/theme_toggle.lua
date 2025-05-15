--[[
    Copyright (C) 2025 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.PFMThemeToggle", gui.Base)
Element.THEME_LIGHT = 0
Element.THEME_DARK = 1
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(12, 12)

	local el = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	el:AddStyleClass("theme_toggle_light")
	self.m_icon = el

	self:SetCursor(gui.CURSOR_SHAPE_HAND)
	self:SetMouseInputEnabled(true)

	self.m_theme = Element.THEME_DARK
	self:SetTooltip(locale.get_text("pfm_toggle_theme"))
end
function Element:SetTheme(theme)
	if theme == self.m_theme then
		return
	end
	self.m_icon:RemoveStyleClass("theme_toggle_light")
	self.m_icon:RemoveStyleClass("theme_toggle_dark")
	self.m_theme = theme

	local skin
	if theme == Element.THEME_DARK then
		skin = "pfm"
		self.m_icon:AddStyleClass("theme_toggle_light")
	else
		skin = "pfm_light"
		self.m_icon:AddStyleClass("theme_toggle_dark")
	end
	gui.load_skin(skin)

	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		tool.get_filmmaker():SetSkin(skin)
	end
end
function Element:Toggle()
	if self.m_theme == Element.THEME_DARK then
		self:SetTheme(Element.THEME_LIGHT)
	else
		self:SetTheme(Element.THEME_DARK)
	end
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
		self:Toggle()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
gui.register("WIPFMThemeToggle", Element)

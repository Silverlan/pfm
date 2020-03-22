--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/gridbox.lua")
include("/gui/asseticon.lua")

util.register_class("gui.IconGridView",gui.Base)
function gui.IconGridView:__init()
	gui.Base.__init(self)
end
function gui.IconGridView:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(64,64)

	self.m_iconContainer = gui.create("WIGridBox",self)
	self.m_icons = {}
	self:SetAutoSizeToContents(false,true)

	self:SetIconFactory(function(parent)
		return gui.create("WIImageIcon",parent)
	end)
end
function gui.IconGridView:SetIconFactory(factory) self.m_iconFactory = factory end
function gui.IconGridView:OnSizeChanged(w,h)
	if(util.is_valid(self.m_iconContainer)) then self.m_iconContainer:SetWidth(w) end
end
function gui.IconGridView:SetIconSelected(icon)
	if(util.is_valid(self.m_selectedIcon)) then self.m_selectedIcon:SetSelected(false) end
	icon:SetSelected(true)
	self.m_selectedIcon = icon

	self:CallCallbacks("OnIconSelected",icon)
end
function gui.IconGridView:GetIcons() return self.m_icons end
function gui.IconGridView:AddIcon(text,...)
	local el = self.m_iconFactory(self.m_iconContainer,...)
	if(el == nil) then return end
	el:SetText(text)
	table.insert(self.m_icons,el)

	el:SetMouseInputEnabled(true)
	el:AddCallback("OnMouseEvent",function(el,button,action,mods)
		if(util.is_valid(self) == false) then return end
		if(button == input.MOUSE_BUTTON_LEFT and action == input.STATE_PRESS) then
			self:SetIconSelected(el)
		end
	end)
	self:CallCallbacks("OnIconAdded",el)
	return el
end
gui.register("WIIconGridView",gui.IconGridView)

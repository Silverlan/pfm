--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.DragAndDropOverlay", gui.Base)
function Element:OnInitialize()
	self:SetSize(128, 128)
	local el = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	el:SetColor(Color(0, 0, 0, 230))

	self.m_elText = gui.create("WIText", self)

	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:TrapFocus(true)
	self:RequestFocus()

	self:SetText(locale.get_text("pfm_drop_here"))

	self:SetZPos(100000)
end
function Element:SetText(text, font)
	local elText = self.m_elText
	elText:SetFont(font or "pfm_medium")
	elText:SetText(text:upper())
	elText:SizeToContents()
	elText:CenterToParent()
	elText:SetColor(Color.White)
	elText:SetAnchor(0.5, 0.5, 0.5, 0.5)
end
function Element:OnRemove() end
gui.register("WIDragAndDropOverlay", Element)
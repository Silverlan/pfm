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

	local elText = gui.create("WIText", self)
	elText:SetFont("pfm_large")
	elText:SetText(locale.get_text("pfm_drop_here_to_install"):upper())
	elText:SizeToContents()
	elText:CenterToParent()
	elText:SetColor(Color.White)
	elText:SetAnchor(0.5, 0.5, 0.5, 0.5)

	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:TrapFocus(true)
	self:RequestFocus()
end
function Element:OnRemove() end
gui.register("WIDragAndDropOverlay", Element)

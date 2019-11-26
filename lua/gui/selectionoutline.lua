--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.SelectionOutline",gui.Base)

gui.SelectionOutline.SELECTION_COLOR = Color(238,201,75)

function gui.SelectionOutline:__init()
	gui.Base.__init(self)
end
function gui.SelectionOutline:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 64
	self:SetSize(w,h)

	self.m_bgOutline = gui.create("WIOutlinedRect",self,0,0,w,h,0,0,1,1)
	self.m_bgOutline:GetColorProperty():Link(self:GetColorProperty())
	self.m_bgOutline:SetOutlineWidth(2)

	self.m_bgSelection = gui.create("WIRect",self,0,0,w,14,0,0,1,0)
	self.m_bgSelection:GetColorProperty():Link(self:GetColorProperty())

	self:SetColor(gui.SelectionOutline.SELECTION_COLOR)
end
gui.register("WISelectionOutline",gui.SelectionOutline)

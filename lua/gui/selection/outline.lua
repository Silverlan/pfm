-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.SelectionOutline", gui.Base)

gui.SelectionOutline.SELECTION_COLOR = Color(238, 201, 75)

function gui.SelectionOutline:__init()
	gui.Base.__init(self)
end
function gui.SelectionOutline:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 64
	self:SetSize(w, h)

	self.m_bgOutline = gui.create("WIOutlinedRect", self, 0, 0, w, h, 0, 0, 1, 1)
	self.m_bgOutline:GetColorProperty():Link(self:GetColorProperty())
	self.m_bgOutline:SetOutlineWidth(2)

	self.m_bgSelection = gui.create("WIRect", self, 0, 0, w, 14, 0, 0, 1, 0)
	self.m_bgSelection:GetColorProperty():Link(self:GetColorProperty())

	self:SetColor(gui.SelectionOutline.SELECTION_COLOR)
end
gui.register("selection_outline", gui.SelectionOutline)

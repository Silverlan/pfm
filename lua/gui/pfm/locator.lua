-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("controls/slider/cursor.lua")

util.register_class("gui.PFMLocator", gui.Base)

function gui.PFMLocator:__init()
	gui.Base.__init(self)
end
function gui.PFMLocator:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(8, 8)

	local locator = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	locator:SetMaterial("gui/pfm/locator")
	locator:SetColor(Color.Black)
end
gui.register("pfm_locator", gui.PFMLocator)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slidercursor.lua")

util.register_class("gui.PFMLocator",gui.Base)

function gui.PFMLocator:__init()
	gui.Base.__init(self)
end
function gui.PFMLocator:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(8,8)
	local locator = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	locator:SetMaterial("gui/pfm/locator")
	locator:SetColor(Color.Black)

	self.m_cursor = self:Wrap("WIPFMSliderCursor")
	self.m_cursor:AddCallback("OnFractionChanged",function(el,fraction)
		self:CallCallbacks("OnFractionChanged",fraction)
	end)
end
function gui.PFMLocator:GetCursor() return self.m_cursor end
gui.register("WIPFMLocator",gui.PFMLocator)

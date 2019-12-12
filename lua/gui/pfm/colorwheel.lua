--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("locator.lua")

util.register_class("gui.PFMColorWheel",gui.Base)

function gui.PFMColorWheel:__init()
	gui.Base.__init(self)
end
function gui.PFMColorWheel:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(150,150)
	local tex = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	tex:SetMaterial("gui/pfm/color_wheel")

	local locator = gui.create("WIPFMLocator",self)
	locator:GetCursor():CenterToParentX()
	locator:GetCursor():SetType(gui.PFMSliderCursor.TYPE_VERTICAL)
	--[[locator:AddCallback("OnFractionChanged",function(el,fraction)
		self:CallCallbacks("OnBrightnessChanged",fraction)
	end)]]
	self.m_locator = locator
end
function gui.PFMColorWheel:SetColorRGB(color)
	-- TODO
end
function gui.PFMColorWheel:GetColorRGB()
	-- TODO
end
gui.register("WIPFMColorWheel",gui.PFMColorWheel)

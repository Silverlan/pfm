--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("locator.lua")

util.register_class("gui.PFMBrightnessSlider",gui.Base)

local TEX_BRIGHTNESS_GRADIENT = vulkan.create_gradient_texture(16,256,vulkan.FORMAT_R8G8B8A8_UNORM,Vector2(0,-1),{
	{offset = 0.0,color = Color.White},
	{offset = 1.0,color = Color.Black}
})
function gui.PFMBrightnessSlider:__init()
	gui.Base.__init(self)
end
function gui.PFMBrightnessSlider:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(15,150)
	local bg = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetTexture(TEX_BRIGHTNESS_GRADIENT)

	local locator = gui.create("WIPFMLocator",self)
	locator:GetCursor():CenterToParentX()
	locator:GetCursor():SetType(gui.PFMSliderCursor.TYPE_VERTICAL)
	locator:AddCallback("OnFractionChanged",function(el,fraction)
		self:CallCallbacks("OnBrightnessChanged",fraction)
	end)
	self.m_locator = locator
end
function gui.PFMBrightnessSlider:SetBrightness(brightness)
	self.m_locator:GetCursor():SetFraction(brightness)
end
function gui.PFMBrightnessSlider:GetBrightness()
	return 1.0 -self.m_locator:GetCursor():GetFraction()
end
gui.register("WIPFMBrightnessSlider",gui.PFMBrightnessSlider)

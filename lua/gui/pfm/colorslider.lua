--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slider.lua")

util.register_class("gui.PFMColorSlider",gui.PFMSlider)

function gui.PFMColorSlider:__init()
	gui.PFMSlider.__init(self)
end
function gui.PFMColorSlider:OnInitialize()
	gui.PFMSlider.OnInitialize(self)

	local sliderBg = gui.create("WIRect",self,0,3,self:GetWidth(),14,0,0,1,1)
	sliderBg:SetColor(Color(38,38,38,255))
	sliderBg:SetZPos(-5)

	self:SetRange(0.0,360.0)
	self:SetDefault(0.0)
	self:SetStepSize(0.1)
	self:AddCallback("OnLeftValueChanged",function(el,val)
		local hsv = util.HSVColor(val,1.0,1.0)
		self.m_bg:SetColor(hsv:ToRGBColor())

		self:CallCallbacks("OnValueChanged",hsv)
	end)
	self.m_bg:SetZPos(-10)
end
gui.register("WIPFMColorSlider",gui.PFMColorSlider)

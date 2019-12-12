--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("colorwheel.lua")
include("brightnessslider.lua")
include("slider.lua")

util.register_class("gui.PFMColorSelector",gui.Base)

function gui.PFMColorSelector:__init()
	gui.Base.__init(self)
end
function gui.PFMColorSelector:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(192,270)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color(32,32,32))

	self.m_contents = gui.create("WIHBox",self)
	gui.create("WIBase",self.m_contents,0,0,10,1) -- Gap

	self.m_coreContents = gui.create("WIVBox",self.m_contents)
	gui.create("WIBase",self.m_coreContents,0,0,1,10) -- Gap

	local selectorContents = gui.create("WIHBox",self.m_coreContents)
	local colorWheel = gui.create("WIPFMColorWheel",selectorContents)
	local brightnessSlider = gui.create("WIPFMBrightnessSlider",selectorContents)

	gui.create("WIBase",self.m_coreContents,0,0,1,10) -- Gap

	self.m_redSlider = gui.create("WIPFMSlider",self.m_coreContents)
	self.m_redSlider:SetRange(0,1,0)
	self.m_redSlider:AddCallback("OnLeftValueChanged",function(el,value)
		local color = self:GetColor():ToVector4()
		color.x = value
		self:SetColor(Color(color))
	end)

	self.m_greenSlider = gui.create("WIPFMSlider",self.m_coreContents)
	self.m_greenSlider:SetRange(0,1,0)
	self.m_greenSlider:AddCallback("OnLeftValueChanged",function(el,value)
		local color = self:GetColor():ToVector4()
		color.y = value
		self:SetColor(Color(color))
	end)

	self.m_blueSlider = gui.create("WIPFMSlider",self.m_coreContents)
	self.m_blueSlider:SetRange(0,1,0)
	self.m_blueSlider:AddCallback("OnLeftValueChanged",function(el,value)
		local color = self:GetColor():ToVector4()
		color.z = value
		self:SetColor(Color(color))
	end)

	self:SetColor(Color.White)
end
function gui.PFMColorSelector:SetColor(color)
	if(color == self:GetColor()) then return end
	self.m_color = color
	local vColor = color:ToVector4()
	if(util.is_valid(self.m_redSlider)) then
		self.m_redSlider:SetValue(vColor.x)
		self.m_redSlider:SetText(locale.get_text("pfm_color_r") .. ": " .. util.round_string(vColor.x,2))
	end
	if(util.is_valid(self.m_greenSlider)) then
		self.m_greenSlider:SetValue(vColor.y)
		self.m_greenSlider:SetText(locale.get_text("pfm_color_g") .. ": " .. util.round_string(vColor.y,2))
	end
	if(util.is_valid(self.m_blueSlider)) then
		self.m_blueSlider:SetValue(vColor.z)
		self.m_blueSlider:SetText(locale.get_text("pfm_color_b") .. ": " .. util.round_string(vColor.z,2))
	end
	self:CallCallbacks("OnColorChanged",color)
end
function gui.PFMColorSelector:GetColor() return self.m_color end
gui.register("WIPFMColorSelector",gui.PFMColorSelector)

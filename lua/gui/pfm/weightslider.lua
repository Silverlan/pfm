--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")

util.register_class("gui.PFMWeightSlider",gui.Base)

function gui.PFMWeightSlider:__init()
	gui.Base.__init(self)
end
function gui.PFMWeightSlider:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,33)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(38,38,38))

	self.m_sliderBar = gui.create("WIPFMWeightSliderBar",self,18,19)
	self.m_sliderBar:SetWidth(self:GetWidth() -18 *2)
	self.m_sliderBar:SetAnchor(0,0,1,0)
	self.m_sliderBar:AddCallback("OnFractionChanged",function(el,fraction)
		self:CallCallbacks("OnFractionChanged",fraction)
	end)

	local color = Color(152,152,152)
	self.m_labelL = gui.create("WIText",self)
	self.m_labelL:SetText(locale.get_text("pfm_weight_slider_left"))
	self.m_labelL:SetFont("pfm_medium")
	self.m_labelL:SizeToContents()
	self.m_labelL:SetColor(color)
	self.m_labelL:SetPos(4,15)

	self.m_labelR = gui.create("WIText",self)
	self.m_labelR:SetText(locale.get_text("pfm_weight_slider_right"))
	self.m_labelR:SetFont("pfm_medium")
	self.m_labelR:SizeToContents()
	self.m_labelR:SetColor(color)
	self.m_labelR:SetPos(self:GetWidth() -self.m_labelR:GetWidth() -5,15)
	self.m_labelR:SetAnchor(1,1,1,1)

	self.m_startIndicator = gui.create("WIRect",self,0,0,1,3)
	self.m_startIndicator:SetColor(color)
	self.m_startIndicator:SetY(7)

	self.m_centerIndicator = gui.create("WIRect",self,0,0,1,3)
	self.m_centerIndicator:SetColor(color)
	self.m_centerIndicator:SetY(7)

	self.m_endIndicator = gui.create("WIRect",self,0,0,1,3)
	self.m_endIndicator:SetColor(color)
	self.m_endIndicator:SetY(7)
end
function gui.PFMWeightSlider:GetFraction() return util.is_valid(self.m_sliderBar) and self.m_sliderBar:GetFraction() or 0.0 end
function gui.PFMWeightSlider:SetFraction(fraction) if(util.is_valid(self.m_sliderBar)) then self.m_sliderBar:SetFraction(fraction) end end
function gui.PFMWeightSlider:GetStepSize() return util.is_valid(self.m_sliderBar) and self.m_sliderBar:GetStepSize() or 0.0 end
function gui.PFMWeightSlider:SetStepSize(stepSize) if(util.is_valid(self.m_sliderBar)) then self.m_sliderBar:SetStepSize(stepSize) end end
function gui.PFMWeightSlider:OnSizeChanged(w,h)
	if(util.is_valid(self.m_startIndicator)) then self.m_startIndicator:SetX(self.m_sliderBar:GetX() +self.m_sliderBar:FractionToX(0)) end
	if(util.is_valid(self.m_centerIndicator)) then self.m_centerIndicator:SetX(self.m_sliderBar:GetX() +self.m_sliderBar:FractionToX(0.5)) end
	if(util.is_valid(self.m_endIndicator)) then self.m_endIndicator:SetX(self.m_sliderBar:GetX() +self.m_sliderBar:FractionToX(1.0)) end
end
gui.register("WIPFMWeightSlider",gui.PFMWeightSlider)

---------------

util.register_class("gui.PFMWeightSliderBar",gui.Base)

function gui.PFMWeightSliderBar:__init()
	gui.Base.__init(self)
end
function gui.PFMWeightSliderBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,15)

	self.m_sliderLine = gui.create("WIRect",self,0,0,self:GetWidth(),3,0,0,1,0)
	self.m_sliderLine:SetColor(Color.Black)
	self.m_sliderLine:CenterToParent()

	self.m_cursor = gui.create("WIRect",self,0,0,12,15)
	self.m_cursor:SetColor(Color(126,126,126))
	self:SetFraction(0.5)
	self:SetStepSize(0.05)
end
function gui.PFMWeightSliderBar:XToFraction(x)
	return (x -self.m_cursor:GetHalfWidth()) /(self:GetWidth() -self.m_cursor:GetWidth())
end
function gui.PFMWeightSliderBar:FractionToX(fraction)
	fraction = fraction *(self:GetWidth() -self.m_cursor:GetWidth())
	return fraction +self.m_cursor:GetHalfWidth()
end
function gui.PFMWeightSliderBar:SetStepSize(stepSize) self.m_stepSize = stepSize end
function gui.PFMWeightSliderBar:GetStepSize(stepSize) return self.m_stepSize end
function gui.PFMWeightSliderBar:GetFraction() return self.m_fraction end
function gui.PFMWeightSliderBar:SetFraction(fraction)
	if(util.is_valid(self.m_cursor) == false) then return end
	self.m_fraction = math.round(math.clamp(fraction,0.0,1.0),self:GetStepSize())
	local x = self.m_fraction *(self:GetWidth() -self.m_cursor:GetWidth())
	self.m_cursor:SetX(x)
	self:CallCallbacks("OnFractionChanged",self:GetFraction())
end
function gui.PFMWeightSliderBar:OnSizeChanged(w,h)
	self:SetFraction(self:GetFraction())
end
gui.register("WIPFMWeightSliderBar",gui.PFMWeightSliderBar)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMSliderBar",gui.Base)

function gui.PFMSliderBar:__init()
	gui.Base.__init(self)
end
function gui.PFMSliderBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,7)

	self.m_offsetFromDefaultIndicator = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight())
	self.m_offsetFromDefaultIndicator:SetColor(Color(61,61,61))

	self.m_cursor = gui.create("WIRect",self,0,0,1,self:GetHeight())
	self.m_cursor:SetVisible(false)
	self.m_cursor:SetColor(Color(131,131,131))

	self:SetRange(0,1)
end
function gui.PFMSliderBar:SetRange(min,max,optDefault)
	self.m_min = min
	self.m_max = max
	self.m_default = optDefault
	self:Update()
end
function gui.PFMSliderBar:SetValue(optValue)
	if(optValue ~= nil) then optValue = math.clamp(optValue,self:GetMin(),self:GetMax()) end
	self.m_value = optValue
	self:CallCallbacks("OnValueChanged",self:GetValue())
	self:Update()
end
function gui.PFMSliderBar:GetMin() return self.m_min end
function gui.PFMSliderBar:GetMax() return self.m_max end
function gui.PFMSliderBar:GetDefault() return self.m_default end
function gui.PFMSliderBar:GetValue() return self.m_value end
function gui.PFMSliderBar:GetFraction(value)
	return ((value or self:GetValue()) -self:GetMin()) /(self:GetMax() -self:GetMin())
end
function gui.PFMSliderBar:FractionToX(fraction)
	return fraction *self:GetWidth()
end
function gui.PFMSliderBar:ValueToX(value)
	return self:FractionToX(self:GetFraction(value))
end
function gui.PFMSliderBar:XToValue(x)
	x = x /self:GetWidth()
	return self:GetMin() +(self:GetMax() -self:GetMin()) *x
end
function gui.PFMSliderBar:OnUpdate()
	local value = self:GetValue()
	if(value == nil) then
		if(util.is_valid(self.m_offsetFromDefaultIndicator)) then self.m_offsetFromDefaultIndicator:SetVisible(false) end
		if(util.is_valid(self.m_cursor)) then self.m_cursor:SetVisible(false) end
		return
	end

	local x = self:ValueToX(self:GetValue())
	if(util.is_valid(self.m_cursor)) then
		self.m_cursor:SetVisible(true)
		self.m_cursor:SetX(x)
	end

	local default = self:GetDefault()
	if(default == nil or util.is_valid(self.m_offsetFromDefaultIndicator) == false) then
		if(util.is_valid(self.m_offsetFromDefaultIndicator)) then self.m_offsetFromDefaultIndicator:SetVisible(false) end
		return
	end
	self.m_offsetFromDefaultIndicator:SetVisible(true)
	local xDefault = self:ValueToX(default)
	local xMin = math.min(x,xDefault)
	local xMax = math.max(x,xDefault)
	self.m_offsetFromDefaultIndicator:SetX(xMin)
	self.m_offsetFromDefaultIndicator:SetWidth(xMax -xMin)
end
gui.register("WIPFMSliderBar",gui.PFMSliderBar)

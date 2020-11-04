--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slidercursor.lua")

util.register_class("gui.PFMSliderBar",gui.Base)

function gui.PFMSliderBar:__init()
	gui.Base.__init(self)
end
function gui.PFMSliderBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,7)

	self.m_offsetFromDefaultIndicator = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight())
	self.m_offsetFromDefaultIndicator:SetColor(Color(61,61,61))

	local cursorRect = gui.create("WIRect",self,0,0,1,self:GetHeight())
	cursorRect:SetColor(Color(131,131,131))

	self.m_cursor = cursorRect:Wrap("WIPFMSliderCursor")
	self.m_cursor:AddCallback("OnFractionChanged",function(el,fraction)
		self:OnFractionChanged(fraction)
	end)

	self:SetRange(0,1)
	self:ScheduleUpdate()
end
function gui.PFMSliderBar:GetCursor() return self.m_cursor end
function gui.PFMSliderBar:SetDefault(default)
	self.m_default = default
	self:SetValue(default)
	self:Update()
end
function gui.PFMSliderBar:SetRange(min,max) self.m_cursor:SetRange(min,max) end
function gui.PFMSliderBar:SetWeight(weight) self.m_cursor:SetWeight(weight) end
function gui.PFMSliderBar:GetMin() return self.m_cursor:GetMin() end
function gui.PFMSliderBar:GetMax() return self.m_cursor:GetMax() end
function gui.PFMSliderBar:SetMin(min) return self.m_cursor:SetMin(min) end
function gui.PFMSliderBar:SetMax(max) return self.m_cursor:SetMax(max) end
function gui.PFMSliderBar:SetValue(value) self.m_cursor:SetValue(value) end
function gui.PFMSliderBar:SetInteger(b) self.m_cursor:SetInteger(b) end
function gui.PFMSliderBar:OnFractionChanged(fraction)
	self:CallCallbacks("OnValueChanged",self:GetValue())
	self:Update()
end
function gui.PFMSliderBar:GetDefault() return self.m_default end
function gui.PFMSliderBar:GetValue() return self.m_cursor:GetValue() end
function gui.PFMSliderBar:GetFraction(value)
	return ((value or self:GetValue()) -self:GetMin()) /(self:GetMax() -self:GetMin())
end
function gui.PFMSliderBar:SetFraction(fraction)
	self.m_cursor:SetFraction(fraction)
end
function gui.PFMSliderBar:FractionToOffset(fraction)
	return fraction *self:GetWidth()
end
function gui.PFMSliderBar:ValueToOffset(value)
	return self:FractionToOffset(self:GetFraction(value))
end
function gui.PFMSliderBar:OffsetToValue(x)
	x = x /self:GetWidth()
	return self:GetMin() +(self:GetMax() -self:GetMin()) *x
end
function gui.PFMSliderBar:OnSizeChanged()
	self:ScheduleUpdate()
end
function gui.PFMSliderBar:OnUpdate()
	local value = self:GetValue()
	if(value == nil) then
		if(util.is_valid(self.m_offsetFromDefaultIndicator)) then self.m_offsetFromDefaultIndicator:SetVisible(false) end
		--if(util.is_valid(self.m_cursor)) then self.m_cursor:SetVisible(false) end
		return
	end

	local x = self:ValueToOffset(self:GetValue())
	if(util.is_valid(self.m_cursor)) then
		--self.m_cursor:SetVisible(true)
		self.m_cursor:SetX(x)
	end

	local default = self:GetDefault()
	if(default == nil or util.is_valid(self.m_offsetFromDefaultIndicator) == false) then
		if(util.is_valid(self.m_offsetFromDefaultIndicator)) then self.m_offsetFromDefaultIndicator:SetVisible(false) end
		return
	end
	self.m_offsetFromDefaultIndicator:SetVisible(true)
	local xDefault = self:ValueToOffset(default)
	local xMin = math.min(x,xDefault)
	local xMax = math.max(x,xDefault)
	self.m_offsetFromDefaultIndicator:SetX(xMin)
	self.m_offsetFromDefaultIndicator:SetWidth(xMax -xMin)
end
gui.register("WIPFMSliderBar",gui.PFMSliderBar)

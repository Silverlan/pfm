-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("cursor.lua")

local Element = util.register_class("gui.PFMSliderBar", gui.Base)

function Element:__init()
	gui.Base.__init(self)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 7)

	self.m_offsetFromDefaultIndicator = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_offsetFromDefaultIndicator:SetColor(Color(61, 61, 61))

	local bgFilled = gui.create("WIRect", self)
	bgFilled:AddStyleClass("slider_filled")
	self.m_bgFilled = bgFilled

	local cursorRect = gui.create("WIRect", self, 0, 0, 1, self:GetHeight())
	cursorRect:SetColor(Color(131, 131, 131))
	self.m_cursorRect = cursorRect

	self.m_cursor = cursorRect:Wrap("pfm_slider_cursor")
	self.m_cursor:AddCallback("OnValueChanged", function(el, value, fraction)
		self:OnValueChanged(value, fraction)
	end)
	self.m_cursor:AddCallback("OnUserInputStarted", function(el, fraction)
		self:OnUserInputStarted(fraction)
	end)
	self.m_cursor:AddCallback("OnUserInputEnded", function(el, fraction)
		self:OnUserInputEnded(fraction)
	end)

	self:SetRange(0, 1)
	self:ScheduleUpdate()
end
function Element:GetCursor()
	return self.m_cursor
end
function Element:SetDefault(default)
	self.m_default = default
	self:SetValue(default)
	self:Update()
end
function Element:SetStepSize(stepSize)
	self.m_cursor:SetStepSize(stepSize)
end
function Element:GetStepSize()
	return self.m_cursor:GetStepSize()
end
function Element:SetRange(min, max)
	self.m_cursor:SetRange(min, max)
end
function Element:SetWeight(weight)
	self.m_cursor:SetWeight(weight)
end
function Element:GetMin()
	return self.m_cursor:GetMin()
end
function Element:GetMax()
	return self.m_cursor:GetMax()
end
function Element:SetMin(min)
	return self.m_cursor:SetMin(min)
end
function Element:SetMax(max)
	return self.m_cursor:SetMax(max)
end
function Element:SetValue(value)
	self.m_cursor:SetValue(value)
end
function Element:SetInteger(b)
	self.m_cursor:SetInteger(b)
end
function Element:OnValueChanged(value, fraction)
	self:CallCallbacks("OnValueChanged", value)
	self:Update()
end
function Element:OnUserInputStarted(fraction)
	self:CallCallbacks("OnUserInputStarted", self:GetValue())
end
function Element:OnUserInputEnded(fraction)
	self:CallCallbacks("OnUserInputEnded", self:GetValue())
end
function Element:GetDefault()
	return self.m_default
end
function Element:GetValue()
	return self.m_cursor:GetValue()
end
function Element:GetFraction(value)
	return ((value or self:GetValue()) - self:GetMin()) / (self:GetMax() - self:GetMin())
end
function Element:SetFraction(fraction)
	self.m_cursor:SetFraction(fraction)
end
function Element:FractionToOffset(fraction)
	return fraction * self:GetWidth()
end
function Element:ValueToOffset(value)
	return self:FractionToOffset(self:GetFraction(value))
end
function Element:OffsetToValue(x)
	x = x / self:GetWidth()
	return self:GetMin() + (self:GetMax() - self:GetMin()) * x
end
function Element:OnSizeChanged()
	if util.is_valid(self.m_cursorRect) then
		self.m_cursorRect:SetHeight(self:GetHeight())
	end
	if util.is_valid(self.m_cursor) then
		self.m_cursor:SetHeight(self:GetHeight())
	end
	if util.is_valid(self.m_bgFilled) then
		self.m_bgFilled:SetHeight(self:GetHeight())
	end
	self:ScheduleUpdate()
end
function Element:OnUpdate()
	local value = self:GetValue()
	if value == nil then
		if util.is_valid(self.m_offsetFromDefaultIndicator) then
			self.m_offsetFromDefaultIndicator:SetVisible(false)
		end
		--if(util.is_valid(self.m_cursor)) then self.m_cursor:SetVisible(false) end
		return
	end

	local x = self:ValueToOffset(self:GetValue())
	if util.is_valid(self.m_cursor) then
		--self.m_cursor:SetVisible(true)
		self.m_cursor:SetX(x)
	end

	if util.is_valid(self.m_bgFilled) then
		self.m_bgFilled:SetWidth(x)
	end

	local default = self:GetDefault()
	if default == nil or util.is_valid(self.m_offsetFromDefaultIndicator) == false then
		if util.is_valid(self.m_offsetFromDefaultIndicator) then
			self.m_offsetFromDefaultIndicator:SetVisible(false)
		end
		return
	end
	self.m_offsetFromDefaultIndicator:SetVisible(true)
	local xDefault = self:ValueToOffset(default)
	local xMin = math.min(x, xDefault)
	local xMax = math.max(x, xDefault)
	self.m_offsetFromDefaultIndicator:SetX(xMin)
	self.m_offsetFromDefaultIndicator:SetWidth(xMax - xMin)
end
gui.register("pfm_slider_bar", Element)

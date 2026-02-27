-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.PFMSliderCursor", gui.Base)

Element.TYPE_HORIZONTAL = 0
Element.TYPE_VERTICAL = 1
function Element:__init()
	gui.Base.__init(self)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnCursorMoved", function(el, x, y)
		self:OnCursorMoved(x, y)
	end)
	self.m_value = util.FloatProperty(0.0)
	self:SetType(Element.TYPE_HORIZONTAL)
	self:SetRange(0.0, 1.0)
	self:SetStepSize(0.0)
	self:SetFraction(0.0)
	self:SetWeight(1.0)
end
function Element:SetStepSize(stepSize)
	self.m_stepSize = stepSize
end
function Element:GetStepSize()
	return self.m_stepSize
end
function Element:SetRange(min, max)
	self.m_min = min
	self.m_max = max
	self:Update()
end
function Element:GetMin()
	return self.m_min
end
function Element:GetMax()
	return self.m_max
end
function Element:SetMin(min)
	self.m_min = min
	self:Update()
end
function Element:SetMax(max)
	self.m_max = max
	self:Update()
end
function Element:GetType()
	return self.m_type
end
function Element:IsHorizontal()
	return self:GetType() == Element.TYPE_HORIZONTAL
end
function Element:IsVertical()
	return self:GetType() == Element.TYPE_VERTICAL
end
function Element:SetInteger(b)
	self.m_intType = b
end
function Element:GetBounds(el)
	el = el or self
	return self:IsHorizontal() and el:GetWidth() or el:GetHeight()
end
function Element:OffsetToFraction(v)
	return (v - self:GetBounds() / 2) / (self:GetBounds(self:GetParent()) - self:GetBounds())
end
function Element:FractionToOffset(fraction)
	fraction = fraction * (self:GetBounds(self:GetParent()) - self:GetBounds())
	return fraction + self:GetBounds() / 2
end
function Element:GetRange()
	return self:GetMax() - self:GetMin()
end
function Element:FractionToValue(fraction)
	return self:GetMin() + fraction * self:GetRange()
end
function Element:ValueToFraction(value)
	local range = self:GetRange()
	if range == 0 then
		return 0
	end
	return (value - self:GetMin()) / range
end
function Element:GetFraction()
	return self:ValueToFraction(self:GetValue())
end
function Element:SetFraction(fraction, inputOrigin)
	local val = self:FractionToValue(fraction)
	self:SetValue(val, inputOrigin)
end
function Element:GetValueProperty()
	return self.m_value
end
function Element:SetValue(value, inputOrigin)
	if self.m_skipSetValue then
		return
	end
	self.m_skipSetValue = true -- Prevent callbacks from changing fraction while we're still doing our thing
	self.m_value:Set(value)
	self:UpdateValue(inputOrigin)
	self.m_skipSetValue = nil
end
function Element:GetValue()
	return self.m_value:Get()
end
function Element:UpdateValue(inputOrigin)
	local v = self:GetFraction() * (self:GetBounds(self:GetParent()) - self:GetBounds())
	if self:IsHorizontal() then
		self:SetX(v)
	else
		self:SetY(v)
	end
	self:CallCallbacks("OnValueChanged", self:GetValue(), self:GetFraction(), inputOrigin)
end
function Element:OnSizeChanged(w, h)
	self:UpdateValue()
end
function Element:SetType(type)
	self.m_type = type
end
function Element:IsActive()
	return self.m_cursorStartOffset ~= nil
end
function Element:SetCursorDragModeEnabled(enabled)
	if enabled then
		self.m_cursorTracker = gui.CursorTracker()
		self.m_cursorTracker:SetSticky(true)
		gui.set_cursor_input_mode(gui.CURSOR_MODE_HIDDEN)
		self.m_dragStartValue = self:GetValue()
		self:SetThinkingEnabled(true)

		self:SetCursorMovementCheckEnabled(true)
		self.m_cursorStartOffset = self:IsHorizontal() and self:GetParent():GetCursorPos().x
			or self:GetParent():GetCursorPos().y
		self:CallCallbacks("OnUserInputStarted", self:GetFraction())
		return
	end
	if self.m_dragStartValue == nil then
		return
	end
	self.m_cursorTracker = nil
	gui.set_cursor_input_mode(gui.CURSOR_MODE_NORMAL)
	self.m_dragStartValue = nil
	self:SetThinkingEnabled(false)

	self:SetCursorMovementCheckEnabled(false)
	self.m_cursorStartOffset = nil
	self:CallCallbacks("OnUserInputEnded", self:GetFraction())
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:SetCursorDragModeEnabled(true)
		elseif state == input.STATE_RELEASE then
			self:SetCursorDragModeEnabled(false)
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function Element:SetWeight(weight)
	self.m_weight = weight
end
function Element:GetWeight()
	return self.m_weight
end
function Element:OnThink()
	if self.m_cursorTracker ~= nil then
		self.m_cursorTracker:Update()
	end
end
function Element:OnRemove()
	self:SetCursorDragModeEnabled(false)
end
function Element:GetDiscreteStepSize()
	return math.get_largest_power_of_10(self:GetMax()) / 100.0
end
function Element:OnCursorMoved(x, y)
	--print(self,self:GetParent():GetCursorPos().x)

	local p = self:GetParent()
	local pos
	local extent
	local dt = self.m_cursorTracker:GetTotalDeltaPosition()
	if self:IsHorizontal() then
		extent = p:GetWidth()
		pos = p:GetCursorPos().x
		dt = dt.x
	else
		extent = p:GetHeight()
		pos = p:GetCursorPos().y
		dt = dt.y
	end
	self.m_cursorTracker:Update()
	if input.is_shift_key_down() then
		local value = self.m_dragStartValue + math.floor(dt / 4) / 100.0
		value = math.clamp(value, self:GetMin(), self:GetMax())
		self:SetValue(value, "user")
		return
	end
	local stepSize = self:GetStepSize()
	if stepSize == 0.0 then
		stepSize = 0.001
	end
	if input.is_ctrl_key_down() then
		stepSize = self:GetDiscreteStepSize()
	end
	local range = self:GetMax() - self:GetMin()
	local changePerPixel = range / extent
	local pixelsPerStep = stepSize / changePerPixel
	local value = self.m_dragStartValue + math.floor(dt / pixelsPerStep) * stepSize
	if input.is_ctrl_key_down() then
		value = math.round(value / stepSize) * stepSize
	end
	value = math.clamp(value, self:GetMin(), self:GetMax())
	self:SetValue(value, "user")
end
gui.register("pfm_slider_cursor", Element)

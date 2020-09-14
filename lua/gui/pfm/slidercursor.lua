--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMSliderCursor",gui.Base)

gui.PFMSliderCursor.TYPE_HORIZONTAL = 0
gui.PFMSliderCursor.TYPE_VERTICAL = 1
function gui.PFMSliderCursor:__init()
	gui.Base.__init(self)
end
function gui.PFMSliderCursor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnCursorMoved",function(el,x,y)
		self:OnCursorMoved(x,y)
	end)
	self.m_fraction = util.FloatProperty(0.0)
	self:SetType(gui.PFMSliderCursor.TYPE_HORIZONTAL)
	self:SetStepSize(0.0)
	self:SetFraction(0.0)
	self:SetWeight(1.0)
end
function gui.PFMSliderCursor:SetRange(min,max)
	self.m_min = min
	self.m_max = max
	self:Update()
end
function gui.PFMSliderCursor:GetMin() return self.m_min end
function gui.PFMSliderCursor:GetMax() return self.m_max end
function gui.PFMSliderCursor:GetType() return self.m_type end
function gui.PFMSliderCursor:IsHorizontal() return self:GetType() == gui.PFMSliderCursor.TYPE_HORIZONTAL end
function gui.PFMSliderCursor:IsVertical() return self:GetType() == gui.PFMSliderCursor.TYPE_VERTICAL end
function gui.PFMSliderCursor:SetInteger(b) self.m_intType = b end
function gui.PFMSliderCursor:GetBounds(el)
	el = el or self
	return self:IsHorizontal() and el:GetWidth() or el:GetHeight()
end
function gui.PFMSliderCursor:OffsetToFraction(v)
	return (v -self:GetBounds() /2) /(self:GetBounds(self:GetParent()) -self:GetBounds())
end
function gui.PFMSliderCursor:FractionToOffset(fraction)
	fraction = fraction *(self:GetBounds(self:GetParent()) -self:GetBounds())
	return fraction +self:GetBounds() /2
end
function gui.PFMSliderCursor:SetStepSize(stepSize) self.m_stepSize = stepSize end
function gui.PFMSliderCursor:GetStepSize(stepSize) return self.m_stepSize end
function gui.PFMSliderCursor:GetFraction() return self.m_fraction:Get() end
function gui.PFMSliderCursor:GetFractionProperty() return self.m_fraction end
function gui.PFMSliderCursor:SetValue(value)
	local fraction = (value -self:GetMin()) /(self:GetMax() -self:GetMin())
	self:SetFraction(fraction)
end
function gui.PFMSliderCursor:GetValue()
	local value = self:GetMin() +self:GetFraction() *(self:GetMax() -self:GetMin())
	if(self.m_intType == true) then value = math.round(value) end
	return value
end
function gui.PFMSliderCursor:SetFraction(fraction)
	local stepSize = self:GetStepSize()
	if(stepSize > 0.0) then fraction = math.round(fraction,stepSize) end
	self.m_fraction:Set(math.clamp(fraction,0.0,1.0))
	self:UpdateFraction()
end
function gui.PFMSliderCursor:UpdateFraction()
	local v = self:GetFraction() *(self:GetBounds(self:GetParent()) -self:GetBounds())
	if(self:IsHorizontal()) then self:SetX(v)
	else self:SetY(v) end
	self:CallCallbacks("OnFractionChanged",self:GetFraction())
end
function gui.PFMSliderCursor:OnSizeChanged(w,h)
	self:UpdateFraction()
end
function gui.PFMSliderCursor:SetType(type)
	self.m_type = type
end
function gui.PFMSliderCursor:IsActive() return self.m_cursorStartOffset ~= nil end
function gui.PFMSliderCursor:SetCursorDragModeEnabled(enabled)
	if(enabled) then
		self:SetCursorMovementCheckEnabled(true)
		self.m_cursorStartOffset = self:IsHorizontal() and self:GetParent():GetCursorPos().x or self:GetParent():GetCursorPos().y
		return
	end
	self:SetCursorMovementCheckEnabled(false)
	self.m_cursorStartOffset = nil
end
function gui.PFMSliderCursor:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			self:SetCursorDragModeEnabled(true)
		elseif(state == input.STATE_RELEASE) then
			self:SetCursorDragModeEnabled(false)
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMSliderCursor:SetWeight(weight) self.m_weight = weight end
function gui.PFMSliderCursor:GetWeight() return self.m_weight end
function gui.PFMSliderCursor:OnCursorMoved(x,y)
	--print(self,self:GetParent():GetCursorPos().x)

	local p = self:GetParent()
	local x = p:GetCursorPos().x
	local w = p:GetWidth()
	local fraction = (w > 0) and (x /w) or 0.0
	local stepSize = self:GetStepSize()
	if(stepSize > 0.0) then fraction = fraction -(fraction %stepSize) end
	self:SetFraction(fraction)

	--[[if(self.m_cursorStartOffset == nil) then return end
	local v = self:IsHorizontal() and (self:GetX() +x) or (self:GetY() +y)
	local vDelta = v -self.m_cursorStartOffset
	vDelta = vDelta *self:GetWeight()
	if(vDelta == 0.0) then return end
	if(self:GetStepSize() == 0.0) then
		self.m_cursorStartOffset = v
		local sz = self:IsHorizontal() and (self:GetParent():GetWidth() -self:GetWidth()) or (self:GetParent():GetHeight() -self:GetHeight())
		if(sz > 0) then
			local step = vDelta /sz
			self:SetFraction(self:GetFraction() +step)
		end
		return
	end

	-- Note: Our cursor element behaves slightly different than the actual mouse cursor.
	-- When moving in the range [0,1], the cursor element will start at offset 0 and move to width -cursorWidth (if the slider is horizontal).
	-- The mouse cursor, however, has to start at offset 0 and move all the way to width. This causes a visual disconnect between the mouse cursor
	-- and the cursor element, so we scale the mouse cursor step size so that both of them match visually.
	local cursorStepSize = (self:IsHorizontal() and self:GetParent():GetWidth() or self:GetParent():GetHeight()) /(1.0 /self:GetStepSize())
	cursorStepSize = cursorStepSize -(cursorStepSize /self:FractionToOffset(self:GetStepSize()))

	cursorStepSize = math.max(cursorStepSize,1.0) -- TODO: Something fishy with this, see resolution bars in Filmmaker Cycles render tab
	if(cursorStepSize <= 0.0) then return end

	local sign = math.sign(vDelta)
	vDelta = math.abs(vDelta)
	while(vDelta >= cursorStepSize) do
		self:SetFraction(self:GetFraction() +self:GetStepSize() *sign)
		self.m_cursorStartOffset = self.m_cursorStartOffset +cursorStepSize *sign
		vDelta = vDelta -cursorStepSize
	end]]
end
gui.register("WIPFMSliderCursor",gui.PFMSliderCursor)

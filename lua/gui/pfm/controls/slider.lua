-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/ui/fonts.lua")
include("/gui/wicontextmenu.lua")
include("/gui/pfm/dialogs/entry_edit_window.lua")
include("slider/bar.lua")
include("slider/arrow.lua")

local Element = util.register_class("gui.PFMSlider", gui.Base)

function Element:__init()
	gui.Base.__init(self)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 20)

	local bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bg:SetColor(Color.Clear)
	self.m_bg = bg

	self.m_sliderBarUpper = gui.create("pfm_slider_bar", self, 0, 3)
	self.m_sliderBarUpper:SetWidth(self:GetWidth())
	self.m_sliderBarUpper:SetHeight(self:GetHeight() - 6)
	self.m_sliderBarUpper:SetAnchor(0, 0, 1, 1)
	self.m_sliderBarUpper:AddCallback("OnValueChanged", function(el, value)
		self:CallCallbacks("OnLeftValueChanged", value)
		self:UpdateText()
	end)
	self.m_sliderBarUpper:AddCallback("OnUserInputStarted", function(el, value)
		self:CallCallbacks("OnUserInputStarted", value)
	end)
	self.m_sliderBarUpper:AddCallback("OnUserInputEnded", function(el, value)
		self:CallCallbacks("OnUserInputEnded", value)
	end)
	self.m_sliderBarUpper:GetCursor():AddCallback("TranslateFraction", function(el, value)
		return self:TranslateValue(value)
	end)

	local elArrow = gui.create("pfm_slider_arrow", self)
	elArrow:SetArrowType("left")
	elArrow:SetVisible(false)
	elArrow:AddCallback("OnClicked", function(el)
		local val = self:GetValue() - self.m_sliderBarUpper:GetCursor():GetDiscreteStepSize()
		self:SetValue(math.clamp(val, self:GetMin(), self:GetMax()))
	end)
	self.m_elArrowLeft = elArrow

	local elArrow = gui.create("pfm_slider_arrow", self)
	elArrow:SetArrowType("right")
	elArrow:SetVisible(false)
	elArrow:AddCallback("OnClicked", function(el)
		local val = self:GetValue() + self.m_sliderBarUpper:GetCursor():GetDiscreteStepSize()
		self:SetValue(math.clamp(val, self:GetMin(), self:GetMax()))
	end)
	elArrow:SetX(self:GetWidth() - elArrow:GetWidth())
	elArrow:SetAnchor(1, 0, 1, 1)
	self.m_elArrowRight = elArrow

	--self.m_sliderBarUpper:GetCursor():SetStepSize(stepSize / (self:GetMax() - self:GetMin()))

	--[[self.m_sliderBarLower = gui.create("pfm_slider_bar",self,0,self.m_sliderBarUpper:GetBottom())
	self.m_sliderBarLower:SetWidth(self:GetWidth())
	self.m_sliderBarLower:SetAnchor(0,0,1,0)
	self.m_sliderBarLower:AddCallback("OnValueChanged",function(el,value)
		self:CallCallbacks("OnRightValueChanged",value)
		self:UpdateText()
	end)]]

	self.m_text = gui.create("WIText", self)
	self.m_text:AddStyleClass("input_field_text")
	self.m_text:SetVisible(false)

	self.m_leftRightRatio = util.FloatProperty(0.5)
	self:SetStepSize(0.0)
	self:SetRange(0, 1)
	self:SetLeftRightValueRatio(0.5)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnDoubleClick", function()
		-- TODO: Add edit field!
		return util.EVENT_REPLY_HANDLED
	end)

	self:AddStyleClass("input_field")
end
function Element:OnCursorEntered()
	self.m_elArrowLeft:SetVisible(true)
	self.m_elArrowRight:SetVisible(true)
end
function Element:OnCursorExited()
	self.m_elArrowLeft:SetVisible(false)
	self.m_elArrowRight:SetVisible(false)
end
function Element:TranslateValue(value)
	local stepSize = self:GetStepSize()
	local min = self:GetMin()
	local max = self:GetMax()
	local range = max - min
	value = min + value * range
	if input.is_alt_key_down() then
		value = math.floor(value)
	end
	value = (value / range) - min

	return value
end
function Element:OnSizeChanged(w, h)
	if util.is_valid(self.m_sliderBarUpper) then
		self.m_sliderBarUpper:Update()
	end
	--if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:Update() end
end
function Element:SetStepSize(stepSize)
	self.m_stepSize = stepSize
	local strStepSize = tostring(stepSize)
	local decimalPlacePos = strStepSize:find("%.")
	self.m_numDecimalPlaces = 0
	if stepSize == 0 then
		self.m_numDecimalPlaces = 2
	elseif decimalPlacePos ~= nil then
		self.m_numDecimalPlaces = #strStepSize - decimalPlacePos - 1
	end
	self.m_sliderBarUpper:SetStepSize(stepSize)
	self:UpdateStepSize()
end
function Element:GetStepSize()
	return self.m_stepSize
end
function Element:UpdateStepSize()
	--if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():SetStepSize(stepSize /(self:GetMax() -self:GetMin())) end
end
function Element:SetLeftRightValueRatio(ratio)
	self.m_leftRightRatio:Set(math.clamp(ratio, 0.0, 1.0))

	local scaleRight = 0.0
	local scaleLeft = 0.0
	-- If ratio >= 0.5 -> left slider will be at full speed, otherwise right slider.
	-- Other slider will be scaled accordingly.
	if ratio > 0.5 then
		scaleRight = 1.0
		scaleLeft = ((1.0 - ratio) / 0.5)
	else
		scaleRight = ratio / 0.5
		scaleLeft = 1.0
	end
	self.m_sliderBarUpper:SetWeight(scaleLeft)
	--self.m_sliderBarLower:SetWeight(scaleRight)
end
function Element:GetLeftRightValueRatio()
	return self.m_leftRightRatio:Get()
end
function Element:GetLeftRightValueRatioProperty()
	return self.m_leftRightRatio
end
function Element:GetLeftSliderBar()
	return self.m_sliderBarUpper
end
function Element:GetRightSliderBar()
	return self.m_sliderBarLower
end
function Element:SetLeftRange(min, max, optDefault)
	self.m_defaultMin = min
	self.m_defaultMax = max
	local bar = self:GetLeftSliderBar()
	if util.is_valid(bar) then
		bar:SetRange(min, max, optDefault)
	end
end
function Element:SetRightRange(min, max, optDefault)
	local bar = self:GetRightSliderBar()
	if util.is_valid(bar) then
		bar:SetRange(min, max, optDefault)
	end
end
function Element:SetRange(min, max, optDefault)
	self:SetLeftRange(min, max, optDefault)
	self:SetRightRange(min, max, optDefault)
	self:UpdateStepSize()
end
function Element:GetRange()
	local bar = self:GetLeftSliderBar()
	if util.is_valid(bar) then
		return bar:GetMin(), bar:GetMax(), bar:GetDefault()
	end
	return 0.0, 0.0, 0.0
end
function Element:SetDefault(default)
	self:GetLeftSliderBar():SetDefault(default)
	-- self:GetRightSliderBar():SetDefault(default)
end
function Element:SetLeftValue(value)
	local bar = self:GetLeftSliderBar()
	if util.is_valid(bar) then
		bar:SetValue(value)
	end
end
function Element:SetRightValue(value) end -- local bar = self:GetRightSliderBar() if(util.is_valid(bar)) then bar:SetValue(value) end end
function Element:SetValueAndUpdateRange(val, useDefaultRange)
	self:SetValue(val, useDefaultRange)
end
function Element:SetValue(optValue, useDefaultRange)
	self:SetLeftValue(optValue)
	self:SetRightValue(optValue)

	if optValue ~= nil then
		local val = optValue
		local max = val
		if useDefaultRange then
			max = self.m_defaultMax or max
		else
			max = self:GetMax()
		end
		max = math.max(max, val)

		local min = val
		if useDefaultRange then
			min = self.m_defaultMin or min
		else
			min = self:GetMin()
		end
		min = math.min(min, val)

		self:GetLeftSliderBar():SetMin(min)
		self:GetLeftSliderBar():SetMax(max)
		self:ScheduleUpdate()
	end
end
function Element:SetInteger(b)
	self:GetLeftSliderBar():SetInteger(b)
	-- self:GetRightSliderBar():SetInteger(b)
end
function Element:GetLeftMin(value)
	local bar = self:GetLeftSliderBar()
	return util.is_valid(bar) and bar:GetMin() or 0.0
end
function Element:GetRightMin(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMin() or 0.0 end
function Element:GetLeftMax(value)
	local bar = self:GetLeftSliderBar()
	return util.is_valid(bar) and bar:GetMax() or 0.0
end
function Element:GetRightMax(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMax() or 0.0 end
function Element:GetLeftDefault(value)
	local bar = self:GetLeftSliderBar()
	return util.is_valid(bar) and bar:GetDefault() or 0.0
end
function Element:GetRightDefault(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetDefault() or 0.0 end
function Element:GetLeftValue(value)
	local bar = self:GetLeftSliderBar()
	return util.is_valid(bar) and bar:GetValue() or 0.0
end
function Element:GetRightValue(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetValue() or 0.0 end
function Element:GetMin()
	return self:GetLeftMin()
end
function Element:GetMax()
	return self:GetLeftMax()
end
function Element:SetMin(min)
	self.m_defaultMin = min
	local bar = self:GetLeftSliderBar()
	bar:SetMin(min)

	-- bar = self:GetRightSliderBar()
	-- bar:SetMin(min)
end
function Element:SetMax(max)
	self.m_defaultMax = max
	local bar = self:GetLeftSliderBar()
	bar:SetMax(max)

	-- bar = self:GetRightSliderBar()
	-- bar:SetMax(max)
end
function Element:GrowRangeToValue(value)
	if value < self:GetMin() then
		self:SetMin(value)
	end
	if value > self:GetMax() then
		self:SetMax(value)
	end
end
function Element:GetDefault()
	return self:GetLeftDefault()
end
function Element:ResetToDefault()
	self:SetLeftValue(self:GetLeftDefault())
	self:SetRightValue(self:GetRightDefault())
end
function Element:GetValue()
	return self:GetLeftValue()
end
function Element:CreateSliderRangeEditWindow(min, max, default, fOnClose)
	local teMin
	local teMax
	local teDefault
	local p = pfm.open_entry_edit_window(locale.get_text("pfm_slider_range_edit_window_title"), function(ok)
		if ok then
			local min = util.is_valid(teMin) and tonumber(teMin:GetText()) or 0.0
			local max = util.is_valid(teMax) and tonumber(teMax:GetText()) or 0.0
			local default = util.is_valid(teDefault) and tonumber(teDefault:GetText()) or 0.0
			fOnClose(true, min, max, default)
		else
			fOnClose(false)
		end
	end)

	teMin = p:AddNumericEntryField(locale.get_text("min") .. ":", tostring(min))
	teMax = p:AddNumericEntryField(locale.get_text("max") .. ":", tostring(max))
	teDefault = p:AddNumericEntryField(locale.get_text("default") .. ":", tostring(default))

	p:SetWindowSize(Vector2i(202, 160))
	p:Update()
end
function Element:OnThink()
	if self.m_cursorTracker ~= nil then
		self.m_cursorTracker:Update()
		local dt = self.m_cursorTracker:GetTotalDeltaPosition()
		if math.abs(dt.x) > 3 or math.abs(dt.y) > 3 then
			self.m_cursorTracker = nil
			self:SetThinkingEnabled(false)

			if util.is_valid(self.m_sliderBarUpper) then
				self.m_sliderBarUpper:GetCursor():InjectMouseInput(
					self.m_sliderBarUpper:GetCursor():GetCursorPos(),
					input.MOUSE_BUTTON_LEFT,
					input.STATE_PRESS,
					input.MOD_NONE
				)
			end
		end
	end
end
function Element:OnUpdate()
	local lb = self:GetLeftSliderBar()
	if util.is_valid(lb) then
		lb:Update()
	end
end
function Element:MouseCallback(button, state, mods)
	if state == input.STATE_RELEASE then
		self.m_cursorTracker = nil
		util.remove(self.m_elEntry)
		local el = gui.create("WINumericEntry", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
		el:SetText(tostring(self:GetValue()))
		el:AddCallback("OnTextEntered", function(...)
			util.remove(el, true)
			local val = tonumber(el:GetText()) or 0.0
			self:CallCallbacks("OnUserInputStarted", self:GetValue())
			self:SetValueAndUpdateRange(val, true)
			self:CallCallbacks("OnUserInputEnded", val)
		end)
		el:AddCallback("OnFocusKilled", function()
			util.remove(el, true)
		end)
		-- el:SetMaxLength(2)
		el:RequestFocus()
		el:SetCaretPos(#el:GetText())
		self.m_elEntry = el
		return util.EVENT_REPLY_HANDLED
	end
	if button == input.MOUSE_BUTTON_LEFT then
		self.m_cursorTracker = gui.CursorTracker()
		self:SetThinkingEnabled(true)
		-- if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():InjectMouseInput(self.m_sliderBarLower:GetCursor():GetCursorPos(),button,state,mods) end
		return util.EVENT_REPLY_HANDLED
	elseif button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_RELEASE then
		local pContext = gui.open_context_menu(self)
		if util.is_valid(pContext) == false then
			return
		end
		pContext:SetPos(input.get_cursor_pos())
		local default = self:GetDefault()
		if default ~= nil then
			pContext:AddItem(locale.get_text("reset"), function()
				if self:IsValid() == false then
					return
				end
				self:SetValue(self:GetDefault())
			end)
		end
		pContext
			:AddItem(locale.get_text("pfm_remap_slider_range"), function()
				self:CreateSliderRangeEditWindow(
					self:GetMin(),
					self:GetMax(),
					self:GetDefault(),
					function(ok, min, max, default)
						if ok == true then
							self:SetRange(min, max, default)
						end
					end
				)
			end)
			:SetName("remap_slider_range")
		pContext:AddItem(locale.get_text("copy_to_clipboard"), function()
			util.set_clipboard_string(tostring(self:GetValue()))
		end)
		self:CallCallbacks("PopulateContextMenu", pContext)
		pContext:Update()
	end
	return util.EVENT_REPLY_HANDLED
end
function Element:SetText(text)
	if util.is_valid(self.m_text) == false then
		return
	end
	self.m_text:SetVisible(#text > 0)
	self.m_baseText = text
	self:UpdateText()
end
function Element:SetUnit(unit)
	self.m_unit = unit
	self:UpdateText()
end
function Element:UpdateText()
	if self.m_baseText == nil then
		return
	end
	local text = self.m_baseText .. ": "
	text = text .. util.round_string(self:GetLeftValue(), self.m_numDecimalPlaces)
	if self:GetLeftRightValueRatio() ~= 0.5 then
		text = text .. " / " .. util.round_string(self:GetRightValue(), self.m_numDecimalPlaces)
	end
	if self.m_unit ~= nil then
		text = text .. " " .. self.m_unit
	end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParent(true)
end
gui.register("pfm_slider", Element)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("/gui/wicontextmenu.lua")
include("/gui/pfm/entry_edit_window.lua")
include("sliderbar.lua")

util.register_class("gui.PFMSlider",gui.Base)

function gui.PFMSlider:__init()
	gui.Base.__init(self)
end
function gui.PFMSlider:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,20)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color.Clear)
	self.m_bg = bg

	self.m_sliderBarUpper = gui.create("WIPFMSliderBar",self,0,3)
	self.m_sliderBarUpper:SetWidth(self:GetWidth())
	self.m_sliderBarUpper:SetHeight(self:GetHeight() -6)
	self.m_sliderBarUpper:SetAnchor(0,0,1,1)
	self.m_sliderBarUpper:AddCallback("OnValueChanged",function(el,value)
		self:CallCallbacks("OnLeftValueChanged",value)
		self:UpdateText()
	end)
	self.m_sliderBarUpper:AddCallback("OnUserInputStarted",function(el,value)
		self:CallCallbacks("OnUserInputStarted",value)
	end)
	self.m_sliderBarUpper:AddCallback("OnUserInputEnded",function(el,value)
		self:CallCallbacks("OnUserInputEnded",value)
	end)

	--[[self.m_sliderBarLower = gui.create("WIPFMSliderBar",self,0,self.m_sliderBarUpper:GetBottom())
	self.m_sliderBarLower:SetWidth(self:GetWidth())
	self.m_sliderBarLower:SetAnchor(0,0,1,0)
	self.m_sliderBarLower:AddCallback("OnValueChanged",function(el,value)
		self:CallCallbacks("OnRightValueChanged",value)
		self:UpdateText()
	end)]]

	self.m_text = gui.create("WIText",self)
	self.m_text:AddStyleClass("input_field_text")
	self.m_text:SetVisible(false)

	self.m_leftRightRatio = util.FloatProperty(0.5)
	self:SetStepSize(0.0)
	self:SetRange(0,1)
	self:SetLeftRightValueRatio(0.5)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnDoubleClick",function()
		-- TODO: Add edit field!
		return util.EVENT_REPLY_HANDLED
	end)

	self:AddStyleClass("input_field")
end
function gui.PFMSlider:OnSizeChanged(w,h)
	if(util.is_valid(self.m_sliderBarUpper)) then self.m_sliderBarUpper:Update() end
	--if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:Update() end
end
function gui.PFMSlider:SetStepSize(stepSize)
	self.m_stepSize = stepSize
	local strStepSize = tostring(stepSize)
	local decimalPlacePos = strStepSize:find("%.")
	self.m_numDecimalPlaces = 0
	if(decimalPlacePos ~= nil) then
		if(stepSize == 0) then self.m_numDecimalPlaces = 2
		else self.m_numDecimalPlaces = #strStepSize -decimalPlacePos -1 end
	end
	self:UpdateStepSize()
end
function gui.PFMSlider:GetStepSize() return self.m_stepSize end
function gui.PFMSlider:UpdateStepSize()
	local stepSize = self:GetStepSize()
	if(util.is_valid(self.m_sliderBarUpper)) then self.m_sliderBarUpper:GetCursor():SetStepSize(stepSize /(self:GetMax() -self:GetMin())) end
	--if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():SetStepSize(stepSize /(self:GetMax() -self:GetMin())) end
end
function gui.PFMSlider:SetLeftRightValueRatio(ratio)
	self.m_leftRightRatio:Set(math.clamp(ratio,0.0,1.0))

	local scaleRight = 0.0
	local scaleLeft = 0.0
	-- If ratio >= 0.5 -> left slider will be at full speed, otherwise right slider.
	-- Other slider will be scaled accordingly.
	if(ratio > 0.5) then
		scaleRight = 1.0
		scaleLeft = ((1.0 -ratio) /0.5)
	else
		scaleRight = ratio /0.5
		scaleLeft = 1.0
	end
	self.m_sliderBarUpper:SetWeight(scaleLeft)
	--self.m_sliderBarLower:SetWeight(scaleRight)
end
function gui.PFMSlider:GetLeftRightValueRatio() return self.m_leftRightRatio:Get() end
function gui.PFMSlider:GetLeftRightValueRatioProperty() return self.m_leftRightRatio end
function gui.PFMSlider:GetLeftSliderBar() return self.m_sliderBarUpper end
function gui.PFMSlider:GetRightSliderBar() return self.m_sliderBarLower end
function gui.PFMSlider:SetLeftRange(min,max,optDefault) local bar = self:GetLeftSliderBar() if(util.is_valid(bar)) then bar:SetRange(min,max,optDefault) end end
function gui.PFMSlider:SetRightRange(min,max,optDefault) local bar = self:GetRightSliderBar() if(util.is_valid(bar)) then bar:SetRange(min,max,optDefault) end end
function gui.PFMSlider:SetRange(min,max,optDefault)
	self:SetLeftRange(min,max,optDefault)
	self:SetRightRange(min,max,optDefault)
	self:UpdateStepSize()
end
function gui.PFMSlider:GetRange() local bar = self:GetLeftSliderBar() if(util.is_valid(bar)) then return bar:GetMin(),bar:GetMax(),bar:GetDefault() end return 0.0,0.0,0.0 end
function gui.PFMSlider:SetDefault(default)
	self:GetLeftSliderBar():SetDefault(default)
	-- self:GetRightSliderBar():SetDefault(default)
end
function gui.PFMSlider:SetLeftValue(value) local bar = self:GetLeftSliderBar() if(util.is_valid(bar)) then bar:SetValue(value) end end
function gui.PFMSlider:SetRightValue(value) end -- local bar = self:GetRightSliderBar() if(util.is_valid(bar)) then bar:SetValue(value) end end
function gui.PFMSlider:SetValue(optValue)
	self:SetLeftValue(optValue)
	self:SetRightValue(optValue)
end
function gui.PFMSlider:SetInteger(b)
	self:GetLeftSliderBar():SetInteger(b)
	-- self:GetRightSliderBar():SetInteger(b)
end
function gui.PFMSlider:GetLeftMin(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetMin() or 0.0 end
function gui.PFMSlider:GetRightMin(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMin() or 0.0 end
function gui.PFMSlider:GetLeftMax(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetMax() or 0.0 end
function gui.PFMSlider:GetRightMax(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMax() or 0.0 end
function gui.PFMSlider:GetLeftDefault(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetDefault() or 0.0 end
function gui.PFMSlider:GetRightDefault(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetDefault() or 0.0 end
function gui.PFMSlider:GetLeftValue(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetValue() or 0.0 end
function gui.PFMSlider:GetRightValue(value) end -- local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetValue() or 0.0 end
function gui.PFMSlider:GetMin() return self:GetLeftMin() end
function gui.PFMSlider:GetMax() return self:GetLeftMax() end
function gui.PFMSlider:SetMin(min)
	local bar = self:GetLeftSliderBar()
	bar:SetMin(min)

	-- bar = self:GetRightSliderBar()
	-- bar:SetMin(min)
end
function gui.PFMSlider:SetMax(min)
	local bar = self:GetLeftSliderBar()
	bar:SetMax(min)
	
	-- bar = self:GetRightSliderBar()
	-- bar:SetMax(min)
end
function gui.PFMSlider:GrowRangeToValue(value)
	if(value < self:GetMin()) then self:SetMin(value) end
	if(value > self:GetMax()) then self:SetMax(value) end
end
function gui.PFMSlider:GetDefault() return self:GetLeftDefault() end
function gui.PFMSlider:ResetToDefault()
	self:SetLeftValue(self:GetLeftDefault())
	self:SetRightValue(self:GetRightDefault())
end
function gui.PFMSlider:GetValue() return self:GetLeftValue() end
function gui.PFMSlider:CreateSliderRangeEditWindow(min,max,default,fOnClose)
	local teMin
	local teMax
	local teDefault
	local p = pfm.open_entry_edit_window(locale.get_text("pfm_slider_range_edit_window_title"),function(ok)
		if(ok) then
			local min = util.is_valid(teMin) and tonumber(teMin:GetText()) or 0.0
			local max = util.is_valid(teMax) and tonumber(teMax:GetText()) or 0.0
			local default = util.is_valid(teDefault) and tonumber(teDefault:GetText()) or 0.0
			fOnClose(true,min,max,default)
		else fOnClose(false) end
	end)

	teMin = p:AddNumericEntryField(locale.get_text("min") .. ":",tostring(min))
	teMax = p:AddNumericEntryField(locale.get_text("max") .. ":",tostring(max))
	teDefault = p:AddNumericEntryField(locale.get_text("default") .. ":",tostring(default))

	p:SetWindowSize(Vector2i(202,160))
	p:Update()
end
function gui.PFMSlider:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(util.is_valid(self.m_sliderBarUpper)) then self.m_sliderBarUpper:GetCursor():InjectMouseInput(self.m_sliderBarUpper:GetCursor():GetCursorPos(),button,state,mods) end
		-- if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():InjectMouseInput(self.m_sliderBarLower:GetCursor():GetCursorPos(),button,state,mods) end
		return util.EVENT_REPLY_HANDLED
	elseif(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_RELEASE) then
		local pContext = gui.open_context_menu()
		if(util.is_valid(pContext) == false) then return end
		pContext:SetPos(input.get_cursor_pos())
		local default = self:GetDefault()
		if(default ~= nil) then
			pContext:AddItem(locale.get_text("pfm_set_to_default"),function()
				if(self:IsValid() == false) then return end
				self:SetValue(self:GetDefault())
			end)
		end
		pContext:AddItem(locale.get_text("pfm_remap_slider_range"),function()
			self:CreateSliderRangeEditWindow(self:GetMin(),self:GetMax(),self:GetDefault(),function(ok,min,max,default)
				if(ok == true) then
					self:SetRange(min,max,default)
				end
			end)
		end)
		pContext:AddItem(locale.get_text("copy_to_clipboard"),function()
			util.set_clipboard_string(tostring(self:GetValue()))
		end)
		self:CallCallbacks("PopulateContextMenu",pContext)
		pContext:Update()
	end
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMSlider:SetText(text)
	if(util.is_valid(self.m_text) == false) then return end
	self.m_text:SetVisible(#text > 0)
	self.m_baseText = text
	self:UpdateText()
end
function gui.PFMSlider:SetUnit(unit)
	self.m_unit = unit
	self:UpdateText()
end
function gui.PFMSlider:UpdateText()
	if(self.m_baseText == nil) then return end
	local text = self.m_baseText .. ": "
	text = text .. util.round_string(self:GetLeftValue(),self.m_numDecimalPlaces)
	if(self:GetLeftRightValueRatio() ~= 0.5) then
		text = text .. " / " .. util.round_string(self:GetRightValue(),self.m_numDecimalPlaces)
	end
	if(self.m_unit ~= nil) then text = text .. " " .. self.m_unit end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParent(true)
end
gui.register("WIPFMSlider",gui.PFMSlider)

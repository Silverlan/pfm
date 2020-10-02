--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("/gui/wicontextmenu.lua")
include("sliderbar.lua")
include("window.lua")

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
	self.m_sliderBarUpper:SetAnchor(0,0,1,0)
	self.m_sliderBarUpper:AddCallback("OnValueChanged",function(el,value)
		self:CallCallbacks("OnLeftValueChanged",value)
		self:UpdateText()
	end)

	self.m_sliderBarLower = gui.create("WIPFMSliderBar",self,0,self.m_sliderBarUpper:GetBottom())
	self.m_sliderBarLower:SetWidth(self:GetWidth())
	self.m_sliderBarLower:SetAnchor(0,0,1,0)
	self.m_sliderBarLower:AddCallback("OnValueChanged",function(el,value)
		self:CallCallbacks("OnRightValueChanged",value)
		self:UpdateText()
	end)

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
	if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:Update() end
end
function gui.PFMSlider:SetStepSize(stepSize)
	self.m_stepSize = stepSize
	local strStepSize = tostring(stepSize)
	local decimalPlacePos = strStepSize:find(".")
	self.m_numDecimalPlaces = 0
	if(decimalPlacePos ~= nil) then
		self.m_numDecimalPlaces = #strStepSize -decimalPlacePos -1
	end
	self:UpdateStepSize()
end
function gui.PFMSlider:GetStepSize() return self.m_stepSize end
function gui.PFMSlider:UpdateStepSize()
	local stepSize = self:GetStepSize()
	if(util.is_valid(self.m_sliderBarUpper)) then self.m_sliderBarUpper:GetCursor():SetStepSize(stepSize /(self:GetMax() -self:GetMin())) end
	if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():SetStepSize(stepSize /(self:GetMax() -self:GetMin())) end
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
	self.m_sliderBarLower:SetWeight(scaleRight)
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
function gui.PFMSlider:SetDefault(default)
	self:GetLeftSliderBar():SetDefault(default)
	self:GetRightSliderBar():SetDefault(default)
end
function gui.PFMSlider:SetLeftValue(value) local bar = self:GetLeftSliderBar() if(util.is_valid(bar)) then bar:SetValue(value) end end
function gui.PFMSlider:SetRightValue(value) local bar = self:GetRightSliderBar() if(util.is_valid(bar)) then bar:SetValue(value) end end
function gui.PFMSlider:SetValue(optValue)
	self:SetLeftValue(optValue)
	self:SetRightValue(optValue)
end
function gui.PFMSlider:SetInteger(b)
	self:GetLeftSliderBar():SetInteger(b)
	self:GetRightSliderBar():SetInteger(b)
end
function gui.PFMSlider:GetLeftMin(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetMin() or 0.0 end
function gui.PFMSlider:GetRightMin(value) local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMin() or 0.0 end
function gui.PFMSlider:GetLeftMax(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetMax() or 0.0 end
function gui.PFMSlider:GetRightMax(value) local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetMax() or 0.0 end
function gui.PFMSlider:GetLeftDefault(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetDefault() or 0.0 end
function gui.PFMSlider:GetRightDefault(value) local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetDefault() or 0.0 end
function gui.PFMSlider:GetLeftValue(value) local bar = self:GetLeftSliderBar() return util.is_valid(bar) and bar:GetValue() or 0.0 end
function gui.PFMSlider:GetRightValue(value) local bar = self:GetRightSliderBar() return util.is_valid(bar) and bar:GetValue() or 0.0 end
function gui.PFMSlider:GetMin() return self:GetLeftMin() end
function gui.PFMSlider:GetMax() return self:GetLeftMax() end
function gui.PFMSlider:GetDefault() return self:GetLeftDefault() end
function gui.PFMSlider:ResetToDefault()
	self:SetLeftValue(self:GetLeftDefault())
	self:SetRightValue(self:GetRightDefault())
end
function gui.PFMSlider:GetValue() return self:GetLeftValue() end
function gui.PFMSlider:CreateSliderRangeEditWindow(min,max,default,fOnClose)
	local p = gui.create("WIPFMWindow")

	p:SetWindowSize(Vector2i(202,160))
	p:SetTitle(locale.get_text("pfm_slider_range_edit_window_title"))

	local contents = p:GetContents()

	gui.create("WIBase",contents,0,0,1,12) -- Gap

	local t = gui.create("WITable",contents)
	t:RemoveStyleClass("WITable")
	t:SetWidth(p:GetWidth() -13)
	t:SetRowHeight(28)

	local function add_text_field(name,value)
		local row = t:AddRow()
		row:SetValue(0,name)

		local textEntry = gui.create("WINumericEntry")
		textEntry:SetWidth(133)
		textEntry:SetText(value)
		row:InsertElement(1,textEntry)
		return textEntry
	end
	local teMin = add_text_field(locale.get_text("min") .. ":",tostring(min))
	local teMax = add_text_field(locale.get_text("max") .. ":",tostring(max))
	local teDefault = add_text_field(locale.get_text("default") .. ":",tostring(default))

	t:Update()
	t:SizeToContents()

	gui.create("WIBase",contents,0,0,1,3) -- Gap

	local boxButtons = gui.create("WIHBox",contents)

	local btOk = gui.create("WIButton",boxButtons)
	btOk:SetSize(73,21)
	btOk:SetText(locale.get_text("ok"))
	btOk:AddCallback("OnMousePressed",function()
		local min = util.is_valid(teMin) and tonumber(teMin:GetText()) or 0.0
		local max = util.is_valid(teMax) and tonumber(teMax:GetText()) or 0.0
		local default = util.is_valid(teDefault) and tonumber(teDefault:GetText()) or 0.0
		p:GetFrame():Remove()
		fOnClose(true,min,max,default)
	end)

	gui.create("WIBase",boxButtons,0,0,8,1) -- Gap

	local btCancel = gui.create("WIButton",boxButtons)
	btCancel:SetSize(73,21)
	btCancel:SetText(locale.get_text("cancel"))
	btCancel:AddCallback("OnMousePressed",function()
		p:GetFrame():Remove()
		fOnClose(false)
	end)

	boxButtons:Update()
	boxButtons:SetX(contents:GetWidth() -boxButtons:GetWidth())
	return p
end
function gui.PFMSlider:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(util.is_valid(self.m_sliderBarUpper)) then self.m_sliderBarUpper:GetCursor():InjectMouseInput(self.m_sliderBarUpper:GetCursor():GetCursorPos(),button,state,mods) end
		if(util.is_valid(self.m_sliderBarLower)) then self.m_sliderBarLower:GetCursor():InjectMouseInput(self.m_sliderBarLower:GetCursor():GetCursorPos(),button,state,mods) end
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

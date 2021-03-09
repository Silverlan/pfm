--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/gui/pfm/slider.lua")

util.register_class("gui.PFMControlsMenu",gui.VBox)
function gui.PFMControlsMenu:__init()
	gui.VBox.__init(self)
end
function gui.PFMControlsMenu:OnInitialize()
	gui.VBox.OnInitialize(self)

	self.m_controls = {}
	self.m_subMenus = {}
	self:SetAutoFillContents(true)
end
function gui.PFMControlsMenu:AddControl(name,ctrl,wrapper,default)
	self.m_controls[name] = {
		element = ctrl,
		wrapper = wrapper,
		default = default
	}
	if(default ~= nil) then self:SetDefault(name,default) end
	self:CallCallbacks("OnControlAdded",name,ctrl,wrapper)
end
function gui.PFMControlsMenu:ClearControls()
	for identifier,data in pairs(self.m_controls) do
		util.remove(data.wrapper)
		util.remove(data.element)
	end
	self.m_controls = {}
end
function gui.PFMControlsMenu:GetControl(name) return (self.m_controls[name] ~= nil) and self.m_controls[name].element or nil end
function gui.PFMControlsMenu:SetControlVisible(identifier,visible)
	local elData = self.m_controls[identifier]
	if(elData == nil) then return end
	local el = (elData.wrapper ~= nil) and elData.wrapper or elData.element
	if(util.is_valid(el) == false) then return end
	el:SetVisible(visible)
end
function gui.PFMControlsMenu:AddFileEntry(name,identifier,default,callback)
	local el = gui.create("WIFileEntry",self)
	el:AddCallback("OnValueChanged",function(...)
		self:OnValueChanged(identifier,el:GetValue())
	end)
	if(callback ~= nil) then el:SetBrowseHandler(callback) end
	el:SetTooltip(name .. "_desc")
	local wrapper = el:Wrap("WIEditableEntry")
	wrapper:SetText(name)
	if(identifier ~= nil) then self:AddControl(identifier,el,wrapper,default) end
	return el
end
function gui.PFMControlsMenu:AddTextEntry(name,identifier,default,callback)
	local el = gui.create("WITextEntry",self)
	el:AddCallback("OnTextEntered",function(...)
		self:OnValueChanged(identifier,el:GetText())
		if(callback ~= nil) then callback(...) end
	end)
	el:SetTooltip(name .. "_desc")
	local wrapper = el:Wrap("WIEditableEntry")
	wrapper:SetText(name)
	if(identifier ~= nil) then self:AddControl(identifier,el,wrapper,default) end
	return el
end
function gui.PFMControlsMenu:AddToggleControl(name,identifier,checked,onChange)
	local el = gui.create("WIToggleOption",self)
	el:SetText(name)
	el:SetChecked(checked)
	el:SetTooltip(name .. "_desc")
	el:GetCheckbox():AddCallback("OnChange",function(...)
		self:OnValueChanged(identifier,el:IsChecked())
		if(onChange ~= nil) then onChange(...) end
	end)
	if(identifier ~= nil) then self:AddControl(identifier,el) end
	return el
end
function gui.PFMControlsMenu:AddSliderControl(name,identifier,default,min,max,onChange,stepSize,integer)
	local slider = gui.create("WIPFMSlider",self)
	slider:SetText(name)
	slider:SetRange(min,max)
	if(integer ~= nil) then slider:SetInteger(integer) end
	if(stepSize ~= nil) then slider:SetStepSize(stepSize) end
	slider:AddCallback("OnLeftValueChanged",function(...)
		self:OnValueChanged(identifier,slider:GetValue())
		if(onChange ~= nil) then onChange(...) end
	end)
	if(identifier ~= nil) then self:AddControl(identifier,slider,nil,default) end
	return slider
end
function gui.PFMControlsMenu:AddDropDownMenu(name,identifier,options,defaultOption,onChange)
	local menu = gui.create("WIDropDownMenu",self)
	for _,option in pairs(options) do
		menu:AddOption(option[2],option[1])
	end
	local wrapper = menu:Wrap("WIEditableEntry")
	wrapper:SetText(name)
	menu:AddCallback("OnOptionSelected",function(...)
		self:OnValueChanged(identifier,menu:GetOptionValue(menu:GetSelectedOption()))
		if(onChange ~= nil) then onChange(...) end
	end)
	if(identifier ~= nil) then self:AddControl(identifier,menu,wrapper,defaultOption) end
	return menu,wrapper
end
function gui.PFMControlsMenu:AddColorField(name,identifier,defaultOption,onChange)
	local colorEntry = gui.create("WIPFMColorEntry",self)
	colorEntry:GetColorProperty():AddCallback(function(...)
		self:OnValueChanged(identifier,colorEntry:GetValue())
		if(onChange ~= nil) then onChange(...) end
	end)
	local colorEntryWrapper = colorEntry:Wrap("WIEditableEntry")
	colorEntryWrapper:SetText(name)
	if(identifier ~= nil) then self:AddControl(identifier,colorEntry,colorEntryWrapper,defaultOption) end
	colorEntry:SetColor(defaultOption)
	return colorEntry,colorEntryWrapper
end
function gui.PFMControlsMenu:AddButton(name,identifier,onPress)
	local bt = gui.create("WIPFMButton",self)
	bt:SetText(name)
	if(onPress ~= nil) then bt:AddCallback("OnPressed",onPress) end
	if(identifier ~= nil) then self:AddControl(identifier,bt) end
	return bt
end
function gui.PFMControlsMenu:SetDefault(identifier,default)
	if(self.m_controls[identifier] == nil) then return end
	self.m_controls[identifier].default = default
	-- local el = self.m_controls[identifier].element
	-- if(util.is_valid(el) and el:GetClass() == "wipfmslider") then el:SetDefault(default) end
end
function gui.PFMControlsMenu:SetValue(identifier,value)
	local ctrl = self.m_controls[identifier]
	if(util.is_valid(ctrl.element) == false) then return end
	if(ctrl.element:GetClass() == "widropdownmenu") then ctrl.element:SelectOption(value)
	elseif(ctrl.element:GetClass() == "wipfmslider") then ctrl.element:SetDefault(value)
	elseif(ctrl.element:GetClass() == "wipfmcolorentry") then ctrl.element:SetColor(value)
	elseif(ctrl.element:GetClass() == "witextentry") then ctrl.element:SetText(value)
	elseif(ctrl.element:GetClass() == "witoggleoption") then ctrl.element:SetChecked(value)
	else ctrl.element:SetValue(value) end
end
function gui.PFMControlsMenu:LinkToUDMProperty(identifier,o,propName,translateControlValue,translatePropertyValue)
	local prop = o:GetProperty(propName)
	if(prop == nil) then
		error(propName .. " is not a valid property of " .. tostring(o))
	end
	local default = prop:GetValue()

	local el = self.m_controls[identifier].element
	local isDropDownMenu = (util.is_valid(el) and el:GetClass() == "widropdownmenu")
	if(isDropDownMenu) then default = tostring(default) end

	prop:AddChangeListener(function(newValue)
		if(self.m_skipPropCallback ~= nil and self.m_skipPropCallback[identifier] == true) then return end
		if(isDropDownMenu) then newValue = tostring(newValue) end
		if(translatePropertyValue) then newValue = translatePropertyValue(newValue) end
		self:SetValue(identifier,newValue)
	end)

	self:SetDefault(identifier,default)
	self.m_controls[identifier].property = prop
	self.m_controls[identifier].controlValueToPropertyValue = translateControlValue
end
function gui.PFMControlsMenu:OnValueChanged(identifier,value)
	if(self.m_controls[identifier] == nil or self.m_controls[identifier].property == nil) then return end
	local prop = self.m_controls[identifier].property
	local type = prop:GetType()
	if(type == fudm.ATTRIBUTE_TYPE_FLOAT or type == fudm.ATTRIBUTE_TYPE_TIME) then value = tonumber(value) end
	if(type == fudm.ATTRIBUTE_TYPE_INT or type == fudm.ATTRIBUTE_TYPE_UINT8 or type == fudm.ATTRIBUTE_TYPE_UINT64) then value = math.round(tonumber(value)) end
	if(type == fudm.ATTRIBUTE_TYPE_BOOL) then value = toboolean(value) end
	self.m_skipPropCallback = self.m_skipPropCallback or {}
	self.m_skipPropCallback[identifier] = true
	if(self.m_controls[identifier].controlValueToPropertyValue) then value = self.m_controls[identifier].controlValueToPropertyValue(value) end
	prop:SetValue(value)
	self.m_skipPropCallback[identifier] = nil
end
function gui.PFMControlsMenu:AddHeader(title)
	local header = gui.create("WIEditableEntry",self)
	header:SetEmpty()
	header:SetCategory(title)
	return header
end
function gui.PFMControlsMenu:AddSubMenu()
	local el = gui.create("WIPFMControlsMenu",self)
	el:SetAutoSizeToContents(true)
	el:SetAutoFillContentsToHeight(false)
	table.insert(self.m_subMenus,el)
	return el
end
function gui.PFMControlsMenu:ResetControls()
	for _,el in ipairs(self.m_subMenus) do
		el:ResetControls()
	end
	for name,ctrl in pairs(self.m_controls) do
		if(ctrl.element:IsValid()) then
			if(ctrl.default ~= nil) then
				self:SetValue(name,ctrl.default)
				if(ctrl.element:GetClass() == "wipfmslider") then ctrl.element:ResetToDefault() end
			end
		end
	end
end
gui.register("WIPFMControlsMenu",gui.PFMControlsMenu)

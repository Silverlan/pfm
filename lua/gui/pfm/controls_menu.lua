--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")

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
	self:CallCallbacks("OnControlAdded",name,ctrl,wrapper)
end
function gui.PFMControlsMenu:GetControl(name) return (self.m_controls[name] ~= nil) and self.m_controls[name].element or nil end
function gui.PFMControlsMenu:SetControlVisible(identifier,visible)
	local elData = self.m_controls[identifier]
	if(elData == nil) then return end
	local el = (elData.wrapper ~= nil) and elData.wrapper or elData.element
	if(util.is_valid(el) == false) then return end
	el:SetVisible(visible)
end
function gui.PFMControlsMenu:AddFileEntry(name,identifier,callback)
	local el = gui.create("WIFileEntry",self)
	if(callback ~= nil) then el:SetBrowseHandler(callback) end
	el:SetTooltip(locale.get_text(name .. "_desc"))
	local wrapper = el:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text(name))
	if(identifier ~= nil) then self:AddControl(identifier,el,wrapper) end
	return el
end
function gui.PFMControlsMenu:AddToggleControl(name,identifier,checked,onChange)
	local el = gui.create("WIToggleOption",self)
	el:SetText(locale.get_text(name))
	el:SetChecked(checked)
	el:SetTooltip(locale.get_text(name .. "_desc"))
	if(onChange ~= nil) then el:GetCheckbox():AddCallback("OnChange",onChange) end
	if(identifier ~= nil) then self:AddControl(identifier,el) end
	return el
end
function gui.PFMControlsMenu:AddSliderControl(name,identifier,default,min,max,onChange,stepSize,integer)
	local slider = gui.create("WIPFMSlider",self)
	slider:SetText(locale.get_text(name))
	slider:SetRange(min,max)
	slider:SetDefault(default)
	if(integer ~= nil) then slider:SetInteger(integer) end
	if(stepSize ~= nil) then slider:SetStepSize(stepSize) end
	if(onChange ~= nil) then slider:AddCallback("OnLeftValueChanged",onChange) end
	if(identifier ~= nil) then self:AddControl(identifier,slider,nil,default) end
	return slider
end
function gui.PFMControlsMenu:AddDropDownMenu(name,identifier,options,defaultOption,onChange)
	local menu = gui.create("WIDropDownMenu",self)
	for _,option in pairs(options) do
		menu:AddOption(option[2],option[1])
	end
	local wrapper = menu:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text(name))
	if(onChange ~= nil) then menu:AddCallback("OnOptionSelected",onChange) end
	if(identifier ~= nil) then self:AddControl(identifier,menu,wrapper,defaultOption) end
	return menu,wrapper
end
function gui.PFMControlsMenu:AddColorField(name,identifier,defaultOption,onChange)
	local colorEntry = gui.create("WIPFMColorEntry",self)
	if(onChange ~= nil) then colorEntry:GetColorProperty():AddCallback(onChange) end
	local colorEntryWrapper = colorEntry:Wrap("WIEditableEntry")
	colorEntryWrapper:SetText(locale.get_text(name))
	if(identifier ~= nil) then self:AddControl(identifier,colorEntry,colorEntryWrapper,defaultOption) end
	colorEntry:SetColor(defaultOption)
	return colorEntry,colorEntryWrapper
end
function gui.PFMControlsMenu:AddHeader(title)
	local header = gui.create("WIEditableEntry",self)
	header:SetEmpty()
	header:SetCategory(locale.get_text(title))
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
				if(ctrl.element:GetClass() == "widropdownmenu") then ctrl.element:SelectOption(ctrl.default)
				elseif(ctrl.element:GetClass() == "wipfmslider") then
					ctrl.element:SetDefault(ctrl.default)
					ctrl.element:ResetToDefault()
				elseif(ctrl.element:GetClass() == "wipfmcolorentry") then ctrl.element:SetColor(ctrl.default)
				else ctrl.element:SetValue(ctrl.default) end
			end
		end
	end
end
gui.register("WIPFMControlsMenu",gui.PFMControlsMenu)

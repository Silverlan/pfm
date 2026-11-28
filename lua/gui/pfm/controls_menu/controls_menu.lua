-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/controls/slider.lua")
include("/gui/controls/file_entry.lua")
include("/gui/controls/editable_entry.lua")

local Element = util.register_class("gui.PFMControlContainer", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetAutoSizeToContents(true)
	self:AddStyleClass("input-control-container")

	local container = gui.create_hbox(self)
	container:AddStyleClass("input-control-wrapper__content-area")
	self.m_container = container
end
function Element:InitializeIconContainer()
	if util.is_valid(self.m_iconContainer) then
		return self.m_iconContainer
	end
	local el = gui.create_hbox(self.m_container)
	el:AddStyleClass("property-control__icon-container")
	self.m_iconContainer = el
	return el
end
function Element:AddIcon(elIcon)
	self:InitializeIconContainer()
	elIcon:SetParent(self.m_iconContainer)
end
function Element:SetTargetElement(el)
	el:SetParent(self.m_container)
	self.m_targetElement = el
end
gui.register("pfm_control_container", Element)

util.register_class("gui.PFMControlsMenu", gui.Base)

include("control_wrappers.lua")

function gui.PFMControlsMenu:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	self:AddStyleClass("input-control-panel")

	self.m_controlContainer = gui.create_vbox(self)
		:AddStyleClass("input-control-panel__content-area")
	self.m_controls = {}
	self.m_orderedControlNames = {}
	self.m_subMenus = {}
	self.m_subMenuNameIndices = {}
	self:SetAutoSizeToContents(false, true)
end
function gui.PFMControlsMenu:GetControlCount()
	local n = 0
	for name, data in pairs(self.m_controls) do
		if data.element:IsValid() then
			n = n + 1
		end
	end
	return n
end
function gui.PFMControlsMenu:AddControl(name, ctrl, wrapper, default, container)
	self.m_controls[name] = {
		element = ctrl,
		wrapper = wrapper,
		container = container,
		default = default,
	}
	table.insert(self.m_orderedControlNames, name)
	if default ~= nil then
		self:SetDefault(name, default)
	end
	self:CallCallbacks("OnControlAdded", name, ctrl, wrapper)
end
function gui.PFMControlsMenu:SetControlEnabled(name, enabled)
	if self.m_controls[name] == nil then
		return
	end
	local wrapper = self.m_controls[name].wrapper
	if util.is_valid(wrapper) == false then
		return
	end
	if enabled then
		util.remove(self.m_controls[name].disabledOverlay)
		return
	end
	if util.is_valid(self.m_controls[name].disabledOverlay) then
		return
	end
	local el = gui.create("WIBase", wrapper, 0, 0, wrapper:GetWidth(), wrapper:GetHeight(), 0, 0, 1, 1)
	el:AddStyleClass("input-field__disabled-overlay")
	el:SetMouseInputEnabled(true)
	el:AddCallback("OnMouseEvent", function()
		return util.EVENT_REPLY_HANDLED
	end) -- Trap mouse input
	self.m_controls[name].disabledOverlay = el
end
function gui.PFMControlsMenu:ClearControls()
	for identifier, data in pairs(self.m_controls) do
		util.remove(data.container)
		util.remove(data.wrapper)
		util.remove(data.element)
	end
	self.m_controls = {}
	self.m_orderedControlNames = {}
	util.remove(self.m_subMenus)
	self.m_subMenus = {}
	self.m_subMenuNameIndices = {}
end
function gui.PFMControlsMenu:GetControl(name)
	if self.m_subMenuNameIndices[name] ~= nil then
		return self.m_subMenus[self.m_subMenuNameIndices[name]]
	end
	return (self.m_controls[name] ~= nil) and self.m_controls[name].element or nil
end
function gui.PFMControlsMenu:SetControlVisible(identifier, visible)
	local elData = self.m_controls[identifier]
	if elData == nil then
		return
	end
	local el = elData.container or elData.wrapper or elData.element
	if util.is_valid(el) == false then
		return
	end
	el:SetVisible(visible)
end
local function apply_tooltip(el, loc)
	if util.get_type_name(loc) ~= "LocStr" then
		return
	end
	local locId = loc:GetLocaleIdentifier() .. "_desc"
	local result, str = locale.get_text(locId, true)
	if result == false then
		return
	end
	el:SetTooltip(str)
end
local function apply_text(el, loc)
	if util.get_type_name(loc) ~= "LocStr" then
		el:SetText(loc)
		return
	end
	el:SetText(loc:GetText())
end
function gui.PFMControlsMenu:AddContainer(el)
	local container = gui.create("pfm_control_container", self.m_controlContainer)
	container:SetTargetElement(el)
	return container
end
function gui.PFMControlsMenu:AddFileEntry(name, identifier, default, browseHandler, callback)
	local el = gui.create("file_entry")
	local c = self:AddContainer(el)
	el:AddCallback("OnValueChanged", function(...)
		self:OnValueChanged(identifier, el:GetValue())
		if callback ~= nil then
			callback(...)
		end
	end)
	if browseHandler ~= nil then
		el:SetBrowseHandler(browseHandler)
	end
	apply_tooltip(el, name)
	local wrapper = el:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, el, wrapper, default, c)
	end
	return el, wrapper, c
end
function gui.PFMControlsMenu:AddInfo(name, identifier)
	local el = gui.create("WIBase")
	local c = self:AddContainer(el)
	apply_tooltip(el, name)

	local wrapper = el:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, el, wrapper, name, c)
	end
	return el, wrapper, c
end
function gui.PFMControlsMenu:AddText(name, identifier, default)
	local el = gui.create("WIText")
	local c = self:AddContainer(el)
	apply_tooltip(el, name)
	el:SetText(default)

	local wrapper = el:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, el, wrapper, default, c)
	end
	return el, wrapper, c
end
function gui.PFMControlsMenu:AddTextEntry(name, identifier, default, callback)
	local el = gui.create("WITextEntry")
	local c = self:AddContainer(el)
	el:AddCallback("OnTextEntered", function(...)
		self:OnValueChanged(identifier, el:GetText())
		if callback ~= nil then
			callback(...)
		end
	end)
	apply_tooltip(el, name)
	local wrapper = el:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, el, wrapper, default, c)
	end
	return el, wrapper, c
end
function gui.PFMControlsMenu:AddToggleControl(name, identifier, checked, onChange)
	local el = gui.create("toggle_option")
	local c = self:AddContainer(el)
	apply_text(el, name)
	el:SetChecked(checked)
	apply_tooltip(el, name)

	local wrapper = el:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	el:GetCheckbox():AddCallback("OnChange", function(...)
		self:OnValueChanged(identifier, el:IsChecked())
		if onChange ~= nil then
			onChange(...)
		end
	end)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, el, wrapper, checked, c)
	end
	return el, wrapper, c
end
function gui.PFMControlsMenu:AddSliderControl(name, identifier, default, min, max, onChange, stepSize, integer)
	local slider = gui.create("pfm_slider")
	local c = self:AddContainer(slider)
	apply_text(slider, name)
	slider:SetRange(min, max)
	if integer ~= nil then
		slider:SetInteger(integer)
	end
	if stepSize ~= nil then
		slider:SetStepSize(stepSize)
	end
	slider:AddCallback("OnLeftValueChanged", function(...)
		self:OnValueChanged(identifier, slider:GetValue())
		if onChange ~= nil then
			onChange(...)
		end
	end)
	if identifier ~= nil then
		slider:SetName(identifier)
		self:AddControl(identifier, slider, nil, default, c)
	end
	return slider, nil, c
end
function gui.PFMControlsMenu:AddDropDownMenu(name, identifier, options, defaultOption, onChange)
	local menu = gui.create("WIDropDownMenu")
	local c = self:AddContainer(menu)
	for _, option in pairs(options) do
		local text = option[2]
		if(util.get_type_name(text) ~= "Loc") then text = tostring(text) end
		menu:AddOption(text, tostring(option[1]))
	end
	local wrapper = menu:Wrap("editable_entry")
	c:SetTargetElement(wrapper)
	apply_text(wrapper, name)
	menu:AddCallback("OnOptionSelected", function(...)
		self:OnValueChanged(identifier, menu:GetOptionValue(menu:GetSelectedOption()))
		if onChange ~= nil then
			onChange(...)
		end
	end)
	if identifier ~= nil then
		wrapper:SetName(identifier)
		self:AddControl(identifier, menu, wrapper, defaultOption, c)
	end
	return menu, wrapper, c
end
function gui.PFMControlsMenu:AddColorField(name, identifier, defaultOption, onChange)
	local colorEntry = gui.create("pfm_color_entry")
	local c = self:AddContainer(colorEntry)
	local colorEntryWrapper = colorEntry:Wrap("editable_entry")
	c:SetTargetElement(colorEntryWrapper)
	apply_text(colorEntryWrapper, name)
	if identifier ~= nil then
		colorEntryWrapper:SetName(identifier)
		self:AddControl(identifier, colorEntry, colorEntryWrapper, defaultOption, c)
	end
	colorEntry:SetColor(defaultOption)
	colorEntry:GetColorProperty():AddCallback(function(...)
		self:OnValueChanged(identifier, colorEntry:GetValue())
		if onChange ~= nil then
			onChange(...)
		end
	end)
	return colorEntry, colorEntryWrapper, c
end
function gui.PFMControlsMenu:AddButton(name, identifier, onPress)
	local bt = gui.create("pfm_button")
	local c = self:AddContainer(bt)
	apply_text(bt, name)
	bt:ScheduleUpdate()
	if onPress ~= nil then
		bt:AddCallback("OnPressed", onPress)
	end
	if identifier ~= nil then
		bt:SetName(identifier)
		self:AddControl(identifier, bt, nil, nil, c)
	end
	return bt, nil, c
end
function gui.PFMControlsMenu:SetDefault(identifier, default)
	if self.m_controls[identifier] == nil then
		return
	end
	self.m_controls[identifier].default = default
	-- local el = self.m_controls[identifier].element
	-- if(util.is_valid(el) and el:IsType(gui.TYPE_PFM_SLIDER)) then el:SetDefault(default) end
end
function gui.PFMControlsMenu:SetValue(identifier, value)
	local ctrl = self.m_controls[identifier]
	if util.is_valid(ctrl.element) == false then
		return
	end
	if ctrl.element:IsType(gui.TYPE_WIDROPDOWNMENU) then
		ctrl.element:SelectOption(value)
	elseif ctrl.element:IsType(gui.TYPE_PFM_SLIDER) then
		ctrl.element:SetDefault(value)
	elseif ctrl.element:IsType(gui.TYPE_PFM_COLOR_ENTRY) then
		ctrl.element:SetColor(value)
	elseif ctrl.element:IsType(gui.TYPE_WITEXTENTRY) or ctrl.element:IsType(gui.TYPE_WITEXT) then
		ctrl.element:SetText(tostring(value))
	elseif ctrl.element:IsType(gui.TYPE_TOGGLE_OPTION) then
		ctrl.element:SetChecked(value)
	elseif ctrl.element:IsType(gui.TYPE_WIBASE) then
		apply_text(ctrl.wrapper, value)
	else
		ctrl.element:SetValue(value)
	end
end
function gui.PFMControlsMenu:LinkToUDMProperty(identifier, o, propName, translateControlValue, translatePropertyValue)
	local default = o:GetPropertyValue(propName)

	local el = self.m_controls[identifier].element
	local isDropDownMenu = (util.is_valid(el) and el:IsType(gui.TYPE_WIDROPDOWNMENU))
	if isDropDownMenu then
		default = tostring(default)
	end

	o:AddChangeListener(propName, function(newValue)
		if self.m_skipPropCallback ~= nil and self.m_skipPropCallback[identifier] == true then
			return
		end
		if isDropDownMenu then
			newValue = tostring(newValue)
		end
		if translatePropertyValue then
			newValue = translatePropertyValue(newValue)
		end
		self:SetValue(identifier, newValue)
	end)

	self:SetDefault(identifier, default)
	self.m_controls[identifier].parentProperty = o
	self.m_controls[identifier].propertyName = propName
	self.m_controls[identifier].controlValueToPropertyValue = translateControlValue
end
function gui.PFMControlsMenu:OnValueChanged(identifier, value)
	if self.m_controls[identifier] == nil or self.m_controls[identifier].propertyName == nil then
		return
	end

	local parent = self.m_controls[identifier].parentProperty
	local propName = self.m_controls[identifier].propertyName
	local udmType = parent:GetPropertyUdmType(propName)
	if udmType == udm.TYPE_INVALID and udm.Schema.is_enum_type(parent:GetPropertyType(propName)) then
		udmType = udm.TYPE_INT32
	end
	if self.m_controls[identifier].controlValueToPropertyValue then
		value = self.m_controls[identifier].controlValueToPropertyValue(value)
	elseif udmType ~= udm.TYPE_INVALID then
		if udmType == udm.TYPE_BOOLEAN then
			value = toboolean(value)
		elseif udm.is_integral_type(udmType) then
			value = toint(value)
		elseif udm.is_floating_point_type(udmType) then
			value = tonumber(value)
		end
	end

	self.m_skipPropCallback = self.m_skipPropCallback or {}
	self.m_skipPropCallback[identifier] = true
	parent:SetPropertyValue(propName, value)
	self.m_skipPropCallback[identifier] = nil
end
function gui.PFMControlsMenu:AddHeader(title)
	local header = gui.create("editable_entry", self.m_controlContainer)
	header:SetEmpty()
	header:SetCategory(title)
	return header
end
function gui.PFMControlsMenu:AddCollapsibleSubMenu(title, identifier)
	local collapsible = gui.create("collapsible_group", self.m_controlContainer)
	collapsible:SetGroupName(title)
	collapsible:Expand()
	local elSubMenu = self:AddSubMenu(identifier, collapsible:GetContents())
	return elSubMenu, collapsible
end
function gui.PFMControlsMenu:SetAutoFillContentsToWidth(autoFill)
	-- self.m_controlContainer:SetAutoFillContentsToWidth(autoFill)
end
function gui.PFMControlsMenu:SetAutoFillContentsToHeight(autoFill)
	-- self.m_controlContainer:SetAutoFillContentsToHeight(autoFill)
end
function gui.PFMControlsMenu:SetFixedWidth(fixedWidth)
	--self.m_controlContainer:SetFixedWidth(fixedWidth)
end
function gui.PFMControlsMenu:SetFixedHeight(fixedHeight)
	--self.m_controlContainer:SetFixedHeight(fixedHeight)
end
function gui.PFMControlsMenu:AddSubMenu(identifier, parent)
	parent = parent or self
	local el = gui.create("pfm_controls_menu", parent)

	table.insert(self.m_subMenus, el)
	if identifier ~= nil then
		el:SetName(identifier)
		self.m_subMenuNameIndices[identifier] = #self.m_subMenus
	end
	return el
end
function gui.PFMControlsMenu:ResetControls()
	for _, name in ipairs(self.m_orderedControlNames) do
		local ctrl = self.m_controls[name]
		if ctrl.element:IsValid() then
			if ctrl.default ~= nil then
				self:SetValue(name, ctrl.default)
				if ctrl.element:IsType(gui.TYPE_PFM_SLIDER) then
					ctrl.element:ResetToDefault()
				end
			end
		end
	end
	for _, el in ipairs(self.m_subMenus) do
		el:ResetControls()
	end
end
gui.register("pfm_controls_menu", gui.PFMControlsMenu)

-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local ButtonGroup = util.register_class("gui.PFMButtonGroup")
function ButtonGroup:__init(hbox, tabButtons)
	self.m_hbox = hbox
	self.m_tabButtons = tabButtons or false
	self.m_buttons = {}
end
function ButtonGroup:AddIconButton(icon, onPressed)
	local bt = gui.PFMButton.create(self.m_hbox, icon, onPressed)
	self:AddButton(bt)
	return bt
end
function ButtonGroup:AddGenericButton(text, onPressed)
	local bt = gui.create("pfm_button", self.m_hbox)
	bt:SetText(text)
	bt:AddCallback("OnPressed", onPressed)
	self:AddButton(bt)
	return bt
end
function ButtonGroup:AddButton(bt)
	local newButtons = {}
	for _,bt in ipairs(self.m_buttons) do
		if(bt:IsValid()) then
			table.insert(newButtons, bt)
		end
	end
	self.m_buttons = newButtons

	if #self.m_buttons == 0 then
		bt:SetType(self.m_tabButtons and gui.PFMButton.BUTTON_TYPE_TAB or gui.PFMButton.BUTTON_TYPE_NORMAL)
	else
		if #self.m_buttons == 1 then
			self.m_buttons[1]:SetType(
				self.m_tabButtons and gui.PFMButton.BUTTON_TYPE_TAB_LEFT or gui.PFMButton.BUTTON_TYPE_LEFT
			)
		end
		bt:SetType(self.m_tabButtons and gui.PFMButton.BUTTON_TYPE_TAB_RIGHT or gui.PFMButton.BUTTON_TYPE_RIGHT)
		if #self.m_buttons > 1 then
			self.m_buttons[#self.m_buttons]:SetType(
				self.m_tabButtons and gui.PFMButton.BUTTON_TYPE_TAB_MIDDLE or gui.PFMButton.BUTTON_TYPE_MIDDLE
			)
		end
	end
	table.insert(self.m_buttons, bt)
	return bt
end

local Element = util.register_class("gui.PFMBaseButton", gui.Base)
Element.BUTTON_TYPE_NORMAL = 0
Element.BUTTON_TYPE_LEFT = 1
Element.BUTTON_TYPE_RIGHT = 2
Element.BUTTON_TYPE_MIDDLE = 3
Element.BUTTON_TYPE_TAB_LEFT = 4
Element.BUTTON_TYPE_TAB_RIGHT = 5
Element.BUTTON_TYPE_TAB_MIDDLE = 6
Element.BUTTON_TYPE_TAB = 7
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetAutoSizeToContents(true, false)
	self:AddStyleClass("button")
	local contents = gui.create_hbox(self)
		:AddStyleClass("button__content-area")
	self.m_contents = contents

	self:SetType(gui.PFMBaseButton.BUTTON_TYPE_NORMAL)
end
function Element:SetText(text)
	if util.is_valid(self.m_text) == false then
		self.m_text = gui.create("WIText", self.m_contents)
		self.m_text:AddStyleClass("button__text")
	end
	self.m_text:SetText(text)
end
function Element:GetText()
	return self.m_text:GetText()
end
function Element:SetType(type)
	self.m_type = type
	self:UpdateStyle()
end
function Element:GetType()
	return self.m_type or gui.PFMBaseButton.BUTTON_TYPE_NORMAL
end
function Element:SetIcon(icon)
	if util.is_valid(self.m_icon) == false then
		local elIcon = gui.create("WITexturedRect", self.m_contents)
		elIcon:AddStyleClass("button__icon")
		self.m_icon = elIcon
	end
	if(self.m_curIcon ~= nil) then
		self.m_icon:RemoveStyleClass("button__icon--" .. self.m_curIcon)
	end
	self.m_curIcon = icon
	self.m_icon:AddStyleClass("button__icon--" .. icon)
	self.m_icon:RefreshSkin()
end
function Element:UpdateStyle()
	for _, c in ipairs({
		"button--standalone",
		"button--left",
		"button--right",
		"button--middle",
		"button-tab--left",
		"button-tab--right",
		"button-tab--middle",
		"button-tab--standalone",
	}) do
		self:RemoveStyleClass(c)
	end

	local type = self:GetType()
	local isTab = false
	if type == Element.BUTTON_TYPE_LEFT then
		self:AddStyleClass("button--left")
	elseif type == Element.BUTTON_TYPE_RIGHT then
		self:AddStyleClass("button--right")
	elseif type == Element.BUTTON_TYPE_MIDDLE then
		self:AddStyleClass("button--middle")
	else
		isTab = true
		if type == Element.BUTTON_TYPE_TAB_LEFT then
			self:AddStyleClass("button-tab--left")
		elseif type == Element.BUTTON_TYPE_TAB_RIGHT then
			self:AddStyleClass("button-tab--right")
		elseif type == Element.BUTTON_TYPE_TAB_MIDDLE then
			self:AddStyleClass("button-tab--middle")
		elseif type == Element.BUTTON_TYPE_TAB then
			self:AddStyleClass("button-tab--standalone")
		else
			isTab = false
			self:AddStyleClass("button--standalone")
		end
	end
	if isTab then self:AddStyleClass("button-tab")
	else self:RemoveStyleClass("button-tab") end
	self:RefreshSkin()
end
function Element:SetPressed(pressed)
	self.m_pressed = pressed
	self:SetState(gui.STATE_PRESSED, pressed)
	self:OnActiveStateChanged(pressed)
end
function Element:OnActiveStateChanged(pressed) end
function Element:IsPressed()
	return self.m_pressed or false
end
function Element:SizeToContents()
	local sz = self.m_text:GetWidth()
	self:SetWidth(sz)
end

util.register_class("gui.PFMButton", gui.PFMBaseButton)
gui.PFMButton.create = function(parent, matUnpressed, matPressed, onPressed)
	local bt = gui.create("pfm_button", parent)
	if type(matPressed) ~= "string" then
		bt:SetIcon(matUnpressed)
		onPressed = matPressed
	else
		bt:SetMaterials(matUnpressed, matPressed)
	end
	if onPressed ~= nil then
		bt:AddCallback("OnPressed", onPressed)
	end
	return bt
end

function gui.PFMButton:OnInitialize()
	gui.PFMBaseButton.OnInitialize(self)

	self:SetMouseInputEnabled(true)

	self.m_pressed = false
	self.m_enabled = true
end
function gui.PFMButton:SetEnabledStyleClass(styleClass)
	self.m_enabledStyleClass = styleClass
end
function gui.PFMButton:SetDisabledStyleClass(styleClass)
	self.m_disabledStyleClass = styleClass
end
function gui.PFMButton:SetEnabled(enabled)
	if enabled == self:IsEnabled() then
		return
	end
	if enabled == false then
		self:SetActivated(false)
	end
	self.m_enabled = enabled
	--[[if(enabled)  then
		if(self.m_enabledStyleClass ~= nil) then
			self:AddStyleClass(self.m_enabledStyleClass)
		end
		self:RemoveStyleClass(self.m_disabledStyleClass or "button_disabled")
	else
		if(self.m_enabledStyleClass ~= nil) then
			self:RemoveStyleClass(self.m_enabledStyleClass)
		end
		self:AddStyleClass(self.m_disabledStyleClass or "button_disabled")
	end
	self:RefreshSkin()]]
end
function gui.PFMButton:IsEnabled()
	return self.m_enabled
end
function gui.PFMButton:IsActivated()
	return self.m_pressed
end
function gui.PFMButton:SetActivated(activated)
	if self:IsEnabled() == false then
		return
	end
	self.m_pressed = activated
	self:SetPressed(activated)
	self:SetMaterial(activated and self.m_pressedMaterial or self.m_unpressedMaterial)
end
function gui.PFMButton:SetPressedMaterial(mat)
	self.m_pressedMaterial = mat
	if self:IsActivated() then
		self:SetMaterial(mat)
	end
end
function gui.PFMButton:SetUnpressedMaterial(mat)
	self.m_unpressedMaterial = mat
	if self:IsActivated() == false then
		self:SetMaterial(mat)
	end
end
function gui.PFMButton:SetMaterials(unpressedMat, pressedMat)
	self.m_unpressedMaterial = unpressedMat
	self.m_pressedMaterial = pressedMat
	self:SetMaterial(self.m_pressed and pressedMat or unpressedMat)
	local mat = game.load_material(unpressedMat)
	if mat == nil then
		return
	end
	local texInfo = mat:GetTextureInfo("diffuse_map")
	if texInfo == nil then
		return
	end
end
function gui.PFMButton:SetIcon(icon, updateSize)
	gui.PFMBaseButton.SetIcon(self, icon)
end
function gui.PFMButton:SetMaterial(mat)
	--[[if mat ~= nil and util.is_valid(self.m_button) then
		self.m_button:SetMaterial(mat)
	end]]
end
function gui.PFMButton:SetupContextMenu(fPopulateContextMenu, openOnClick)
	if util.is_valid(self.m_elCaret) == false then
		local caret = gui.create("WITexturedRect", self.m_contents)
		caret:SetMaterial("gui/pfm/icons/caret-down-fill")
		caret:AddStyleClass("button__icon")
		self.m_elCaret = caret
	end

	self.m_fPopulateContextMenu = fPopulateContextMenu
	self.m_contextTrigger = gui.create("WIBase", self.m_contents)
	self.m_contextTrigger:SetMouseInputEnabled(true)
	self.m_contextTrigger:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button ~= input.MOUSE_BUTTON_LEFT or self:IsEnabled() == false then
			return util.EVENT_REPLY_UNHANDLED
		end
		if state == input.STATE_PRESS then
			self:OpenContextMenu()
		end
		return util.EVENT_REPLY_HANDLED
	end)
	if openOnClick == true then
		self:AddCallback("OnPressed", function()
			self:OpenContextMenu()
		end)
	end
end
function gui.PFMButton:OpenContextMenu()
	if self.m_fPopulateContextMenu == nil then
		return
	end
	self:SetActivated(true)
	local pContext = gui.open_context_menu(self)
	if util.is_valid(pContext) == false then
		return
	end
	local pos = self:GetAbsolutePos()
	pContext:SetOriginPos(pos.x, pos.y + self:GetHeight())
	self.m_fPopulateContextMenu(pContext)
	self:CallCallbacks("PopulateContextMenu", pContext)
	pContext:Update()

	pContext:AddCallback("OnRemove", function()
		if self:IsValid() then
			self:SetActivated(false)
		end
	end)
end
function gui.PFMButton:OnPressed() end
function gui.PFMButton:MouseCallback(button, state, mods)
	if self:IsEnabled() == false then
		return util.EVENT_REPLY_UNHANDLED
	end
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			self:SetActivated(true)
		elseif state == input.STATE_RELEASE then
			if self:OnPressed() ~= true and self:CallCallbacks("OnPressed") ~= true and self:IsValid() then
				self:SetActivated(false)
			end
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("pfm_button", gui.PFMButton)

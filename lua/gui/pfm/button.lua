--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
	local bt = gui.create("WIPFMButton", self.m_hbox)
	bt:SetWidth(128)
	bt:SetText(text)
	bt:AddCallback("OnPressed", onPressed)
	self:AddButton(bt)
	return bt
end
function ButtonGroup:AddButton(bt)
	if #self.m_buttons == 0 then
		bt:SetType(self.m_tabButtons and gui.PFMButton.BUTTON_TYPE_NORMAL or gui.PFMButton.BUTTON_TYPE_TAB)
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

	self:SetSize(32, 26)
	local elBg = gui.create("WI9SliceRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_elBg = elBg

	--elBg:GetColorProperty():Link(self:GetColorProperty())
	self:SetType(gui.PFMBaseButton.BUTTON_TYPE_NORMAL)
end
function Element:SetText(text)
	if util.is_valid(self.m_text) == false then
		self.m_text = gui.create("WIText", self)
		self.m_text:SetFont("pfm_medium")
		self.m_text:SetColor(Color(152, 152, 152))
	end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParent()
	self.m_text:SetAnchor(0.5, 0.5, 0.5, 0.5)
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
		local elIcon = gui.create("WITexturedRect", self)
		elIcon:SetSize(18, 18)
		elIcon:SetMaterial("gui/pfm/cursor-fill")
		elIcon:CenterToParent()
		elIcon:SetAnchor(0.5, 0.5, 0.5, 0.5)
		elIcon:AddStyleClass("button_icon")
		self.m_icon = elIcon
	end
	self.m_icon:SetMaterial("gui/pfm/icons/" .. icon)
end
function Element:UpdateStyle()
	for _, c in ipairs({
		"button",
		"button_left",
		"button_right",
		"button_middle",
		"button_tab_left",
		"button_tab_right",
		"button_tab_middle",
		"button_tab",
	}) do
		self.m_elBg:RemoveStyleClass(c)
	end

	local type = self:GetType()
	if type == Element.BUTTON_TYPE_LEFT then
		self.m_elBg:AddStyleClass("button_left")
	elseif type == Element.BUTTON_TYPE_RIGHT then
		self.m_elBg:AddStyleClass("button_right")
	elseif type == Element.BUTTON_TYPE_MIDDLE then
		self.m_elBg:AddStyleClass("button_middle")
	elseif type == Element.BUTTON_TYPE_TAB_LEFT then
		self.m_elBg:AddStyleClass("button_tab_left")
	elseif type == Element.BUTTON_TYPE_TAB_RIGHT then
		self.m_elBg:AddStyleClass("button_tab_right")
	elseif type == Element.BUTTON_TYPE_TAB_MIDDLE then
		self.m_elBg:AddStyleClass("button_tab_middle")
	elseif type == Element.BUTTON_TYPE_TAB then
		self.m_elBg:AddStyleClass("button_tab")
	else
		self.m_elBg:AddStyleClass("button")
	end
	self:RefreshSkin()
end
function Element:SetPressed(pressed)
	self.m_pressed = pressed
	if pressed then
		self.m_elBg:RemoveStyleClass("button_background_unpressed")
		self.m_elBg:AddStyleClass("button_background_pressed")
	else
		self.m_elBg:RemoveStyleClass("button_background_pressed")
		self.m_elBg:AddStyleClass("button_background_unpressed")
	end
	self.m_elBg:RefreshSkin()
	self:OnActiveStateChanged(pressed)
end
function Element:OnActiveStateChanged(pressed) end
function Element:IsPressed()
	return self.m_pressed or false
end
local MIDDLE_SEGMENT_WIDTH = 24 -- Width of "gui/pfm/bt_middle"
function Element:CalcWidthWithMargin(requestSize)
	local size = requestSize
	local m = requestSize % MIDDLE_SEGMENT_WIDTH
	if m > 0 then
		size = size + (MIDDLE_SEGMENT_WIDTH - m)
	end
	return size, MIDDLE_SEGMENT_WIDTH
end
function Element:SizeToContents()
	local sz = self.m_text:GetWidth()
	local margin = 20
	local middleSize = sz + margin
	middleSize = self:CalcWidthWithMargin(middleSize)
	local totalSize = middleSize
	self:SetWidth(totalSize)
end

util.register_class("gui.PFMButton", gui.PFMBaseButton)
gui.PFMButton.create = function(parent, matUnpressed, matPressed, onPressed)
	local bt = gui.create("WIPFMButton", parent)
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
	self:SetSize(64, 30)

	self.m_pressed = false
	self.m_enabled = true
end
function gui.PFMButton:SetEnabledColor(col)
	self.m_enabledColor = col
end
function gui.PFMButton:SetDisabledColor(col)
	self.m_disabledColor = col
end
function gui.PFMButton:SetEnabled(enabled)
	if enabled == self:IsEnabled() then
		return
	end
	if enabled == false then
		self:SetActivated(false)
	end
	self.m_enabled = enabled
	local color = enabled and (self.m_enabledColor or Color.White) or (self.m_disabledColor or Color(128, 128, 128))
	self:SetColor(color)
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
	self:SetSize(texInfo:GetWidth(), texInfo:GetHeight())
end
function gui.PFMButton:SetIcon(icon)
	gui.PFMBaseButton.SetIcon(self, icon)
	self:SetSize(30, 30)
end
function gui.PFMButton:SetMaterial(mat)
	--[[if mat ~= nil and util.is_valid(self.m_button) then
		self.m_button:SetMaterial(mat)
	end]]
end
function gui.PFMButton:SetupContextMenu(fPopulateContextMenu, openOnClick)
	self.m_fPopulateContextMenu = fPopulateContextMenu
	local w = 12
	self.m_contextTrigger = gui.create("WIBase", self, self:GetWidth() - w, 0, w, self:GetHeight(), 1, 0, 1, 0)
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
	pContext:SetPos(pos.x, pos.y + self:GetHeight())
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
gui.register("WIPFMButton", gui.PFMButton)

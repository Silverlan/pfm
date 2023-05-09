--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.EditableEntry", gui.Base)

gui.get_delta_time = function()
	return time.frame_time()
end

function gui.EditableEntry:__init()
	gui.Base.__init(self)
end
function gui.EditableEntry:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 32)
	self.m_centerText = true

	self.m_descContainer = gui.create("WIBase", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	local pText = gui.create("WIText", self.m_descContainer)
	pText:AddStyleClass("input_field_text")
	self.m_pText = pText

	local cbOnChildAdded
	cbOnChildAdded = self:AddCallback("OnChildAdded", function(el, elChild)
		if self.m_empty then
			return
		end
		self.m_target = elChild
		if elChild:GetClass() == "witextentry" or elChild:GetClass() == "widropdownmenu" then
			elChild:AddCallback("OnTextChanged", function()
				self:UpdateText()
			end)
			elChild:AddCallback("OnMenuClosed", function(el)
				self.m_target:SetVisible(false)
			end)
			elChild:SetVisible(false)
		elseif elChild:GetClass() == "witext" then
			elChild:AddCallback("OnTextChanged", function()
				self:UpdateText()
			end)
			elChild:SetVisible(false)
		elseif elChild:GetClass() == "wipfmcolorentry" then
			self:RemoveStyleClass("input_field")
			self:AddStyleClass("input_field_outline")
			self.m_activeTarget = true
			self.m_descContainer:SetZPos(10)

			local function update_text_color()
				if self:IsValid() == false then
					return
				end
				if util.is_valid(self.m_pText) then
					self.m_pText:SetColor(elChild:GetColor():GetContrastColor())
				end
				self:UpdateText()
			end
			elChild:GetColorProperty():AddCallback(update_text_color)
			update_text_color()
		elseif elChild:GetClass() == "witoggleoption" then
			self.m_pText:SetVisible(false)
		elseif elChild:GetClass() == "wipfmslider" then
			elChild:AddCallback("OnLeftValueChanged", function()
				self:UpdateText()
			end)
			elChild:SetVisible(false)
		else
			elChild:AddCallback("OnValueChanged", function()
				self:UpdateText()
			end)
			elChild:SetVisible(false)
		end
		if util.is_valid(cbOnChildAdded) then
			cbOnChildAdded:Remove()
		end
	end)
	local cbOnChildRemoved
	cbOnChildRemoved = self:AddCallback("OnChildRemoved", function(el, elChild)
		if elChild == self.m_target then
			elChild:SetVisible(true)
			if util.is_valid(cbOnChildRemoved) then
				cbOnChildRemoved:Remove()
			end
		end
	end)
	self:SetMouseInputEnabled(true)

	self:SetText("")
	self:AddStyleClass("input_field")
end
function gui.EditableEntry:MouseCallback(button, state, mods)
	if button ~= input.MOUSE_BUTTON_LEFT and button ~= input.MOUSE_BUTTON_RIGHT then
		return util.EVENT_REPLY_UNHANDLED
	end
	if button == input.MOUSE_BUTTON_RIGHT then
		if state == input.STATE_RELEASE then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			self:CallCallbacks("PopulateContextMenu", pContext)
			pContext:Update()
			if pContext:IsPopulated() == false then
				return util.EVENT_REPLY_UNHANDLED
			end
		end
		return util.EVENT_REPLY_HANDLED
	end
	if state ~= input.STATE_PRESS then
		return util.EVENT_REPLY_UNHANDLED
	end
	if util.is_valid(self.m_target) then
		if self.m_target:GetClass() == "wipfmslider" then
			local isAltDown = input.get_key_state(input.KEY_LEFT_ALT) ~= input.STATE_RELEASE
				or input.get_key_state(input.KEY_RIGHT_ALT) ~= input.STATE_RELEASE
			if isAltDown then
				self:StartEditMode(true)
				return util.EVENT_REPLY_HANDLED
			end
		end
		if self.m_presetValues ~= nil and #self.m_presetValues > 0 then
			local numOptions = #self.m_presetValues
			local option = self.m_curPresetOption or 0
			if button == input.MOUSE_BUTTON_LEFT then
				if option == -1 or option == numOptions - 1 then
					option = 0
				else
					option = option + 1
				end
			else
				if option == -1 or option == 0 then
					option = numOptions - 1
				else
					option = option - 1
				end
			end
			self.m_skipTextUpdate = true
			self.m_target:SetValue(self.m_presetValues[option + 1][1])
			self.m_skipTextUpdate = nil

			self:UpdateText(self.m_presetValues[option + 1][2])
			self.m_curPresetOption = option
			return util.EVENT_REPLY_HANDLED
		end
		if self.m_target:GetClass() == "widropdownmenu" then
			if self.m_useAltMode then
				self.m_target:SetVisible(true)
				self.m_target:OpenMenu()
			else
				local isAltDown = input.get_key_state(input.KEY_LEFT_ALT) ~= input.STATE_RELEASE
					or input.get_key_state(input.KEY_RIGHT_ALT) ~= input.STATE_RELEASE
				if self.m_target:IsEditable() and isAltDown then
					self:StartEditMode(true)
					return util.EVENT_REPLY_HANDLED
				elseif isAltDown then
					button = input.MOUSE_BUTTON_RIGHT
				end
				local numOptions = self.m_target:GetOptionCount()
				local option = self.m_target:GetSelectedOption()
				if button == input.MOUSE_BUTTON_LEFT then
					if option == -1 or option == numOptions - 1 then
						option = 0
					else
						option = option + 1
					end
				else
					if option == -1 or option == 0 then
						option = numOptions - 1
					else
						option = option - 1
					end
				end
				self.m_target:SelectOption(option)
			end
			return util.EVENT_REPLY_HANDLED
		end
	end
	if button == input.MOUSE_BUTTON_LEFT and self.m_empty ~= true then
		if util.is_valid(self.m_target) and self.m_activeTarget == true then
			return util.EVENT_REPLY_UNHANDLED
		end
		self:StartEditMode(true)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.EditableEntry:SetUseAltMode(altMode)
	self.m_useAltMode = altMode
end
function gui.EditableEntry:SetCategory(text)
	self:SetEmpty()
	self:SetText(text)
	self:AddStyleClass("input_field_category")
end
function gui.EditableEntry:SetEmpty()
	self.m_target = nil
	self.m_empty = true
end
function gui.EditableEntry:OnThink()
	local endEditMode = true
	local elFocus = gui.get_focused_element()
	if
		util.is_valid(self.m_target)
		and util.is_valid(elFocus)
		and (elFocus == self.m_target or elFocus:IsDescendantOf(self.m_target))
	then
		endEditMode = false
	end
	if endEditMode then
		self:StartEditMode(false)
	end
end
function gui.EditableEntry:StartEditMode(enabled)
	if self.m_activeTarget then
		return
	end
	if util.is_valid(self.m_target) and self.m_target:GetClass() == "witext" then
		return
	end
	self:SetThinkingEnabled(enabled)
	self.m_descContainer:SetVisible(not enabled)
	if util.is_valid(self.m_target) then
		if self.m_target:GetClass() ~= "witoggleoption" then
			self.m_target:SetVisible(enabled)
		end
		if enabled then
			self.m_target:RequestFocus()
		end
	end
end
function gui.EditableEntry:SetText(text)
	self.m_baseText = text
	self:UpdateText()
end
function gui.EditableEntry:SetCenterText(center)
	self.m_centerText = center or false
	self:UpdateText()
end
function gui.EditableEntry:UpdateText(value)
	if self.m_skipTextUpdate or util.is_valid(self.m_pText) == false then
		return
	end
	local text = self.m_baseText
	if value == nil then
		self.m_curPresetOption = nil
		if util.is_valid(self.m_target) then
			text = text .. ": "
			if self.m_target:GetClass() == "widropdownmenu" then
				local selectedOption = self.m_target:GetSelectedOption()
				if selectedOption ~= -1 then
					value = self.m_target:GetOptionText(selectedOption)
				else
					value = self.m_target:GetText()
				end
			elseif self.m_target:GetClass() == "witoggleoption" then
				value = self.m_target:IsChecked() and "1" or "0"
			elseif self.m_target:GetClass() == "witext" then
				value = self.m_target:GetText()
			else
				value = tostring(self.m_target:GetValue())
			end
			if #value == 0 then
				value = "-"
			end
		else
			value = ""
		end
	else
		text = text .. ": "
	end

	local handled, newValueText = self:CallCallbacks("TranslateValueText", value)
	if handled == util.EVENT_REPLY_HANDLED then
		value = newValueText
	end

	text = text .. value
	self.m_pText:SetText(text)
	self.m_pText:SizeToContents()
	if self.m_centerText then
		self.m_pText:CenterToParent(true)
	else
		self.m_pText:ClearAnchor()
		self.m_pText:SetX(5)
		self.m_pText:CenterToParentY()
	end

	self:CallCallbacks("OnValueChanged")
end
function gui.EditableEntry:SetPresetValues(values)
	self.m_presetValues = values
end
gui.register("WIEditableEntry", gui.EditableEntry)

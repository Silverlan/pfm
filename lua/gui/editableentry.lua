--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.EditableEntry",gui.Base)

gui.get_delta_time = function()
	return time.frame_time()
end

function gui.EditableEntry:__init()
	gui.Base.__init(self)
end
function gui.EditableEntry:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,32)

	self.m_descContainer = gui.create("WIBase",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	local pText = gui.create("WIText",self.m_descContainer)
	pText:AddStyleClass("input_field_text")
	self.m_pText = pText

	local cbOnChildAdded
	cbOnChildAdded = self:AddCallback("OnChildAdded",function(el,elChild)
		if(self.m_empty) then return end
		self.m_target = elChild
		elChild:SetVisible(false)
		if(elChild:GetClass() == "witextentry" or elChild:GetClass() == "widropdownmenu") then
			elChild:AddCallback("OnTextChanged",function()
				self:UpdateText()
			end)
		else
			elChild:AddCallback("OnValueChanged",function()
				self:UpdateText()
			end)
		end
		if(util.is_valid(cbOnChildAdded)) then cbOnChildAdded:Remove() end
	end)
	local cbOnChildRemoved
	cbOnChildRemoved = self:AddCallback("OnChildRemoved",function(el,elChild)
		if(elChild == self.m_target) then
			elChild:SetVisible(true)
			if(util.is_valid(cbOnChildRemoved)) then cbOnChildRemoved:Remove() end
		end
	end)
	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMouseEvent",function(pFilmClip,button,state,mods)
		if(state ~= input.STATE_PRESS or (button ~= input.MOUSE_BUTTON_LEFT and button ~= input.MOUSE_BUTTON_RIGHT)) then return util.EVENT_REPLY_UNHANDLED end
		if(util.is_valid(self.m_target) and self.m_target:GetClass() == "widropdownmenu") then
			local isAltDown = input.get_key_state(input.KEY_LEFT_ALT) ~= input.STATE_RELEASE or
				input.get_key_state(input.KEY_RIGHT_ALT) ~= input.STATE_RELEASE
			if(self.m_target:IsEditable() and isAltDown) then
				self:StartEditMode(true)
				return util.EVENT_REPLY_HANDLED
			end
			local numOptions = self.m_target:GetOptionCount()
			local option = self.m_target:GetSelectedOption()
			if(button == input.MOUSE_BUTTON_LEFT) then
				if(option == -1 or option == numOptions -1) then option = 0
				else option = option +1 end
			else
				if(option == -1 or option == 0) then option = numOptions -1
				else option = option -1 end
			end
			self.m_target:SelectOption(option)
			return util.EVENT_REPLY_HANDLED
		end
		if(button == input.MOUSE_BUTTON_LEFT) then
			self:StartEditMode(true)
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	self:SetText("")
	self:AddStyleClass("input_field")
end
function gui.EditableEntry:SetEmpty()
	self.m_target = nil
	self.m_empty = true
end
function gui.EditableEntry:OnThink()
	local endEditMode = true
	local elFocus = gui.get_focused_element()
	if(util.is_valid(self.m_target) and util.is_valid(elFocus) and (elFocus == self.m_target or elFocus:IsDescendantOf(self.m_target))) then
		endEditMode = false
	end
	if(endEditMode) then self:StartEditMode(false) end
end
function gui.EditableEntry:StartEditMode(enabled)
	self:SetThinkingEnabled(enabled)
	self.m_descContainer:SetVisible(not enabled)
	if(util.is_valid(self.m_target)) then
		self.m_target:SetVisible(enabled)
		if(enabled) then
			self.m_target:RequestFocus()
		end
	end
end
function gui.EditableEntry:SetText(text)
	self.m_baseText = text
	self:UpdateText()
end
function gui.EditableEntry:UpdateText()
	if(util.is_valid(self.m_pText) == false) then return end
	local text = self.m_baseText
	local value
	if(util.is_valid(self.m_target)) then
		text = text .. ": "
		if(self.m_target:GetClass() == "widropdownmenu") then
			local selectedOption = self.m_target:GetSelectedOption()
			if(selectedOption ~= -1) then value = self.m_target:GetOptionText(selectedOption)
			else value = self.m_target:GetText() end
		else value = self.m_target:GetValue() end
		if(#value == 0) then value = "-" end
	else value = "" end
	text = text .. value
	self.m_pText:SetText(text)
	self.m_pText:SizeToContents()
	self.m_pText:CenterToParent(true)
end
gui.register("WIEditableEntry",gui.EditableEntry)

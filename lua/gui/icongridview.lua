--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/gridbox.lua")
include("/gui/asseticon.lua")

util.register_class("gui.IconGridView",gui.Base)
function gui.IconGridView:__init()
	gui.Base.__init(self)
end
function gui.IconGridView:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(64,64)

	self.m_iconContainer = gui.create("WIGridBox",self)
	self.m_icons = {}
	self.m_selected = {}
	self:SetAutoSizeToContents(false,true)

	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetIconFactory(function(parent)
		return gui.create("WIImageIcon",parent)
	end)
end
function gui.IconGridView:SetIconFactory(factory) self.m_iconFactory = factory end
function gui.IconGridView:OnSizeChanged(w,h)
	if(util.is_valid(self.m_iconContainer)) then self.m_iconContainer:SetWidth(w) end
end
function gui.IconGridView:DeselectAll()
	for el,_ in pairs(self.m_selected) do
		if(el:IsValid()) then self:SetIconSelected(el,false) end
	end
	self.m_selected = {}
end
function gui.IconGridView:SelectAll()
	for _,el in ipairs(self.m_icons) do
		if(el:IsValid()) then
			self:SetIconSelected(el)
		end
	end
end
function gui.IconGridView:FindIconIndex(el)
	for i,elOther in ipairs(self.m_icons) do
		if(util.is_same_object(el,elOther)) then return i end
	end
end
function gui.IconGridView:SelectRange(from,to)
	local ifrom = self:FindIconIndex(from)
	local ito = self:FindIconIndex(to)
	if(ifrom == nil or ito == nil) then return end
	for i=ifrom,ito do
		local el = self.m_icons[i]
		if(el:IsValid()) then
			self:SetIconSelected(el)
		end
	end
end
function gui.IconGridView:SetIconSelected(icon,selected)
	if(selected == nil) then selected = true end
	if((selected and self.m_selected[icon]) or (not selected and self.m_selected[icon] == nil)) then return end
	icon:SetSelected(selected)

	if(selected) then self.m_selected[icon] = true
	else self.m_selected[icon] = nil end

	self:CallCallbacks("OnIconSelected",icon)
end
function gui.IconGridView:GetIcons() return self.m_icons end
function gui.IconGridView:GetSelectedIcons()
	local tSelected = {}
	for el,_ in pairs(self.m_selected) do
		if(el:IsValid()) then
			table.insert(tSelected,el)
		end
	end
	return tSelected
end
function gui.IconGridView:IsIconSelected(el) return self.m_selected[el] == true end
function gui.IconGridView:MouseCallback(button,action,mods)
	if(action == input.STATE_PRESS and button == input.MOUSE_BUTTON_RIGHT) then
		local pContext = gui.open_context_menu()
		if(util.is_valid(pContext)) then
			pContext:SetPos(input.get_cursor_pos())
			self:CallCallbacks("PopulateContextMenu",pContext)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end
	if(action == input.STATE_PRESS and button == input.MOUSE_BUTTON_LEFT) then
		self:DeselectAll()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.IconGridView:KeyboardCallback(key,scanCode,action,mods)
	if(action == input.STATE_PRESS and key == input.KEY_A) then
		local isCtrlDown = input.get_key_state(input.KEY_LEFT_CONTROL) ~= input.STATE_RELEASE or
			input.get_key_state(input.KEY_RIGHT_CONTROL) ~= input.STATE_RELEASE
		if(isCtrlDown) then
			self:SelectAll()
			return util.EVENT_REPLY_HANDLED
		end
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.IconGridView:CreateIcon(text,...)
	local el = self.m_iconFactory(self.m_iconContainer,...)
	if(el == nil) then return end
	return self:AddIcon(text,el,...)
end
function gui.IconGridView:AddIcon(text,el,...)
	if(#el:GetText() == 0) then el:SetText(text) end -- Assign text, but only if icon hasn't assigned any text iself yet
	el:SetParent(self.m_iconContainer)
	table.insert(self.m_icons,el)

	el:SetMouseInputEnabled(true)
	el:AddCallback("OnMouseEvent",function(el,button,action,mods)
		if(util.is_valid(self) == false) then return util.EVENT_REPLY_UNHANDLED end
		if(button ~= input.MOUSE_BUTTON_LEFT or action ~= input.STATE_PRESS) then return util.EVENT_REPLY_UNHANDLED end
		local isCtrlDown = input.get_key_state(input.KEY_LEFT_CONTROL) ~= input.STATE_RELEASE or
			input.get_key_state(input.KEY_RIGHT_CONTROL) ~= input.STATE_RELEASE
		if(isCtrlDown) then
			self:SetIconSelected(el,not self:IsIconSelected(el))
			return util.EVENT_REPLY_HANDLED
		end
		local isShiftDown = input.get_key_state(input.KEY_LEFT_SHIFT) ~= input.STATE_RELEASE or
			input.get_key_state(input.KEY_RIGHT_SHIFT) ~= input.STATE_RELEASE
		if(isShiftDown) then
			local lastSelected = 1
			for i=1,#self.m_icons do
				local el = self.m_icons[i]
				if(el:IsValid() and self:IsIconSelected(el)) then
					lastSelected = i
				end
			end
			self:DeselectAll()
			local from = lastSelected
			local to = self:FindIconIndex(el)
			if(to ~= nil) then
				if(to < from) then
					local tmp = to
					to = from
					from = tmp
				end
				for i=from,to do
					local el = self.m_icons[i]
					if(el:IsValid()) then self:SetIconSelected(el) end
				end
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_HANDLED
		end
		self:DeselectAll()
		self:SetIconSelected(el)
		return util.EVENT_REPLY_HANDLED
	end)
	self:CallCallbacks("OnIconAdded",el)
	return el
end
gui.register("WIIconGridView",gui.IconGridView)

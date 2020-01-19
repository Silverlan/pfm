--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMSelection",gui.Base)

gui.PFMSelection.SELECTION_MODE_NONE = 0
gui.PFMSelection.SELECTION_MODE_SELECTED = 1
gui.PFMSelection.SELECTION_MODE_HOVER = 2
function gui.PFMSelection:__init()
	gui.Base.__init(self)
end
function gui.PFMSelection:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(8,8)
	local bg = gui.create("WIOutlinedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetOutlineWidth(1)
	bg:SetColor(Color(160,160,160))
	self.m_bg = bg

	self.m_selectedElements = {}

	self:SetCursorMovementCheckEnabled(true)
	self:AddCallback("OnCursorMoved",function(el,x,y)
		self:UpdateBounds()
		self.m_cursorHasMoved = true
	end)
	self:SetBackgroundElement(true)
end
function gui.PFMSelection:UpdateBounds()
	local startPos = self.m_cursorStartPos:Copy()
	local endPos = self:GetParent():GetCursorPos()

	vector.to_min_max(startPos,endPos)

	self:SetPos(startPos)
	self:SetSize(endPos -startPos)
	self:GetParent():CallCallbacks("OnSelectionChanged",self:GetPos(),self:GetSize())

	self:UpdateSelectedElements()
end
function gui.PFMSelection:IsInSelection(el)
	local startPos = Vector(self:GetLeft(),self:GetTop(),0)
	local endPos = Vector(self:GetRight(),self:GetBottom(),0)
	return intersect.aabb_with_aabb(startPos,endPos,Vector(el:GetLeft(),el:GetTop(),0),Vector(el:GetRight(),el:GetBottom(),0)) ~= intersect.RESULT_OUTSIDE
end
function gui.PFMSelection:GetSelectableElements()
	local tSelectable = {}
	for _,el in ipairs(self:GetParent():GetChildren()) do
		if(el._impl ~= nil and el._impl.mouseSelectable == true) then
			table.insert(tSelectable,el)
		end
	end
	return tSelectable
end
function gui.PFMSelection:UpdateSelectedElements()
	for el,b in pairs(self.m_selectedElements) do
		if(el:IsValid() and self:IsInSelection(el) == false and el._impl.mouseSelectionMode ~= gui.PFMSelection.SELECTION_MODE_SELECTED) then
			self.m_selectedElements[el] = nil
			gui.set_mouse_selection_mode(el,gui.PFMSelection.SELECTION_MODE_NONE)
		end
	end

	for _,el in ipairs(self:GetSelectableElements()) do
		if(self.m_selectedElements[el] == nil) then
			if(self:IsInSelection(el)) then
				self.m_selectedElements[el] = true
				if(el._impl.mouseSelectionMode ~= gui.PFMSelection.SELECTION_MODE_SELECTED) then
					gui.set_mouse_selection_mode(el,gui.PFMSelection.SELECTION_MODE_HOVER)
				end
			end
		end
	end
end
function gui.PFMSelection:StartSelection()
	self.m_cursorStartPos = self:GetParent():GetCursorPos()
	self.m_cursorHasMoved = false
	self:UpdateBounds()
end
function gui.PFMSelection:EndSelection()
	self:GetParent():CallCallbacks("OnSelectionApplied",self:GetPos(),self:GetSize())
	local tSelected = {}
	for el,b in pairs(self.m_selectedElements) do
		if(el:IsValid()) then
			gui.set_mouse_selection_mode(el,gui.PFMSelection.SELECTION_MODE_SELECTED)
			tSelected[el] = true
		end
	end
	local isCtrlDown = input.get_key_state(input.KEY_LEFT_CONTROL) ~= input.STATE_RELEASE or
		input.get_key_state(input.KEY_RIGHT_CONTROL) ~= input.STATE_RELEASE
	if(isCtrlDown) then return end
	--if(self.m_cursorHasMoved == true) then
		for _,el in ipairs(self:GetSelectableElements()) do
			if(tSelected[el] == nil) then
				gui.set_mouse_selection_mode(el,gui.PFMSelection.SELECTION_MODE_NONE)
			end
		end
	--end
end
gui.register("WIPFMSelection",gui.PFMSelection)


gui.set_mouse_selection_enabled = function(el,enabled)
	el._impl = el._impl or {}
	if(enabled == false) then
		if(util.is_valid(el._impl.cbMouseSelection)) then el._impl.cbMouseSelection:Remove() end
		el._impl.cbMouseSelection = nil
		return
	end
	if(util.is_valid(el._impl.cbMouseSelection)) then return end
	el:SetMouseInputEnabled(true)
	el._impl.cbMouseSelection = el:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT) then
			if(state == input.STATE_PRESS) then
				if(util.is_valid(el._impl.elMouseSelection) == false) then
					el._impl.elMouseSelection = gui.create("WIPFMSelection",el)
					el._impl.elMouseSelection:StartSelection()
				end
			elseif(state == input.STATE_RELEASE) then
				if(util.is_valid(el._impl.elMouseSelection)) then
					el._impl.elMouseSelection:EndSelection()
					el._impl.elMouseSelection:Remove()
				end
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end

gui.set_mouse_selection_mode = function(el,selectionMode)
	if(el._impl == nil or el._impl.mouseSelectable ~= true or el._impl.mouseSelectionMode == selectionMode) then return end
	el._impl.mouseSelectionMode = selectionMode
	if(selectionMode == gui.PFMSelection.SELECTION_MODE_NONE) then
		el:CallCallbacks("OnMouseDeselected")
	elseif(selectionMode == gui.PFMSelection.SELECTION_MODE_SELECTED) then
		el:CallCallbacks("OnMouseSelected")
	elseif(selectionMode == gui.PFMSelection.SELECTION_MODE_HOVER) then
		el:CallCallbacks("OnMouseSelectionHover")
	end
end

gui.clear_mouse_selection = function(el)
	for _,el in ipairs(el:GetChildren()) do
		if(el._impl ~= nil) then
			gui.set_mouse_selection_mode(el,gui.PFMSelection.SELECTION_MODE_NONE)
		end
	end
end

gui.set_mouse_selectable = function(el,selectable)
	el._impl = el._impl or {}
	el._impl.mouseSelectable = selectable
end

gui.set_mouse_selected = function(el,selected)
	if(el._impl == nil or el._impl.mouseSelectable ~= true) then return end
	gui.set_mouse_selection_mode(el,selected and gui.PFMSelection.SELECTION_MODE_SELECTED or gui.PFMSelection.SELECTION_MODE_DESELECTED)
end

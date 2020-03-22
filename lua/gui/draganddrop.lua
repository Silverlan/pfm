--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.DragGhost",gui.Base)
gui.DragGhost.impl = util.get_class_value(gui.DragGhost,"impl") or {
	dragTargets = {}
}
function gui.DragGhost:__init()
	gui.Base.__init(self)
end
function gui.DragGhost:OnInitialize()
	self:EnableThinking()
	self.m_cbOnMouseRelease = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
		if(self.m_complete == true) then return util.EVENT_REPLY_UNHANDLED end
		self.m_complete = true
		if(mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE) then
			self:RemoveSafely()
			if(util.is_valid(self.m_targetElement) and util.is_valid(self.m_hoverElement)) then
				self:CallCallbacks("OnDragDropped",self.m_hoverElement)
				self.m_targetElement:CallCallbacks("OnDragDropped",self.m_hoverElement)
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.DragGhost:OnRemove()
	if(util.is_valid(self.m_cbOnMouseRelease)) then self.m_cbOnMouseRelease:Remove() end
	self:ClearHover()
end
function gui.DragGhost:OnThink()
	local pos = input.get_cursor_pos()
	self:SetPos(pos)

	local elCursor = gui.get_element_under_cursor(function(el)
		local els = gui.DragGhost.impl.dragTargets[self.m_catName]
		return els ~= nil and els[el] == true
	end)
	if(util.is_valid(elCursor)) then
		if(self.m_hoverElement ~= elCursor) then
			self:ClearHover()
			self.m_hoverElement = elCursor
			self:CallCallbacks("OnDragTargetHoverStart")
			self.m_targetElement:CallCallbacks("OnDragTargetHoverStart",elCursor)
		end
	else self:ClearHover() end
end
function gui.DragGhost:SetTargetElement(el,cursorOffset,catName)
	self.m_targetElement = el
	self.m_cursorOffset = cursorOffset
	self.m_catName = catName

	self.m_drawInfo = gui.Element.DrawInfo()

	self:SetSize(el:GetSize())
end
function gui.DragGhost:GetTargetElement() return self.m_targetElement end
function gui.DragGhost:ClearHover()
	if(self.m_hoverElement == nil) then return end
	self:CallCallbacks("OnDragTargetHoverStop")
	self.m_targetElement:CallCallbacks("OnDragTargetHoverStop",self.m_hoverElement)
	self.m_hoverElement = nil
end
function gui.DragGhost:OnDraw()
	if(util.is_valid(self.m_targetElement) == false) then return end
	local resolution = engine.get_window_resolution()
	local offset = self:GetAbsolutePos() -self.m_cursorOffset
	self.m_drawInfo.offset = Vector2i(offset.x,offset.y)
	self.m_drawInfo.size = resolution
	self.m_drawInfo.color = self:GetColor()
	self.m_targetElement:Draw(self.m_drawInfo,Vector2i(offset.x,offset.y),resolution,Vector2i(offset.x,offset.y))
end
gui.register("WIDragGhost",gui.DragGhost)

gui.enable_drag_and_drop = function(src,catName,fOnGhostCreated)
	src:AddCallback("OnMouseEvent",function(src,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
			local p = gui.create("WIDragGhost")
			p:SetTargetElement(src,src:GetCursorPos(),catName)
			if(fOnGhostCreated ~= nil) then fOnGhostCreated(p) end
			return util.EVENT_REPLY_HANDLED
		end
	end)
	src:SetMouseInputEnabled(true)
end

gui.mark_as_drag_and_drop_target = function(tgt,catName)
	gui.DragGhost.impl.dragTargets[catName] = gui.DragGhost.impl.dragTargets[catName] or {}
	gui.DragGhost.impl.dragTargets[catName][tgt] = true
end

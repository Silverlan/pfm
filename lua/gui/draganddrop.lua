--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.DragGhost", gui.Base)
gui.DragGhost.impl = util.get_class_value(gui.DragGhost, "impl") or {
	dragTargets = {},
}
function gui.DragGhost:__init()
	gui.Base.__init(self)
end
function gui.DragGhost:OnInitialize()
	self.m_cursorTracker = gui.CursorTracker()
	self.m_isDragging = false
	self:SetSize(128, 128)
	self:EnableThinking()

	self.m_cbOnMouseRelease = input.add_callback("OnMouseInput", function(mouseButton, state, mods)
		if self:IsDragging() == false then
			self:RemoveSafely()
			return util.EVENT_REPLY_UNHANDLED
		end
		if self.m_complete == true then
			return util.EVENT_REPLY_UNHANDLED
		end
		self.m_complete = true
		if mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE then
			self:RemoveSafely()
			if util.is_valid(self.m_targetElement) and util.is_valid(self.m_hoverElement) then
				self:CallCallbacks("OnDragDropped", self.m_hoverElement)
				self.m_targetElement:CallCallbacks("OnDragDropped", self.m_hoverElement)
			end
			self:CallCallbacks("OnDragStopped")
			self.m_targetElement:CallCallbacks("OnDragStopped")
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.DragGhost:IsDragging()
	return self.m_isDragging
end
function gui.DragGhost:StartDragging()
	if self:IsDragging() then
		return
	end
	self.m_isDragging = true
	self.m_cursorTracker = nil

	local el = gui.create("WIRect", self, 0, 0, 128, 128, 0, 0, 1, 1)
	el:SetColor(Color.Gray)

	self:CallCallbacks("OnDragStarted")
end
function gui.DragGhost:OnRemove()
	if util.is_valid(self.m_cbOnMouseRelease) then
		self.m_cbOnMouseRelease:Remove()
	end
	self:ClearHover()
end
function gui.DragGhost:OnThink()
	if not self:IsDragging() then
		local dt = self.m_cursorTracker:Update()
		if dt.x == 0 and dt.y == 0 then
			return
		end
		self:StartDragging()
	end

	local pos = input.get_cursor_pos()
	self:SetPos(pos)

	local elCursor = gui.get_element_under_cursor(function(el)
		local els = gui.DragGhost.impl.dragTargets[self.m_catName]
		if els ~= nil and els[el] == true then
			return true
		end
		return self:CallCallbacks("OnHoverElement", el) or false
	end)
	if util.is_valid(elCursor) then
		if self.m_hoverElement ~= elCursor then
			self:ClearHover()
			self.m_hoverElement = elCursor
			self:CallCallbacks("OnDragTargetHoverStart", elCursor)
			self.m_targetElement:CallCallbacks("OnDragTargetHoverStart", elCursor)
		end
	else
		self:ClearHover()
	end
end
function gui.DragGhost:SetTargetElement(el, cursorOffset, catName)
	self.m_targetElement = el
	self.m_cursorOffset = cursorOffset
	self.m_catName = catName

	self:SetSize(el:GetSize())
end
function gui.DragGhost:GetTargetElement()
	return self.m_targetElement
end
function gui.DragGhost:ClearHover()
	if self.m_hoverElement == nil then
		return
	end
	self:CallCallbacks("OnDragTargetHoverStop", self.m_hoverElement)
	self.m_targetElement:CallCallbacks("OnDragTargetHoverStop", self.m_hoverElement)
	self.m_hoverElement = nil
end
function gui.DragGhost:OnDraw()
	-- TODO: This is no longer functional.
	-- The new way of doing it would be to render the target element into an image
	-- and use a WITexturedRect to display it
	if util.is_valid(self.m_targetElement) == false then
		return
	end
	local resolution = engine.get_window_resolution()
	local offset = self:GetAbsolutePos() - self.m_cursorOffset
	self.m_drawInfo = gui.Element.DrawInfo()
	self.m_drawInfo.offset = Vector2i(offset.x, offset.y)
	self.m_drawInfo.size = resolution
	self.m_drawInfo.color = self:GetColor()
	self.m_targetElement:Draw(self.m_drawInfo, Vector2i(offset.x, offset.y), resolution, Vector2i(offset.x, offset.y))
end
gui.register("WIDragGhost", gui.DragGhost)

gui.enable_drag_and_drop = function(src, catName, fOnGhostCreated)
	src:AddCallback("OnMouseEvent", function(src, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			local p = gui.create("WIDragGhost")
			p:SetTargetElement(src, src:GetCursorPos(), catName)
			if fOnGhostCreated ~= nil then
				fOnGhostCreated(p)
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)
	--
	src:SetMouseInputEnabled(true)
end

gui.mark_as_drag_and_drop_target = function(tgt, catName)
	gui.DragGhost.impl.dragTargets[catName] = gui.DragGhost.impl.dragTargets[catName] or {}
	gui.DragGhost.impl.dragTargets[catName][tgt] = true
end

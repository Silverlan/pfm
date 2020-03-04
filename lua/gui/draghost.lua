--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.DragGhost",gui.Base)
function gui.DragGhost:__init()
	gui.Base.__init(self)
end
function gui.DragGhost:OnInitialize()
	self:EnableThinking()
	self.m_cbOnMouseRelease = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
		if(mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE) then
			self.m_cbOnMouseRelease:Remove()
			self:RemoveSafely()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.DragGhost:OnRemove()
	if(util.is_valid(self.m_cbOnMouseRelease)) then self.m_cbOnMouseRelease:Remove() end
end
function gui.DragGhost:OnThink()
	local pos = input.get_cursor_pos()
	self:SetPos(64,64)--pos)
end
function gui.DragGhost:SetTargetElement(el)
	self.m_targetElement = el
	self:SetSize(el:GetSize())
end
function gui.DragGhost:OnDraw()
	if(util.is_valid(self.m_targetElement) == false) then return end
	self.m_targetElement:Draw(self:GetAbsolutePos(),Vector2(1920,1280),false)
end
gui.register("WIDragGhost",gui.DragGhost)

--[[gui.enable_drag_and_drop = function(src)
	src:AddCallback("OnMouseEvent",function()
		local p = gui.create("WIDragGhost")
		p:SetTargetElement(src)
		-- GHOST!!!
	end)
	-- src,dst
end]]

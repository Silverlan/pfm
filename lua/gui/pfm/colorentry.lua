--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("colorselector.lua")

util.register_class("gui.PFMColorEntry",gui.Base)

function gui.PFMColorEntry:__init()
	gui.Base.__init(self)
end
function gui.PFMColorEntry:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,24)
	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_rect = bg
	bg:GetColorProperty():Link(self:GetColorProperty())
	self:SetColor(Color.White)

	self:SetMouseInputEnabled(true)
end
function gui.PFMColorEntry:OnRemove()
	if(util.is_valid(self.m_colorSelectorWrapper)) then self.m_colorSelectorWrapper:Remove() end
end
function gui.PFMColorEntry:OpenColorSelector()
	if(util.is_valid(self.m_colorSelectorWrapper)) then return end

	local elWrapper = gui.create("WIBase",tool.get_filmmaker())
	elWrapper:SetZPos(10000)
	elWrapper:SetAutoAlignToParent(true)
	elWrapper:SetMouseInputEnabled(true)
	elWrapper:RequestFocus()
	elWrapper:TrapFocus()
	elWrapper:AddCallback("OnMouseEvent",function(el,button,state,mods)
		elWrapper:RemoveSafely()
		return util.EVENT_REPLY_HANDLED
	end)
	self.m_colorSelectorWrapper = elWrapper

	local el = gui.create("WIPFMColorSelector",elWrapper)
	local parent = el:GetParent()
	self.m_colorSelector = el
	el:SelectColor(self:GetColor())
	local pos = parent:GetCursorPos()
	pos.x = math.clamp(pos.x -el:GetWidth() /2.0,0,parent:GetWidth() -el:GetWidth())
	pos.y = math.clamp(pos.y -el:GetHeight() /2.0,0,parent:GetHeight() -el:GetHeight())
	el:SetPos(pos)
	--el:RequestFocus()
	--el:TrapFocus()

	el:Update()
	local colorWheel = el:GetColorWheel()
	local cursorPos = colorWheel:GetAbsolutePos() +colorWheel:GetSelectedColorCoordinates()
	input.set_cursor_pos(cursorPos)
	colorWheel:InjectMouseInput(colorWheel:GetCursorPos(),input.MOUSE_BUTTON_LEFT,input.STATE_PRESS,input.MOD_NONE)

	el:AddCallback("OnColorChanged",function()
		local color = el:GetSelectedColorRGB()
		self:SetColor(color)
	end)
	--[[el:SetCursorMovementCheckEnabled(true)
	el:AddCallback("OnCursorMoved",function(el,x,y)
		if(x < 0 or y < 0 or x >= el:GetWidth() or y >= el:GetHeight()) then
			if(input.get_mouse_button_state(input.MOUSE_BUTTON_LEFT) == input.STATE_RELEASE) then
				if(util.is_valid(self.m_colorSelectorWrapper)) then self.m_colorSelectorWrapper:RemoveSafely() end
			end
		end
	end)]]
	return fileDialog
end
function gui.PFMColorEntry:GetValue() return self:GetColor() end
function gui.PFMColorEntry:OnMouseEvent(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then self:OpenColorSelector()
		elseif(util.is_valid(self.m_colorSelector)) then
			local colorWheel = self.m_colorSelector:GetColorWheel()
			colorWheel:InjectMouseInput(colorWheel:GetCursorPos(),button,state,mods)
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
gui.register("WIPFMColorEntry",gui.PFMColorEntry)

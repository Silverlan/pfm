--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("locator.lua")
include("/shaders/pfm/pfm_color_wheel.lua")

util.register_class("gui.PFMColorWheel",gui.Base)

function gui.PFMColorWheel:__init()
	gui.Base.__init(self)
end
function gui.PFMColorWheel:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(150,150)
	local tex = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	-- The material doesn't matter due to our custom shader, but we do need to specify one
	tex:SetMaterial("white")

	local shader = shader.get("pfm_color_wheel")
	if(shader ~= nil) then tex:SetShader(shader) end

	local locator = gui.create("WIPFMLocator",self)
	locator:SetMouseInputEnabled(true)
	locator:SetCursorMovementCheckEnabled(true)
	locator:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT) then
			el.m_dragging = (state == input.STATE_PRESS)
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	locator:AddCallback("OnCursorMoved",function(el,x,y)
		if(el.m_dragging ~= true) then return util.EVENT_REPLY_UNHANDLED end
		local pos = self:GetCursorPos()

		local deg,l = self:CoordinatesToCircleOffset(pos.x,pos.y)
		self:SetCursorPos(deg,l)
		return util.EVENT_REPLY_HANDLED
	end)
	self.m_locator = locator

	tex:GetColorProperty():Link(self:GetColorProperty())
	self:SetMouseInputEnabled(true)
	self:SetBrightness(1.0)
	self:SetCursorPos(0,0)
	self:SelectColor(Color.White)
end
function gui.PFMColorWheel:OnMouseEvent(button,state,mods)
	local cursorPos = self:GetCursorPos()
	self.m_locator:InjectMouseInput(cursorPos,button,state,mods)
	self.m_locator:CallCallbacks("OnCursorMoved",cursorPos.x,cursorPos.y)
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMColorWheel:UpdateColor()
	self:CallCallbacks("OnColorChanged",self:GetSelectedColor())
end
function gui.PFMColorWheel:SetBrightness(brightness)
	self.m_brightness = brightness
	self:SetColor(Color.Black:Lerp(Color.White,brightness))
	self:CallCallbacks("OnBrightnessChanged",brightness)
	self:UpdateColor()
end
function gui.PFMColorWheel:GetBrightness() return self.m_brightness end
function gui.PFMColorWheel:CoordinatesToCircleOffset(x,y)
	local w = self:GetWidth()
	local h = self:GetHeight()
	x = x /w
	y = y /h
	x = x *2.0 -1.0
	y = y *2.0 -1.0
	local deg = 360.0 -(math.deg(math.atan2(x,y)) +180.0)
	local l = math.clamp(Vector2(x,y):Length(),0.0,1.0)
	return deg,l
end
function gui.PFMColorWheel:CircleOffsetToCoordinates(offset,distFromCenter)
	offset = math.rad(360.0 -(offset -180.0))
	local x = math.sin(offset)
	local y = math.cos(offset)
	local v = Vector2(x,y) *distFromCenter
	x = (v.x +1.0) /2.0
	y = (v.y +1.0) /2.0

	local w = self:GetWidth()
	local h = self:GetHeight()
	x = x *w
	y = y *h
	return Vector2(x,y)
end
function gui.PFMColorWheel:GetColorAtCursor()
	local pos = self.m_locator:GetPos()
	pos.x = pos.x +self.m_locator:GetWidth() /2.0
	pos.y = pos.y +self.m_locator:GetHeight() /2.0

	local xMin = self.m_locator:GetWidth() /2.0
	local xMax = self:GetWidth() -self.m_locator:GetWidth() /2.0

	local yMin = self.m_locator:GetHeight() /2.0
	local yMax = self:GetHeight() -self.m_locator:GetHeight() /2.0

	local x = (pos.x -xMin) /(xMax -xMin)
	local y = (pos.y -yMin) /(yMax -yMin)
	return self:GetColorAtCoordinates(x *self:GetWidth(),y *self:GetHeight())
end
function gui.PFMColorWheel:GetColorAtCoordinates(x,y)
	local deg,l = self:CoordinatesToCircleOffset(x,y)
	return util.HSVColor(deg,l,self:GetBrightness())
end
function gui.PFMColorWheel:GetSelectedColorCoordinates()
	local pos = self.m_locator:GetPos()
	pos.x = pos.x +self.m_locator:GetWidth() /2.0
	pos.y = pos.y +self.m_locator:GetHeight() /2.0
	return pos
end
function gui.PFMColorWheel:SetCursorPos(degree,l)
	-- Assumes that aspect ratio of the color wheel is 1:1
	local maxDist = (self:GetWidth() -self.m_locator:GetWidth()) /self:GetWidth()
	l = math.min(l,maxDist)

	local pos = self:CircleOffsetToCoordinates(degree,l)
	pos.x = pos.x -self.m_locator:GetWidth() /2.0
	pos.y = pos.y -self.m_locator:GetHeight() /2.0
	self.m_locator:SetPos(pos)
	self:UpdateColor()
end
function gui.PFMColorWheel:SelectColor(color)
	if(util.get_type_name(color) == "Color") then color = color:ToHSVColor() end
	self:SetCursorPos(color.h,color.s)
	self:SetBrightness(color.v)
end
function gui.PFMColorWheel:GetSelectedColor()
	return self:GetColorAtCursor()
end
gui.register("WIPFMColorWheel",gui.PFMColorWheel)

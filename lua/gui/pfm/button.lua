--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMButton",gui.Base)

gui.PFMButton.create = function(parent,matUnpressed,matPressed,onPressed)
	local bt = gui.create("WIPFMButton",parent)
	bt:SetMaterials(matUnpressed,matPressed)
	bt:AddCallback("OnPressed",onPressed)
	return bt
end

function gui.PFMButton:__init()
	gui.Base.__init(self)
end
function gui.PFMButton:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetSize(64,64)
	self.m_icon = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_icon:GetColorProperty():Link(self:GetColorProperty())

	self.m_pressed = false
	self.m_enabled = true
end
function gui.PFMButton:SetEnabled(enabled)
	if(enabled == self:IsEnabled()) then return end
	if(enabled == false) then self:SetActivated(false) end
	self.m_enabled = enabled
	local color = enabled and Color.White or Color(128,128,128)
	self:SetColor(color)
end
function gui.PFMButton:IsEnabled() return self.m_enabled end
function gui.PFMButton:IsActivated() return self.m_pressed end
function gui.PFMButton:SetActivated(activated)
	if(self:IsEnabled() == false) then return end
	self.m_pressed = activated
	self:SetMaterial(activated and self.m_pressedMaterial or self.m_unpressedMaterial)
end
function gui.PFMButton:SetPressedMaterial(mat)
	self.m_pressedMaterial = pressedMat
	if(self:IsActivated()) then self:SetMaterial(mat) end
end
function gui.PFMButton:SetUnpressedMaterial(mat)
	self.m_unpressedMaterial = unpressedMat
	if(self:IsActivated() == false) then self:SetMaterial(mat) end
end
function gui.PFMButton:SetMaterials(unpressedMat,pressedMat)
	self.m_unpressedMaterial = unpressedMat
	self.m_pressedMaterial = pressedMat
	self:SetMaterial(self.m_pressed and pressedMat or unpressedMat)
	local mat = game.load_material(unpressedMat)
	if(mat == nil) then return end
	local texInfo = mat:GetTextureInfo("diffuse_map")
	if(texInfo == nil) then return end
	self:SetSize(texInfo:GetWidth(),texInfo:GetHeight())
end
function gui.PFMButton:SetMaterial(mat)
	if(mat ~= nil and util.is_valid(self.m_icon)) then self.m_icon:SetMaterial(mat) end
end
function gui.PFMButton:SetupContextMenu(fPopulateContextMenu)
	local w = 12
	self.m_contextTrigger = gui.create("WIBase",self,self:GetWidth() -w,0,w,self:GetHeight(),1,0,1,0)
	self.m_contextTrigger:SetMouseInputEnabled(true)
	self.m_contextTrigger:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button ~= input.MOUSE_BUTTON_LEFT or self:IsEnabled() == false) then return util.EVENT_REPLY_UNHANDLED end
		if(state == input.STATE_PRESS) then
			self:SetActivated(true)
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			local pos = self:GetAbsolutePos()
			pContext:SetPos(pos.x,pos.y +self:GetHeight())
			fPopulateContextMenu(pContext)
			pContext:Update()

			pContext:AddCallback("OnRemove",function()
				if(self:IsValid()) then self:SetActivated(false) end
			end)
		end
		return util.EVENT_REPLY_HANDLED
	end)
end
function gui.PFMButton:MouseCallback(button,state,mods)
	if(self:IsEnabled() == false) then return util.EVENT_REPLY_UNHANDLED end
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			self:SetActivated(true)
		elseif(state == input.STATE_RELEASE) then
			if(self:CallCallbacks("OnPressed") ~= true) then
				self:SetActivated(false)
			end
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("WIPFMButton",gui.PFMButton)

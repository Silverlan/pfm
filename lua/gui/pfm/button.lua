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
function gui.PFMButton:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			self.m_pressed = true
			self:SetMaterial(self.m_pressedMaterial)
		elseif(state == input.STATE_RELEASE) then
			self.m_pressed = nil
			self:SetMaterial(self.m_unpressedMaterial)
			self:CallCallbacks("OnPressed")
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("WIPFMButton",gui.PFMButton)

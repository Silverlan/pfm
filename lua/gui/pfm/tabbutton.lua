--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTabButton",gui.Base)

function gui.PFMTabButton:__init()
	gui.Base.__init(self)
end
function gui.PFMTabButton:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,32)
	self.m_bg = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetMaterial("gui/pfm/tab-selected")
	self.m_bg:GetColorProperty():Link(self:GetColorProperty())

	self.m_text = gui.create("WIText",self)
	self.m_text:SetColor(Color(152,152,152))
	self.m_text:SetFont("pfm_medium")

	self:SetMouseInputEnabled(true)

	self:SetActive(false)

	local mat = self.m_bg:GetMaterial()
	if(mat == nil) then return end
	local texInfo = mat:GetTextureInfo("diffuse_map")
	if(texInfo == nil) then return end
	self:SetSize(texInfo:GetWidth(),texInfo:GetHeight())
end
function gui.PFMTabButton:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_RELEASE) then
			self:CallCallbacks("OnPressed")
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMTabButton:SetActive(active)
	if(active) then self:SetColor(Color.White)
	else self:SetColor(Color(200,200,200)) end
end
function gui.PFMTabButton:SetText(text)
	if(util.is_valid(self.m_text)) then
		self.m_text:SetText(text)
		self.m_text:SizeToContents()
		self.m_text:SetPos(
			self:GetWidth() *0.5 -self.m_text:GetWidth() *0.5,
			self:GetHeight() *0.5 -self.m_text:GetHeight() *0.5
		)
		self.m_text:SetAnchor(0.5,0.5,0.5,0.5)
	end
end
gui.register("WIPFMTabButton",gui.PFMTabButton)

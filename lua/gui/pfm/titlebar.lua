--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMTitlebar",gui.Base)

function gui.PFMTitlebar:__init()
	gui.Base.__init(self)
end
function gui.PFMTitlebar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,31)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color.White)

	self.m_text = gui.create("WIText",self,11,8)
	self.m_text:SetColor(Color.Black)
	self.m_text:SetFont("pfm_medium")
	self.m_text:SetVisible(false)
end
function gui.PFMTitlebar:SetText(text)
	if(util.is_valid(self.m_text) == false) then return end
	self.m_text:SetVisible(#text > 0)
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
gui.register("WIPFMTitlebar",gui.PFMTitlebar)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMPopup",gui.Base)

function gui.PFMPopup:__init()
	gui.Base.__init(self)
end
function gui.PFMPopup:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(400,32)
	self.m_elBg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_elBg:SetColor(Color.Black)
	self.m_elText = gui.create("WIText",self)
	--self.m_elText:SetAutoBreakMode(gui.Text.AUTO_BREAK_WHITESPACE) -- TODO
	self.m_elText:SetPos(10,10)
	self.m_elText:SetColor(Color.Red)

	self.m_lastVisTime = 0.0
	self:SetThinkingEnabled(true)
end
function gui.PFMPopup:OnThink()
	local t = time.real_time()
	if(t -self.m_lastVisTime > 10) then self:SetVisible(false) end
end
function gui.PFMPopup:SetText(text)
	self.m_elText:SetText(text)
	self.m_elText:SizeToContents()

	self:SetHeight(self.m_elText:GetHeight() +20)
	self.m_lastVisTime = time.real_time()
	self:SetVisible(true)
end
gui.register("WIPFMPopup",gui.PFMPopup)

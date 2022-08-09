--[[
    Copyright (C) 2021 Silverlan

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
	self.m_elText:SetTagsEnabled(true)

	self.m_lastVisTime = 0.0
	self.m_queue = {}
	self.m_first = true
	self:SetThinkingEnabled(true)
end
function gui.PFMPopup:OnThink()
	local t = time.real_time()
	if(t -self.m_lastVisTime > 10) then
		if(#self.m_queue == 0) then
			self:SetVisible(false)
			self.m_first = true
		else self:DisplayNextText() end
	end
end
function gui.PFMPopup:DisplayNextText()
	if(#self.m_queue == 0) then return end
	self.m_elText:SetText(self.m_queue[1])
	self.m_elText:SizeToContents()

	self:SetHeight(self.m_elText:GetHeight() +20)
	self:SetWidth(self.m_elText:GetWidth() +20)
	self.m_lastVisTime = time.real_time()
	self:SetVisible(true)
	self:SetX(self:GetParent():GetWidth() -self:GetWidth())
	table.remove(self.m_queue,1)
end
function gui.PFMPopup:AddToQueue(text)
	table.insert(self.m_queue,text)
	if(self.m_first) then
		self:DisplayNextText()
		self.m_first = false
	end
end
gui.register("WIPFMPopup",gui.PFMPopup)

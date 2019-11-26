--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("tabbutton.lua")
include("/gui/hbox.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMFrame",gui.Base)

function gui.PFMFrame:__init()
	gui.Base.__init(self)
end
function gui.PFMFrame:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,128)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(41,41,41))

	self.m_btClose = gui.PFMButton.create(self,"gui/pfm/icon_clear","gui/pfm/icon_clear_activated",function()
		print("TODO: Close frame")
	end)
	self.m_btClose:SetSize(11,11)
	self.m_btClose:SetPos(self:GetWidth() -self.m_btClose:GetWidth() -7,10)
	self.m_btClose:SetAnchor(1,0,1,0)

	self.m_contents = gui.create("WIBase",self,0,28,self:GetWidth(),self:GetHeight() -28,0,0,1,1)
	self.m_tabButtons = {}
	self.m_tabButtonContainer = gui.create("WIHBox",self)
	self.m_tabButtonContainer:SetHeight(28)

	self:ScheduleUpdate()
end
function gui.PFMFrame:SetActiveTab(tabId)
	if(util.is_valid(self.m_activeTabButton)) then self.m_activeTabButton:SetActive(false) end

	local bt = self.m_tabButtons[tabId]
	if(util.is_valid(bt)) then bt:SetActive(true) end

	self.m_activeTabButton = bt
	self.m_activeTabPanel = bt:GetContents()
end
function gui.PFMFrame:AddTab(name,panel)
	if(util.is_valid(self.m_contents) == false or util.is_valid(self.m_tabButtonContainer) == false) then
		panel:RemoveSafely()
		return
	end
	local bt = gui.create("WIPFMTabButton",self.m_tabButtonContainer)
	bt:SetText(name)
	local tabId = #self.m_tabButtons +1
	bt:AddCallback("OnPressed",function()
		self:SetActiveTab(tabId)
	end)
	panel:SetParent(self.m_contents)
	panel:SetPos(0,0)
	panel:SetSize(self.m_contents:GetWidth(),self.m_contents:GetHeight())
	panel:SetAnchor(0,0,1,1)

	bt:SetContents(panel)
	table.insert(self.m_tabButtons,bt)
end
function gui.PFMFrame:OnUpdate()
	if(self.m_activeTabButton == nil) then self:SetActiveTab(1) end
end
gui.register("WIPFMFrame",gui.PFMFrame)

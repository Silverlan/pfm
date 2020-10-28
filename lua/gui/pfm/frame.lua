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
		print("TODO")
	end)
	self.m_btClose:SetSize(11,11)
	self.m_btClose:SetPos(self:GetWidth() -self.m_btClose:GetWidth() -7,10)
	self.m_btClose:SetAnchor(1,0,1,0)

	self.m_contents = gui.create("WIBase",self,0,28,self:GetWidth(),self:GetHeight() -28,0,0,1,1)
	self.m_tabs = {}
	self.m_tabButtonContainer = gui.create("WIHBox",self)
	self.m_tabButtonContainer:SetHeight(28)

	self:ScheduleUpdate()
end
function gui.PFMFrame:SetActiveTab(tabId)
	if(type(tabId) == "string") then
		tabId = self:GetTabId(tabId)
		if(tabId == nil) then return end
	end
	if(type(tabId) ~= "number") then
		local el = tabId
		for tabId,tabData in ipairs(self.m_tabs) do
			if(tabData.button:IsValid() and tabData.button:GetContents() == el) then
				self:SetActiveTab(tabId)
				break
			end
		end
		return
	end
	if(self.m_tabs[tabId] == nil) then return end
	if(util.is_valid(self.m_activeTabButton)) then self.m_activeTabButton:SetActive(false) end

	local bt = self.m_tabs[tabId].button

	self.m_activeTabButton = bt
	self.m_activeTabPanel = bt:GetContents()
	self.m_activeTabIndex = tabId
	
	if(util.is_valid(bt)) then bt:SetActive(true) end
end
function gui.PFMFrame:GetTabId(identifier)
	for i,tabData in ipairs(self.m_tabs) do
		if(tabData.identifier == identifier) then
			return i
		end
	end
end
function gui.PFMFrame:RemoveTab(identifier)
	local i = self:GetTabId(identifier)
	if(i == nil) then return end
	local tabData = self.m_tabs[i]
	if(tabData.panel:IsValid()) then tabData.panel:Remove() end
	if(tabData.button:IsValid()) then tabData.button:Remove() end
	table.remove(self.m_tabs,i)
	if(self.m_activeTabIndex == i) then
		if(self.m_tabs[self.m_activeTabIndex -1] ~= nil) then self:SetActiveTab(self.m_activeTabIndex -1)
		elseif(self.m_tabs[self.m_activeTabIndex] ~= nil) then self:SetActiveTab(self.m_activeTabIndex) end
	end
end
function gui.PFMFrame:FindTab(name)
	for _,tab in ipairs(self.m_tabs) do
		if(name == tab.identifier) then return tab.panel end
	end
end
function gui.PFMFrame:AddTab(identifier,name,panel)
	if(util.is_valid(self.m_contents) == false or util.is_valid(self.m_tabButtonContainer) == false) then
		panel:RemoveSafely()
		return
	end
	local bt = gui.create("WIPFMTabButton",self.m_tabButtonContainer)
	bt:SetText(name)
	bt:AddCallback("OnPressed",function()
		local tabId = self:GetTabId(identifier)
		self:SetActiveTab(tabId)
	end)
	bt:AddCallback("OnMouseEvent",function(bt,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("close"),function()
				self:RemoveTab(identifier)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	panel:SetParent(self.m_contents)
	panel:SetPos(0,0)
	panel:SetSize(self.m_contents:GetWidth(),self.m_contents:GetHeight())
	panel:SetAnchor(0,0,1,1)

	bt:SetContents(panel)

	table.insert(self.m_tabs,{
		identifier = identifier,
		button = bt,
		panel = panel
	})
	return #self.m_tabs
end
function gui.PFMFrame:OnUpdate()
	if(self.m_activeTabButton == nil) then self:SetActiveTab(1) end
end
gui.register("WIPFMFrame",gui.PFMFrame)

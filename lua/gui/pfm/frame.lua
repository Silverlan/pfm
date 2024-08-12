--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("button.lua")
include("tabbutton.lua")
include("/gui/hbox.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMFrame", gui.Base)

function gui.PFMFrame:__init()
	gui.Base.__init(self)
end
function gui.PFMFrame:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 128)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(41, 41, 41))

	--[[self.m_btClose = gui.PFMButton.create(self, "gui/pfm/icon_clear", "gui/pfm/icon_clear_activated", function()
		print("TODO")
	end)
	self.m_btClose:SetSize(11, 11)
	self.m_btClose:SetPos(self:GetWidth() - self.m_btClose:GetWidth() - 7, 10)
	self.m_btClose:SetAnchor(1, 0, 1, 0)]]

	self.m_contents = gui.create("WIBase", self, 0, 28, self:GetWidth(), self:GetHeight() - 28, 0, 0, 1, 1)
	self.m_tabs = {}
	self.m_tabButtonContainer = gui.create("WIHBox", self)
	self.m_tabButtonContainer:SetHeight(28)
	self.m_tabButtonContainer:SetName("tab_button_container")

	gui.create("WIBase", self.m_tabButtonContainer):SetSize(5, 1) -- Gap
	self.m_btAddPanel = gui.PFMButton.create(
		self.m_tabButtonContainer,
		"gui/pfm/icon_cp_add",
		"gui/pfm/icon_cp_add_activated",
		function()
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			local pos = self.m_btAddPanel:GetAbsolutePos()
			pContext:SetPos(pos.x, pos.y + self.m_btAddPanel:GetHeight())
			self:CallCallbacks("PopulateWindowMenu", pContext)
			pContext:Update()
		end
	)
	self.m_btAddPanel:SetName("panel_add_button")
	gui.create("WIBase", self.m_tabButtonContainer):SetSize(5, 1) -- Gap

	self:SetThinkingEnabled(true)
	self.m_detachedWindows = {}
	self:ScheduleUpdate()
end
function gui.PFMFrame:OnRemove()
	for _, tab in ipairs(self.m_tabs) do
		if util.is_valid(tab.window) then
			tab.window:Close()
		end
	end
end
function gui.PFMFrame:SetActiveTab(tabId)
	if type(tabId) == "string" then
		if tabId == self:GetTabIdentifier(self:GetSelectedTabId()) then
			return
		end
		tabId = self:GetTabId(tabId)
		if tabId == nil then
			return
		end
	end
	if type(tabId) ~= "number" then
		local el = tabId
		for tabId, tabData in ipairs(self.m_tabs) do
			if tabData.button:IsValid() and tabData.button:GetContents() == el then
				self:SetActiveTab(tabId)
				break
			end
		end
		return
	end
	if self.m_tabs[tabId] == nil or tabId == self:GetSelectedTabId() then
		return
	end
	if util.is_valid(self.m_activeTabButton) then
		self.m_activeTabButton:SetActive(false)
	end

	local bt = self.m_tabs[tabId].button

	self.m_activeTabButton = bt
	self.m_activeTabPanel = bt:GetContents()
	self.m_activeTabIndex = tabId

	if util.is_valid(bt) then
		bt:SetActive(true)
	end
end
function gui.PFMFrame:GetTabId(identifier)
	for i, tabData in ipairs(self.m_tabs) do
		if tabData.identifier == identifier then
			return i
		end
	end
end
function gui.PFMFrame:GetSelectedTabId()
	return self.m_activeTabIndex
end
function gui.PFMFrame:GetTabIdentifier(i)
	if i == nil or self.m_tabs[i] == nil then
		return
	end
	return self.m_tabs[i].identifier
end
function gui.PFMFrame:RemoveTab(identifier)
	local i = self:GetTabId(identifier)
	if i == nil then
		return
	end
	local tabData = self.m_tabs[i]
	if tabData.panel:IsValid() then
		tabData.panel:Remove()
	end
	if tabData.button:IsValid() then
		tabData.button:Remove()
	end
	table.remove(self.m_tabs, i)
	if self.m_activeTabIndex == i then
		self:SelectFreeTab()
	end
end
function gui.PFMFrame:SelectFreeTab()
	local function selectTab(i)
		local tab = self.m_tabs[i]
		if tab == nil or util.is_valid(tab.window) then
			return false
		end
		self:SetActiveTab(i)
		return true
	end
	if selectTab(self.m_activeTabIndex) then
		return
	end
	if selectTab(self.m_activeTabIndex - 1) then
		return
	end
	if selectTab(self.m_activeTabIndex + 1) then
		return
	end
	for i = 1, #self.m_tabs do
		if selectTab(self.m_tabs[i]) then
			return
		end
	end
end
function gui.PFMFrame:FindTabIdentifier(el)
	for _, tab in ipairs(self.m_tabs) do
		if util.is_same_object(el, tab.panel) or util.is_same_object(el, tab.button) then
			return tab.identifier
		end
	end
end
function gui.PFMFrame:FindTabData(name)
	for _, tab in ipairs(self.m_tabs) do
		if name == tab.identifier then
			return tab
		end
	end
end
function gui.PFMFrame:FindTab(name)
	local tabData = self:FindTabData(name)
	if tabData == nil then
		return
	end
	return tabData.panel
end
function gui.PFMFrame:FindTabButton(name)
	local tabData = self:FindTabData(name)
	if tabData == nil then
		return
	end
	return tabData.button
end
function gui.PFMFrame:IsTabDetached(name)
	local window = self:GetDetachedTabWindow(name)
	return util.is_valid(window)
end
function gui.PFMFrame:GetDetachedTabWindow(name)
	local tabData = self:FindTabData(name)
	if tabData == nil then
		return false
	end
	return util.is_valid(tabData.window) and tabData.window or nil
end
function gui.PFMFrame:GetTabContainer()
	return self.m_tabButtonContainer
end
function gui.PFMFrame:AddTab(identifier, name, panel)
	if util.is_valid(self.m_contents) == false or util.is_valid(self.m_tabButtonContainer) == false then
		panel:RemoveSafely()
		return
	end
	local bt = gui.create("WIPFMTabButton", self.m_tabButtonContainer)
	bt:SetText(name)
	bt:SetName(identifier .. "_tab_button")
	bt:SetFrame(self)
	bt:AddCallback("OnPressed", function()
		local tabId = self:GetTabId(identifier)
		self:SetActiveTab(tabId)
	end)
	bt:AddCallback("OnMouseEvent", function(bt, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("detach"), function()
				if not self:IsValid() then
					return
				end
				self:DetachTab(identifier)
			end)
			pContext:AddItem(locale.get_text("close"), function()
				if not self:IsValid() then
					return
				end
				self:RemoveTab(identifier)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	panel:SetParent(self.m_contents)
	panel:SetPos(0, 0)
	panel:SetSize(self.m_contents:GetWidth(), self.m_contents:GetHeight())
	panel:SetAnchor(0, 0, 1, 1)

	bt:SetContents(panel)

	table.insert(self.m_tabs, {
		identifier = identifier,
		button = bt,
		panel = panel,
	})
	return #self.m_tabs
end
function gui.PFMFrame:GetTabs()
	return self.m_tabs
end
function gui.PFMFrame:OnThink()
	if self.m_activeTabButton == nil then
		self:SetActiveTab(1)
	end
	self:SetThinkingEnabled(false)
end
function gui.PFMFrame:DetachTab(identifier, width, height)
	if type(identifier) ~= "string" then
		identifier = self:FindTabIdentifier(identifier)
		if identifier == nil then
			return
		end
	end
	local tabData = self:FindTabData(identifier)
	if tabData == nil or util.is_valid(tabData.panel) == false then
		return
	end
	if util.is_valid(tabData.window) then
		return tabData.window
	end
	local panel = tabData.panel
	local createInfo = prosper.WindowCreateInfo()
	createInfo.width = width or panel:GetWidth()
	createInfo.height = height or panel:GetHeight()
	self:LogInfo("Detaching frame " .. identifier .. " with size " .. createInfo.width .. "x" .. createInfo.height)
	if util.is_valid(tabData.button) then
		createInfo.title = tabData.button:GetText()
	end
	local windowHandle = prosper.create_window(createInfo)
	if windowHandle == nil then
		return
	end
	local el = gui.get_base_element(windowHandle)
	if util.is_valid(el) == false then
		return
	end

	local elBg = gui.create("WIRect", el, 0, 0, el:GetWidth(), el:GetHeight(), 0, 0, 1, 1)
	elBg:SetColor(Color(38, 38, 38, 255))

	panel:ClearAnchor()
	panel:SetParentAndUpdateWindow(elBg)
	panel:SetPos(0, 0)
	panel:SetSize(elBg:GetSize())
	panel:SetAnchor(0, 0, 1, 1)
	panel:TrapFocus(true)
	panel:RequestFocus()
	windowHandle:AddCloseListener(function()
		if not self:IsValid() then
			return
		end
		self:AttachTab(identifier)
	end)
	tabData.window = windowHandle

	if util.is_valid(tabData.button) then
		tabData.button:SetVisible(false)
	end

	local i = self:GetTabId(identifier)
	if i ~= nil and self.m_activeTabIndex == i then
		self:SelectFreeTab()
	end
	if panel:IsValid() then
		panel:SetVisible(true)
		panel:CallCallbacks("OnDetached", windowHandle)
	end
	return windowHandle
end

function gui.PFMFrame:AttachTab(identifier)
	if type(identifier) ~= "string" then
		identifier = self:FindTabIdentifier(identifier)
		if identifier == nil then
			return
		end
	end
	local tabData = self:FindTabData(identifier)
	if tabData == nil or util.is_valid(tabData.panel) == false or tabData.window == nil then
		return
	end
	self:LogInfo("Attaching frame " .. identifier)
	local windowHandle = tabData.window

	local panel = tabData.panel
	if panel:IsValid() then
		if util.is_valid(self.m_contents) then
			panel:SetParentAndUpdateWindow(self.m_contents)
			panel:SetPos(0, 0)
			panel:SetSize(self.m_contents:GetWidth(), self.m_contents:GetHeight())
			panel:SetAnchor(0, 0, 1, 1)
			panel:TrapFocus(false)
			panel:KillFocus()
		else
			panel:Remove()
		end
	end

	if windowHandle:IsValid() then
		util.remove(gui.get_base_element(windowHandle))
		windowHandle:Close()
	end
	tabData.window = nil

	if util.is_valid(tabData.button) then
		tabData.button:SetVisible(true)
	end
	self:SetActiveTab(identifier)

	if panel:IsValid() then
		panel:CallCallbacks("OnReattached")
	end
end
gui.register("WIPFMFrame", gui.PFMFrame)

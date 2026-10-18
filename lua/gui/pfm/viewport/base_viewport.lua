-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.PFMBaseViewport", gui.Base)

function gui.PFMBaseViewport:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128, hViewport + hBottom)

	self.m_contents = gui.create("hbox", self)
	self.m_contents:AddStyleClass("fill")
	self.m_contents:AddStyleClass("viewport__content-area")
	--self.m_contents:AddStyleClass("viewport_container")

	self.m_vpContents = gui.create("vbox", self.m_contents)
	self.m_vpContents:AddStyleClass("viewport__viewport-area")
	self.m_vpContents:SetName("left_contents")

	local titleBar = gui.create("hbox", self.m_vpContents)
	titleBar:AddStyleClass("viewport__title-bar")
	self.m_titleBar = titleBar

	self.m_rtBox = gui.create("WIBase", self.m_vpContents)
	self.m_rtBox:AddStyleClass("aspect-ratio-wrapper")

	self.m_aspectRatioWrapper =
		gui.create("aspect_ratio", self.m_rtBox)
	self.m_aspectRatioWrapper:AddStyleClass("aspect-ratio")
	self:InitializeViewport(self.m_aspectRatioWrapper)

	if self.m_settingsEnabled ~= false then
		gui.create("resizer", self.m_contents):SetFraction(0.85)

		local scrollContainer = gui.create("WIScrollContainer", self.m_contents)
		scrollContainer:SetContentsWidthFixed(true)
		scrollContainer:GetVerticalScrollBar():SetScrollAmount(1)
		self.m_scrollContainer = scrollContainer

		self:InitializeSettings(self.m_scrollContainer)
	end
	self:InitializeControls()
end
function gui.PFMBaseViewport:SetSettingsEnabled(enabled)
	self.m_settingsEnabled = enabled
end
function gui.PFMBaseViewport:InitializeViewport(parent) end
function gui.PFMBaseViewport:InitializeSettings(parent)
	local p = gui.create("pfm_controls_menu", parent)
	p:SetName("controls_menu")
	p:SetHorizontalAlignment(gui.ALIGNMENT_FILL)
	p:SetAutoSizeToContents(false, true)
	self.m_settingsBox = p
end
function gui.PFMBaseViewport:InitializeControls() end

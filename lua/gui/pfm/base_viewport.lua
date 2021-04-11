--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMBaseViewport",gui.Base)

function gui.PFMBaseViewport:__init()
	gui.Base.__init(self)
end
function gui.PFMBaseViewport:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128,hViewport +hBottom)

	self.m_contents = gui.create("WIHBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	self.m_vpContents = gui.create("WIVBox",self.m_contents)
	self.m_vpContents:SetAutoFillContents(true)

	local titleBar = gui.create("WIBase",self.m_vpContents)
	titleBar:SetWidth(self.m_vpContents:GetWidth())
	titleBar:SetHeight(0)
	self.m_titleBar = titleBar

	self.m_rtBox = gui.create("WIRect",self.m_vpContents,0,0,128,128)
	self.m_rtBox:SetColor(Color.Black)
	self.m_vpContents:SetAutoFillTarget(self.m_rtBox)
	self.m_aspectRatioWrapper = gui.create("WIAspectRatio",self.m_rtBox,0,0,self.m_rtBox:GetWidth(),self.m_rtBox:GetHeight(),0,0,1,1)
	self:InitializeViewport(self.m_aspectRatioWrapper)

	gui.create("WIResizer",self.m_contents):SetFraction(0.85)

	self:InitializeSettings(self.m_contents)
	self:InitializeControls()
end
function gui.PFMBaseViewport:InitializeViewport(parent) end
function gui.PFMBaseViewport:InitializeSettings(parent)
	local p = gui.create("WIPFMControlsMenu",parent)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p
end
function gui.PFMBaseViewport:InitializeControls()
end

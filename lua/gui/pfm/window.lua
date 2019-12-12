--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("titlebar.lua")

util.register_class("gui.PFMWindow",gui.Base)

function gui.PFMWindow:__init()
	gui.Base.__init(self)
end
function gui.PFMWindow:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,128)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color(54,54,54))

	local mainBox = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight())
	mainBox:SetAutoFillContentsToWidth(true)
	self.m_mainBox = mainBox

	self.m_titleBar = gui.create("WIPFMTitlebar",mainBox)
	self.m_contents = gui.create("WIVBox",mainBox)

	local outline = gui.create("WIOutlinedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	outline:SetColor(Color.DodgerBlue)

	-- Create frame
	local parent = self:GetParent()
	local pBg = gui.create("WIRect",parent,0,0,parent:GetWidth(),parent:GetHeight(),0,0,1,1)
	local col = Color.Black:Copy()
	col.a = 220
	pBg:SetColor(col)
	self:RemoveElementOnRemoval(pBg)

	local sz = gui.get_window_size()
	local pFrame = gui.create("WITransformable",parent)
	pFrame:SetDraggable(true)
	pFrame:SetResizable(false)
	self:RemoveElementOnRemoval(pFrame)

	self:SetParent(pFrame)
	self:SetSize(pFrame:GetSize())
	self:SetAnchor(0,0,1,1)

	pFrame:TrapFocus(true)
	pFrame:RequestFocus()

	local pDrag = pFrame:GetDragArea()
	pDrag:SetHeight(self.m_titleBar:GetHeight())
	pDrag:SetAutoAlignToParent(true,false)

	pFrame:CenterToParent()
	self.m_frame = pFrame
end
function gui.PFMWindow:SetWindowSize(size,minSize,maxSize)
	if(util.is_valid(self.m_frame) == false) then return end
	minSize = minSize or size
	maxSize = maxSize or size
	self.m_frame:SetMinSize(Vector2i(minSize.x,minSize.y))
	self.m_frame:SetMaxSize(Vector2i(maxSize.x,maxSize.y))
	self.m_frame:SetSize(size.x,size.y)
	self.m_frame:CenterToParent()
end
function gui.PFMWindow:GetFrame() return self.m_frame end
function gui.PFMWindow:SetTitle(title)
	if(util.is_valid(self.m_titleBar) == false) then return end
	self.m_titleBar:SetText(title)
end
function gui.PFMWindow:GetContents() return self.m_contents end
function gui.PFMWindow:OnSizeChanged(w,h)
	if(util.is_valid(self.m_mainBox) == false) then return end
	self.m_mainBox:SetWidth(w)
end
gui.register("WIPFMWindow",gui.PFMWindow)

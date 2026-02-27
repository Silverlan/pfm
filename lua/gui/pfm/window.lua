-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("titlebar.lua")

util.register_class("gui.PFMWindow", gui.Base)

function gui.PFMWindow:__init()
	gui.Base.__init(self)
end
function gui.PFMWindow:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 128)

	local bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	bg:AddStyleClass("background2")

	local mainBox = gui.create("vbox", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	mainBox:SetFixedSize(true)
	mainBox:SetAutoFillContentsToWidth(true)
	self.m_mainBox = mainBox

	self.m_titleBar = gui.create("pfm_titlebar", mainBox)
	local contents = gui.create("hbox", mainBox)
	gui.create("WIBase", contents, 0, 0, 12, 1) -- Gap
	self.m_innerContents = gui.create("vbox", contents)
	gui.create("WIBase", contents, 0, 0, 12, 1) -- Gap

	local outline = gui.create("WIOutlinedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	outline:AddStyleClass("outline")

	-- Create frame
	local parent = self:GetParent()
	local pBg = gui.create("WIRect", parent, 0, 0, parent:GetWidth(), parent:GetHeight(), 0, 0, 1, 1)
	local col = Color.Black:Copy()
	col.a = 220
	pBg:SetColor(col)
	self:RemoveElementOnRemoval(pBg)

	local sz = gui.get_window_size()
	local pFrame = gui.create("WITransformable", parent)
	pFrame:SetDraggable(true)
	pFrame:SetResizable(false)
	pFrame:SetZPos(200000)
	self:RemoveElementOnRemoval(pFrame)

	self:SetParent(pFrame)
	self:SetSize(pFrame:GetSize())
	self:SetAnchor(0, 0, 1, 1)

	pFrame:TrapFocus(true)
	pFrame:RequestFocus()

	local pDrag = pFrame:GetDragArea()
	pDrag:SetHeight(self.m_titleBar:GetHeight())
	pDrag:SetAutoAlignToParent(true, false)

	pFrame:CenterToParent()
	self.m_frame = pFrame
end
function gui.PFMWindow:SetWindowSize(size, minSize, maxSize)
	if util.is_valid(self.m_frame) == false then
		return
	end
	minSize = minSize or size
	maxSize = maxSize or size
	self.m_frame:SetMinSize(Vector2i(minSize.x, minSize.y))
	self.m_frame:SetMaxSize(Vector2i(maxSize.x, maxSize.y))
	self.m_frame:SetSize(size.x, size.y)
	self.m_frame:CenterToParent()
end
function gui.PFMWindow:GetFrame()
	return self.m_frame
end
function gui.PFMWindow:SetTitle(title)
	if util.is_valid(self.m_titleBar) == false then
		return
	end
	self.m_titleBar:SetText(title)
end
function gui.PFMWindow:GetContents()
	return self.m_innerContents
end
function gui.PFMWindow:OnSizeChanged(w, h)
	if util.is_valid(self.m_mainBox) == false then
		return
	end
	self.m_mainBox:SetWidth(w)
end
gui.register("pfm_window", gui.PFMWindow)

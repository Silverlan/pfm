-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local MARGIN_SIZE = 12

util.register_class("gui.PFMWindow", gui.Base)
function gui.PFMWindow:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(256, 128)

	self:SetAutoSizeToContents(false, true)
	self:AddStyleClass("window")

	local mainBox = gui.create_vbox(self)
		:AddStyleClass("window__content-area")
	self.m_mainBox = mainBox

	local titleBar = gui.create_hbox(mainBox)
		:AddStyleClass("window__title-bar")

	local titleText = gui.create("WIText", titleBar)
	titleText:AddStyleClass("font_medium")
	titleText:SetVisible(false)
	self.m_titleText = titleText

	self.m_contents = mainBox

	-- Create frame
	local parent = self:GetParent()
	local pBg = gui.create("WIBase", parent, 0, 0, parent:GetWidth(), parent:GetHeight(), 0, 0, 1, 1)
	pBg:AddStyleClass("window__backdrop")
	self:RemoveElementOnRemoval(pBg)

	local pFrame = gui.create("WITransformable", parent)
	pFrame:SetDraggable(true)
	pFrame:SetResizable(false)
	pFrame:SetZPos(200000)
	pFrame:SetAutoSizeToContents(false, true)
	pFrame:SetWidth(512)
	self:RemoveElementOnRemoval(pFrame)

	self:SetParent(pFrame)

	pFrame:TrapFocus(true)
	pFrame:RequestFocus()

	local pDrag = pFrame:GetDragArea()
	-- pDrag:SetHeight(self.m_titleBar:GetHeight())
	pDrag:SetHorizontalAlignment(gui.ALIGNMENT_FILL)

	pFrame:SetAlignment(gui.ALIGNMENT_CENTER)
	self.m_frame = pFrame
end
function gui.PFMWindow:GetMarginSize() return MARGIN_SIZE end
function gui.PFMWindow:SetWindowSize(size, minSize, maxSize)
	if util.is_valid(self.m_frame) == false then
		return
	end
	minSize = minSize or size
	maxSize = maxSize or size
	--self.m_frame:SetMinSize(Vector2i(minSize.x, minSize.y))
	--self.m_frame:SetMaxSize(Vector2i(maxSize.x, maxSize.y))
	--self.m_frame:SetSize(size.x, size.y)
end
function gui.PFMWindow:GetFrame()
	return self.m_frame
end
function gui.PFMWindow:SetTitle(title)
	if util.is_valid(self.m_titleText) == false then return end
	self.m_titleText:SetVisible(#title > 0)
	self.m_titleText:SetText(title)
end
function gui.PFMWindow:GetContents()
	return self.m_contents
end
function gui.PFMWindow:OnSizeChanged(w, h)
	if util.is_valid(self.m_mainBox) == false then
		return
	end
	--self.m_mainBox:ApplyWidth(w)
end
gui.register("pfm_window", gui.PFMWindow)

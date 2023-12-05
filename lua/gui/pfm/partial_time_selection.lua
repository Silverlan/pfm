--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.PFMTriangle", gui.Base)
Element.POSITION_TOP_LEFT = 0
Element.POSITION_TOP_RIGHT = 1
Element.POSITION_BOTTOM_LEFT = 2
Element.POSITION_BOTTOM_RIGHT = 3
local g_triangleBuffers = {}
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	local elShape = gui.create("WIShape", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elShape:GetColorProperty():Link(self:GetColorProperty())
	self.m_elShape = elShape
end
function Element:SetTrianglePos(pos)
	self:InitializeBuffer(pos)
end
function Element:InitializeBuffer(pos)
	local buf = g_triangleBuffers[pos]
	if buf ~= nil then
		self.m_elShape:SetBuffer(buf, 3)
		return
	end
	local verts = {}
	if pos == Element.POSITION_TOP_LEFT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, -1))
	elseif pos == Element.POSITION_TOP_RIGHT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(1, 1))
		table.insert(verts, Vector2(1, -1))
	elseif pos == Element.POSITION_BOTTOM_LEFT then
		table.insert(verts, Vector2(-1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, 1))
	elseif pos == Element.POSITION_BOTTOM_RIGHT then
		table.insert(verts, Vector2(1, -1))
		table.insert(verts, Vector2(-1, 1))
		table.insert(verts, Vector2(1, 1))
	end
	self.m_elShape:ClearVertices()
	for _, v in ipairs(verts) do
		self.m_elShape:AddVertex(v)
	end
	self.m_elShape:Update()
	g_triangleBuffers[pos] = self.m_elShape:GetBuffer()
end
gui.register("WIPFMTriangle", Element)

local Element = util.register_class("gui.PFMPartialTimeSelectionBar", gui.Base)
Element.POSITION_LEFT = 0
Element.POSITION_RIGHT = 1
local lineOffset = 16
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64 + lineOffset * 2)

	self.m_triTop = gui.create("WIPFMTriangle", self, 0, 0, self:GetWidth(), lineOffset, 0, 0, 1, 0)
	self.m_triBottom =
		gui.create("WIPFMTriangle", self, 0, self:GetHeight() - lineOffset, self:GetWidth(), lineOffset, 0, 1, 1, 1)

	self.m_centerBar = gui.create("WIRect", self, 0, lineOffset, 64, self:GetHeight() - lineOffset * 2, 0, 0, 1, 1)

	self.m_triTop:GetColorProperty():Link(self:GetColorProperty())
	self.m_triBottom:GetColorProperty():Link(self:GetColorProperty())
	self.m_centerBar:GetColorProperty():Link(self:GetColorProperty())

	local lineInner = gui.create("WIRect", self)
	lineInner:SetColor(Color.Black)
	self.m_lineInner = lineInner

	local lineOuter = gui.create("WIRect", self)
	lineOuter:SetColor(Color.White)
	self.m_lineOuter = lineOuter
end
function Element:SetBarPosition(pos)
	if pos == Element.POSITION_LEFT then
		self.m_triTop:SetTrianglePos(gui.PFMTriangle.POSITION_BOTTOM_RIGHT)
		self.m_triBottom:SetTrianglePos(gui.PFMTriangle.POSITION_TOP_RIGHT)

		self.m_lineInner:ClearAnchor()
		self.m_lineInner:SetPos(0, lineOffset)
		self.m_lineInner:SetSize(1, self:GetHeight() - lineOffset * 2)
		self.m_lineInner:SetAnchor(0, 0, 0, 1)

		self.m_lineOuter:ClearAnchor()
		self.m_lineOuter:SetPos(self:GetRight() - 1, 0)
		self.m_lineOuter:SetSize(1, self:GetHeight())
		self.m_lineOuter:SetAnchor(1, 0, 1, 1)
	elseif pos == Element.POSITION_RIGHT then
		self.m_triTop:SetTrianglePos(gui.PFMTriangle.POSITION_BOTTOM_LEFT)
		self.m_triBottom:SetTrianglePos(gui.PFMTriangle.POSITION_TOP_LEFT)

		self.m_lineInner:ClearAnchor()
		self.m_lineInner:SetPos(self:GetWidth() - 1, lineOffset)
		self.m_lineInner:SetSize(1, self:GetHeight() - lineOffset * 2)
		self.m_lineInner:SetAnchor(1, 0, 1, 1)

		self.m_lineOuter:ClearAnchor()
		self.m_lineOuter:SetPos(0, 0)
		self.m_lineOuter:SetSize(1, self:GetHeight())
		self.m_lineOuter:SetAnchor(0, 0, 0, 1)
	end
end
gui.register("WIPFMPartialTimeSelectionBar", Element)

local Element = util.register_class("gui.PFMPartialTimeSelection", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 256)

	self.m_leftBar = gui.create("WIPFMPartialTimeSelectionBar", self)
	self.m_leftBar:SetBarPosition(gui.PFMPartialTimeSelectionBar.POSITION_LEFT)
	self.m_leftBar:SetSize(64, self:GetHeight())
	self.m_leftBar:SetAnchor(0, 0, 0, 1)

	self.m_rightBar = gui.create("WIPFMPartialTimeSelectionBar", self)
	self.m_rightBar:SetBarPosition(gui.PFMPartialTimeSelectionBar.POSITION_RIGHT)
	self.m_rightBar:SetSize(64, self:GetHeight())
	self.m_rightBar:SetX(self:GetWidth() - 64)
	self.m_rightBar:SetAnchor(1, 0, 1, 1)

	self.m_centerBar = gui.create(
		"WIRect",
		self,
		self.m_leftBar:GetRight(),
		0,
		(self.m_rightBar:GetLeft() - self.m_leftBar:GetRight()),
		self:GetHeight()
	)
	self.m_centerBar:SetAnchor(0, 0, 1, 1)

	local col = Color(0, 64, 0, 255)
	self.m_leftBar:SetColor(col)
	self.m_rightBar:SetColor(col)
	self.m_centerBar:SetColor(col)
	self:SetAlpha(128)
end
function Element:SetInnerStartPosition(pos)
	self.m_leftBar:SetWidth(pos)
	self:UpdateCenterBar()
end
function Element:SetInnerEndPosition(pos)
	self.m_rightBar:SetWidth(pos)
	self:UpdateCenterBar()
end
function Element:UpdateCenterBar()
	self.m_centerBar:SetX(self.m_leftBar:GetRight())
	self.m_centerBar:SetWidth(self:GetWidth() - (self.m_leftBar:GetWidth() + self.m_rightBar:GetWidth()))
	self.m_centerBar:SetHeight(self:GetHeight())
	self.m_rightBar:SetX(self.m_centerBar:GetRight())
	self.m_leftBar:SetHeight(self:GetHeight())
	self.m_rightBar:SetHeight(self:GetHeight())
end
gui.register("WIPFMPartialTimeSelection", Element)

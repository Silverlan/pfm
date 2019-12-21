--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_grid.lua")
include("/gui/basetimelinegrid.lua")

util.register_class("gui.Grid",gui.Base)

gui.Grid.GRID_COLOR = Color(52,52,52)
function gui.Grid:__init()
	gui.Base.__init(self)
end
function gui.Grid:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)
	self.m_layers = {}

	self:CreateGridLayer(false,1,300)
	self:CreateGridLayer(true,1,300)

	self:CreateGridLayer(false,2,300 *10)
	self:CreateGridLayer(true,2,300 *10)
end
function gui.Grid:CreateGridLayer(horizontal,lineWidth,stride)
	local gridLayer = gui.create("WIGridLayer",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	gridLayer:SetHorizontal(horizontal)
	gridLayer:SetLineWidth(lineWidth)
	gridLayer:SetStrideInPixels(stride)
	gridLayer:SetColor(gui.Grid.GRID_COLOR)
	table.insert(self.m_layers,gridLayer)
	return gridLayer
end
function gui.Grid:SetZoomLevel(zoomLevel)
	for _,layer in ipairs(self.m_layers) do
		if(layer:IsValid()) then layer:SetZoomLevel(zoomLevel) end
	end
end
function gui.Grid:SetStartOffset(startOffset)
	for _,layer in ipairs(self.m_layers) do
		if(layer:IsValid()) then layer:SetStartOffset(startOffset) end
	end
end
function gui.Grid:Setup()

end
function gui.Grid:BuildGrid(curveValues)
	--[[local verts = {}
	self.m_xRange = Vector2(0,1)
	self.m_yRange = Vector2(0,20)

	for i=0,300 do
		table.insert(verts,Vector2(0,i))
		table.insert(verts,Vector2(1,i))
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 *#verts)
	local dsColors = util.DataStream(util.SIZEOF_VECTOR4 *#verts)
	for _,v in ipairs(verts) do
		ds:WriteVector2(v)
		if(_ %10 == 0) then
			dsColors:WriteVector4(Color.Yellow:ToVector4())
		else
			dsColors:WriteVector4(Color.Red:ToVector4())
		end
	end
	local buf = vulkan.util.allocate_temporary_buffer(ds)
	local colorBuffer = vulkan.util.allocate_temporary_buffer(dsColors)
	self:SetLineBuffer(buf,colorBuffer,#verts)]]
end
function gui.Grid:SetLineBuffer(buffer,colorBuffer,vertexCount)
	--[[self.m_lineBuffer = buffer
	self.m_colorBuffer = colorBuffer
	self.m_vertexCount = vertexCount]]
end
--function gui.Grid:OnDraw(w,h,pose)
	--[[if(self.m_shader == nil or self.m_lineBuffer == nil) then return end
	local parent = self:GetParent()
	local drawCmd = game.get_draw_command_buffer()
	local x,y,w,h = gui.get_render_scissor_rect()
	local color = self:GetColor()
	self.m_shader:Draw(drawCmd,self.m_lineBuffer,self.m_colorBuffer,self.m_vertexCount,self.m_xRange,self.m_yRange,color,x,y,w,h)]]
--end
gui.register("WIGrid",gui.Grid)

-----------

util.register_class("gui.GridLayer",gui.BaseTimelineGrid)

function gui.GridLayer:__init()
	gui.BaseTimelineGrid.__init(self)
end
function gui.GridLayer:OnInitialize()
	gui.BaseTimelineGrid.OnInitialize(self)

	self:SetShader("pfm_grid")
	--self:SetSize(128,128)
	--self.m_shader = shader.get("pfm_grid")
end
function gui.GridLayer:Setup()

end
function gui.GridLayer:BuildGrid(curveValues)
	--[[local verts = {}
	self.m_xRange = Vector2(0,1)
	self.m_yRange = Vector2(0,20)

	for i=0,300 do
		table.insert(verts,Vector2(0,i))
		table.insert(verts,Vector2(1,i))
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 *#verts)
	local dsColors = util.DataStream(util.SIZEOF_VECTOR4 *#verts)
	for _,v in ipairs(verts) do
		ds:WriteVector2(v)
		if(_ %10 == 0) then
			dsColors:WriteVector4(Color.Yellow:ToVector4())
		else
			dsColors:WriteVector4(Color.Red:ToVector4())
		end
	end
	local buf = vulkan.util.allocate_temporary_buffer(ds)
	local colorBuffer = vulkan.util.allocate_temporary_buffer(dsColors)
	self:SetLineBuffer(buf,colorBuffer,#verts)]]
end
function gui.GridLayer:SetLineBuffer(buffer,colorBuffer,vertexCount)
	--[[self.m_lineBuffer = buffer
	self.m_colorBuffer = colorBuffer
	self.m_vertexCount = vertexCount]]
end
--function gui.GridLayer:OnDraw(w,h,pose)
	--[[if(self.m_shader == nil or self.m_lineBuffer == nil) then return end
	local parent = self:GetParent()
	local drawCmd = game.get_draw_command_buffer()
	local x,y,w,h = gui.get_render_scissor_rect()
	local color = self:GetColor()
	self.m_shader:Draw(drawCmd,self.m_lineBuffer,self.m_colorBuffer,self.m_vertexCount,self.m_xRange,self.m_yRange,color,x,y,w,h)]]
--end
gui.register("WIGridLayer",gui.GridLayer)

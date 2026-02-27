-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/pfm/grid.lua")
include("/gui/timeline/base_timeline_grid.lua")
include("/gui/timeline/strip.lua")

util.register_class("gui.BaseGridLayer",gui.BaseTimelineGrid,gui.BaseAxis)
function gui.BaseGridLayer:OnInitialize()
	gui.BaseTimelineGrid.OnInitialize(self)

	self.m_axis = util.GraphAxis()

	self:SetLineWidth(1)
	self:SetColor(Color.Black)
	self:SetShader("pfm_grid")
	self:UpdateAxisStride()
end
function gui.BaseGridLayer:RebuildRenderCommandBuffer()
	if(self.m_shader == nil) then return end
	local pcb = prosper.PreparedCommandBuffer()

	local stride = self:GetUnitPixelStride() /self:GetPrimAxisExtents(self)
	if(self.m_shader:GetWrapper():Record(pcb,self:GetLineCount(),stride,self:GetColor(),self.m_yMultiplier,self.m_lineWidth,not self:IsHorizontal()) == false) then pcb = nil end
	self:SetRenderCommandBuffer(pcb)
end
function gui.BaseGridLayer:SetLineWidth(width) self.m_lineWidth = width end
function gui.BaseGridLayer:SetAxis(axis) self.m_axis = axis end
function gui.BaseGridLayer:GetAxis() return self.m_axis end
function gui.BaseGridLayer:SetHorizontal(horizontal)
	gui.BaseTimelineGrid.SetHorizontal(self,horizontal)
end
gui.register("base_grid_layer",gui.BaseGridLayer)

-------------

util.register_class("gui.GridLayer",gui.Base)
function gui.GridLayer:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,16)

	self.m_strip = gui.create("base_grid_layer",self,0,0,self:GetWidth(),6)
	self.m_strip:AddCallback("OnTimelinePropertiesChanged",function()
		self:CallCallbacks("OnTimelinePropertiesChanged")
	end)
end
function gui.GridLayer:SetStepSize(stepSize) self.m_strip:SetStepSize(stepSize) end
function gui.GridLayer:GetStepSize() return self.m_strip:GetStepSize() end
function gui.GridLayer:SetLineWidth(width) self.m_strip:SetLineWidth(width) end
function gui.GridLayer:GetTimelineStripGrid() return self.m_strip end
function gui.GridLayer:OnSizeChanged(w,h)
	self:ScheduleUpdate()
end
function gui.GridLayer:IsHorizontal() return self.m_strip:IsHorizontal() end
function gui.GridLayer:IsVertical() return self.m_strip:IsVertical() end
function gui.GridLayer:SetHorizontal(horizontal)
	self.m_strip:SetHorizontal(horizontal)
	self:SetPrimAxisExtents(self.m_strip,self:GetPrimAxisExtents(self))
	self:SetSecAxisExtents(self.m_strip,6)
end
function gui.GridLayer:SetAxis(axis)
	if(util.is_valid(self.m_strip) == false) then return end
	self.m_strip:SetAxis(axis)
end
function gui.GridLayer:GetAxis()
	if(util.is_valid(self.m_strip) == false) then return end
	return self.m_strip:GetAxis()
end
function gui.GridLayer:SetDataAxisInverted(inverted) self.m_dataAxisInverted = inverted end
function gui.GridLayer:IsDataAxisInverted() return self.m_dataAxisInverted or false end
function gui.GridLayer:OnUpdate()
	local w,h,offset = self.m_strip:CalcAxisBounds(self:IsHorizontal(),self:GetWidth(),self:GetHeight())
	self:SetPrimAxisExtents(self.m_strip,self:IsHorizontal() and w or h)
	self:SetSecAxisExtents(self.m_strip,self:IsHorizontal() and h or w)
	self:SetPrimAxisOffset(self.m_strip,offset)
	self.m_strip:Update()
end
function gui.GridLayer:SetPrimAxisExtents(...) return self.m_strip:SetPrimAxisExtents(...) end
function gui.GridLayer:GetPrimAxisExtents(...) return self.m_strip:GetPrimAxisExtents(...) end
function gui.GridLayer:SetSecAxisExtents(...) return self.m_strip:SetSecAxisExtents(...) end
function gui.GridLayer:GetSecAxisExtents(...) return self.m_strip:GetSecAxisExtents(...) end
function gui.GridLayer:SetPrimAxisOffset(...) return self.m_strip:SetPrimAxisOffset(...) end
function gui.GridLayer:GetPrimAxisOffset(...) return self.m_strip:GetPrimAxisOffset(...) end
function gui.GridLayer:SetSecAxisOffset(...) return self.m_strip:SetSecAxisOffset(...) end
function gui.GridLayer:GetSecAxisOffset(...) return self.m_strip:GetSecAxisOffset(...) end
gui.register("grid_layer",gui.GridLayer)

-------------

util.register_class("gui.Grid",gui.Base)
gui.Grid.GRID_COLOR = Color(52,52,52)
function gui.Grid:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)
	self.m_layers = {}

	self:CreateGridLayer(false,1,300)
	self:CreateGridLayer(false,1,300)

	self.m_timeLayer = self:CreateGridLayer(true,1,300)
end
function gui.Grid:GetTimeLayer() return self.m_timeLayer end
function gui.Grid:CreateGridLayer(horizontal,lineWidth,stride)
	local gridLayer = gui.create("grid_layer",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	gridLayer:SetHorizontal(horizontal)
	gridLayer:SetLineWidth(lineWidth)
	gridLayer:GetAxis():SetStrideInPixels(stride)
	gridLayer:SetColor(gui.Grid.GRID_COLOR)
	table.insert(self.m_layers,gridLayer)
	return gridLayer
end
function gui.Grid:SetXAxis(axis)
	self.m_layers[3]:SetAxis(axis)
end
function gui.Grid:SetYAxis(axis)
	self.m_layers[1]:SetAxis(axis)
	self.m_layers[2]:SetAxis(axis)
end
function gui.Grid:SetZoomLevelX(zoomLevel)
	self.m_layers[3]:GetAxis():SetZoomLevel(zoomLevel)
end
function gui.Grid:SetZoomLevelY(zoomLevel)
	self.m_layers[1]:GetAxis():SetZoomLevel(zoomLevel)
	self.m_layers[2]:GetAxis():SetZoomLevel(zoomLevel)
end
function gui.Grid:SetStartOffsetX(startOffset)
	self.m_layers[3]:GetAxis():SetStartOffset(startOffset)
end
function gui.Grid:SetStartOffsetY(startOffset)
	self.m_layers[1]:GetAxis():SetStartOffset(startOffset)
	self.m_layers[2]:GetAxis():SetStartOffset(startOffset)
end
function gui.Grid:OnUpdate()
	for _,layer in ipairs(self.m_layers) do
		layer:Update()
	end
end
gui.register("grid",gui.Grid)

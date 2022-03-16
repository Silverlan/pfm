--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_timeline.lua")
include("/graph_axis.lua")

util.register_class("gui.BaseTimelineGrid",gui.Base)

function gui.BaseTimelineGrid:__init()
	gui.Base.__init(self)
end
function gui.BaseTimelineGrid:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_startOffset = util.FloatProperty(0.0)
	self.m_zoomLevel = util.FloatProperty(0.0)

	local fOnPropsChanged = function() self:CallCallbacks("OnTimelinePropertiesChanged") end
	self.m_startOffset:AddCallback(fOnPropsChanged)
	self.m_zoomLevel:AddCallback(fOnPropsChanged)
	self:GetSizeProperty():AddCallback(fOnPropsChanged)

	self.m_axis = util.GraphAxis()
	self:SetHorizontal(false)
	self:SetYMultiplier(1.0)
	self.m_axis:SetStrideInPixels(30)
	self:SetLineWidth(1)
	self:SetSize(128,6)
	self.m_axis:SetZoomLevel(1)
	self.m_axis:SetStartOffset(0.0)
	self:ScheduleUpdate()
end
function gui.BaseTimelineGrid:GetAxis() return self.m_axis end
function gui.BaseTimelineGrid:SetYMultiplier(multiplier) self.m_yMultiplier = multiplier end
function gui.BaseTimelineGrid:SetHorizontal(horizontal)
	self.m_horizontal = horizontal
	self.m_primAxis = horizontal and "x" or "y"
	self.m_secAxis = horizontal and "y" or "x"
end
function gui.BaseTimelineGrid:IsHorizontal() return self.m_horizontal end
function gui.BaseTimelineGrid:IsVertical() return self:IsHorizontal() == false end
function gui.BaseTimelineGrid:SetShader(shaderName) self.m_shader = shader.get(shaderName) end
function gui.BaseTimelineGrid:SetLineWidth(lineWidth) self.m_lineWidth = lineWidth end
function gui.BaseTimelineGrid:GetLineWidth() return self.m_lineWidth end
function gui.BaseTimelineGrid:OnUpdate() self:RebuildRenderCommandBuffer() end
function gui.BaseTimelineGrid:GetLineCount()
	local w = self:GetPrimAxisExtents(self)
	local stridePerSecond = self:GetAxis():GetStridePerUnit() *self:GetAxis():GetZoomLevelMultiplier()
	local strideX = stridePerSecond /10.0
	return math.ceil(w /strideX)
end
function gui.BaseTimelineGrid:RebuildRenderCommandBuffer()
	if(self.m_shader == nil) then return end
	local pcb = prosper.PreparedCommandBuffer()
	if(self.m_shader:Record(pcb,self:GetLineCount(),self:GetAxis():GetStrideX(self:GetWidth()),self:GetColor(),4,self:GetLineWidth(),self:IsHorizontal()) == false) then pcb = nil end
	self:SetRenderCommandBuffer(pcb)
end
function gui.BaseTimelineGrid:SetPrimAxisExtents(el,ext)
	if(self.m_horizontal) then el:SetWidth(ext)
	else el:SetHeight(ext) end
end
function gui.BaseTimelineGrid:GetPrimAxisExtents(el)
	if(self.m_horizontal) then return el:GetWidth() end
	return el:GetHeight()
end
function gui.BaseTimelineGrid:SetSecAxisExtents(el,ext)
	if(self.m_horizontal) then el:SetHeight(ext)
	else el:SetWidth(ext) end
end
function gui.BaseTimelineGrid:GetSecAxisExtents(el)
	if(self.m_horizontal) then return el:GetHeight() end
	return el:GetWidth()
end
function gui.BaseTimelineGrid:SetPrimAxisOffset(el,off)
	if(self.m_horizontal) then el:SetX(off)
	else el:SetY(off) end
end
function gui.BaseTimelineGrid:GetPrimAxisOffset(el)
	if(self.m_horizontal) then return el:GetX() end
	return el:GetY()
end
function gui.BaseTimelineGrid:SetSecAxisOffset(el,off)
	if(self.m_horizontal) then el:SetY(off)
	else el:SetX(off) end
end
function gui.BaseTimelineGrid:GetSecAxisOffset(el)
	if(self.m_horizontal) then return el:GetY() end
	return el:GetX()
end

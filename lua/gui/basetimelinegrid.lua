--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_timeline.lua")

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

	self:SetYMultiplier(1.0)
	self:SetStrideInPixels(30)
	self:SetLineWidth(1)
	self:SetHorizontal(false)
	self:SetSize(128,6)
	self.m_timeFrame = udm.PFMTimeFrame()
	self:SetZoomLevel(1)
	self:SetStartOffset(0.0)
	self:Update()
end
function gui.BaseTimelineGrid:SetYMultiplier(multiplier) self.m_yMultiplier = multiplier end
function gui.BaseTimelineGrid:SetHorizontal(horizontal) self.m_horizontal = horizontal end
function gui.BaseTimelineGrid:IsHorizontal() return self.m_horizontal end
function gui.BaseTimelineGrid:IsVertical() return self:IsHorizontal() == false end
function gui.BaseTimelineGrid:SetShader(shaderName) self.m_shader = shader.get(shaderName) end
function gui.BaseTimelineGrid:SetLineWidth(lineWidth) self.m_lineWidth = lineWidth end
function gui.BaseTimelineGrid:GetLineWidth() return self.m_lineWidth end
function gui.BaseTimelineGrid:OnDraw(w,h,pose)
	if(self.m_shader == nil) then return end
	local parent = self:GetParent()
	local drawCmd = game.get_draw_command_buffer()
	local x,y,w,h = gui.get_render_scissor_rect()
	self.m_shader:Draw(drawCmd,pose,x,y,w,h,self:GetLineCount(),self:GetStrideX(),self:GetColor(),self.m_yMultiplier,self:GetLineWidth(),self:IsHorizontal())
end
function gui.BaseTimelineGrid:GetLineCount()
	local w = self:GetWidth()
	local stridePerSecond = self:GetStridePerUnit()
	local strideX = stridePerSecond /10.0
	return math.ceil(w /strideX)
end
function gui.BaseTimelineGrid:GetStrideX()
	local w = self:GetWidth()
	local stridePerSecond = self:GetStridePerUnit()
	local strideX = stridePerSecond /10.0
	return strideX /w
end
function gui.BaseTimelineGrid:SetZoomLevel(zoomLevel)
	zoomLevel = math.clamp(zoomLevel,-3,3)
	self.m_zoomLevel:Set(zoomLevel)
end
function gui.BaseTimelineGrid:GetZoomLevel() return self.m_zoomLevel:Get() end
function gui.BaseTimelineGrid:GetZoomLevelProperty() return self.m_zoomLevel end
function gui.BaseTimelineGrid:GetUnitZoomLevel() return self:GetZoomLevel() %1.0 end
function gui.BaseTimelineGrid:GetZoomLevelMultiplier() return 10 ^math.floor(self:GetZoomLevel()) end
function gui.BaseTimelineGrid:SetStartOffset(offset) self.m_startOffset:Set(offset) end
function gui.BaseTimelineGrid:GetStartOffset() return self.m_startOffset:Get() end
function gui.BaseTimelineGrid:GetStartOffsetProperty() return self.m_startOffset end
function gui.BaseTimelineGrid:GetEndOffset() return self:XOffsetToTimeOffset(self:GetRight()) end
function gui.BaseTimelineGrid:GetStridePerUnit() return (1.0 +(1.0 -self:GetUnitZoomLevel())) *self:GetStrideInPixels() end
function gui.BaseTimelineGrid:SetStrideInPixels(stride) self.m_strideInPixels = stride end
function gui.BaseTimelineGrid:GetStrideInPixels() return self.m_strideInPixels end
function gui.BaseTimelineGrid:TimeOffsetToXOffset(timeInSeconds)
	timeInSeconds = timeInSeconds -self:GetStartOffset() /self:GetZoomLevelMultiplier()
	return timeInSeconds *self:GetStridePerUnit()
end
function gui.BaseTimelineGrid:XOffsetToTimeOffset(x)
	x = x /self:GetStridePerUnit()
	return x +self:GetStartOffset() /self:GetZoomLevelMultiplier()
end

--[[
    Copyright (C) 2019  Florian Weischer

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
	self:SetYMultiplier(1.0)
	self.m_axis:SetStrideInPixels(30)
	self:SetLineWidth(1)
	self:SetHorizontal(false)
	self:SetSize(128,6)
	self.m_timeFrame = udm.PFMTimeFrame()
	self.m_axis:SetZoomLevel(1)
	self.m_axis:SetStartOffset(0.0)
	self:Update()
end
function gui.BaseTimelineGrid:GetAxis() return self.m_axis end
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
	self.m_shader:Draw(drawCmd,pose,x,y,w,h,self:GetLineCount(),self:GetAxis():GetStrideX(self:GetWidth()),self:GetColor(),self.m_yMultiplier,self:GetLineWidth(),self:IsHorizontal())
end
function gui.BaseTimelineGrid:GetLineCount()
	local w = self:GetWidth()
	local stridePerSecond = self:GetAxis():GetStridePerUnit()
	local strideX = stridePerSecond /10.0
	return math.ceil(w /strideX)
end

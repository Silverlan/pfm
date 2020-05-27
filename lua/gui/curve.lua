--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_curve.lua")

util.register_class("gui.Curve",gui.Base)

function gui.Curve:__init()
	gui.Base.__init(self)
end
function gui.Curve:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)
	self.m_shader = shader.get("pfm_curve")

	self:SetHorizontalRange(0,0)
	self:SetVerticalRange(0,0)
	self:EnableThinking()
end
function gui.Curve:GetHorizontalRange() return self.m_xRange end
function gui.Curve:GetVerticalRange() return self.m_yRange end
function gui.Curve:SetHorizontalRange(min,max)
	self.m_xRange = Vector2(min,max)
end
function gui.Curve:SetVerticalRange(min,max)
	self.m_yRange = Vector2(min,max)
end
function gui.Curve:OnThink()
	local range = self:GetHorizontalRange()
	--range.x = range.x +0.004
	--range.y = range.y +0.004
	self:SetHorizontalRange(range.x,range.y)
end
function gui.Curve:BuildCurve(curveValues)
	if(#curveValues == 0) then return end
	--[[local verts = {}
	for _,v in ipairs(curveValues) do
		local x = (v[1] -self.m_xRange[1]) /(self.m_xRange[2] -self.m_xRange[1])
		local y = (v[2] -self.m_yRange[2]) /(self.m_yRange[1] -self.m_yRange[2])
		table.insert(verts,Vector2(x,y))
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 *#verts)
	for _,v in ipairs(verts) do
		ds:WriteVector2(v *2 -Vector2(1,1))
	end
	local buf = prosper.util.allocate_temporary_buffer(ds)
	self:SetLineBuffer(buf,#verts)]]
	local verts = {}
	for _,v in ipairs(curveValues) do
		table.insert(verts,Vector2(v[1],v[2]))
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 *#verts)
	for _,v in ipairs(verts) do
		ds:WriteVector2(v)
	end
	local buf = prosper.util.allocate_temporary_buffer(ds)
	self:SetLineBuffer(buf,#verts)
end
function gui.Curve:SetLineBuffer(buffer,vertexCount)
	self.m_lineBuffer = buffer
	self.m_vertexCount = vertexCount
end
function gui.Curve:OnDraw(drawInfo,pose)
	if(self.m_shader == nil or self.m_lineBuffer == nil) then return end
	local parent = self:GetParent()
	local drawCmd = game.get_draw_command_buffer()
	local x,y,w,h = gui.get_render_scissor_rect()
	local color = self:GetColor()
	self.m_shader:Draw(drawCmd,self.m_lineBuffer,self.m_vertexCount,self.m_xRange,self.m_yRange,color,x,y,w,h)
end
gui.register("WICurve",gui.Curve)

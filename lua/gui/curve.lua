--[[
    Copyright (C) 2021 Silverlan

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
	-- self:EnableThinking()
end
function gui.Curve:RebuildRenderCommandBuffer()
	local pcb = prosper.PreparedCommandBuffer()
	if(self.m_shader:Record(pcb,self.m_lineBuffer,self.m_vertexCount,self.m_xRange,self.m_yRange,self:GetColor()) == false) then pcb = nil end

	self:SetRenderCommandBuffer(pcb)
end
function gui.Curve:GetHorizontalRange() return self.m_xRange end
function gui.Curve:GetVerticalRange() return self.m_yRange end
function gui.Curve:SetHorizontalRange(min,max)
	self.m_xRange = Vector2(min,max)
	if(self.m_lineBuffer ~= nil) then self:RebuildRenderCommandBuffer() end
end
function gui.Curve:SetVerticalRange(min,max)
	self.m_yRange = Vector2(min,max)
	if(self.m_lineBuffer ~= nil) then self:RebuildRenderCommandBuffer() end
end
function gui.Curve:BuildCurve(curveValues)
	if(#curveValues == 0) then return end

	local verts = {}
	for _,v in ipairs(curveValues) do
		table.insert(verts,Vector2(v[1],v[2]))
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 *#verts)
	for _,v in ipairs(verts) do
		ds:WriteVector2(v)
	end
	local buf = prosper.util.allocate_temporary_buffer(ds) -- TODO: Manage our own buffer
	self:SetLineBuffer(buf,#verts)
end
function gui.Curve:SetLineBuffer(buffer,vertexCount)
	self.m_lineBuffer = buffer
	self.m_vertexCount = vertexCount
	self:RebuildRenderCommandBuffer()
end
gui.register("WICurve",gui.Curve)

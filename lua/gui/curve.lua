--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_curve.lua")

util.register_class("gui.Curve", gui.Base)

local g_updateBufCmd
local g_curveCount = 0
function gui.Curve:__init()
	gui.Base.__init(self)
	g_curveCount = g_curveCount + 1
end
function gui.Curve:__finalize()
	g_curveCount = g_curveCount - 1
	if g_curveCount == 0 then
		-- Don't need the command buffer anymore
		g_updateBufCmd = nil
	end
end
function gui.Curve:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 128)
	self.m_shader = shader.get("pfm_curve")

	self:SetHorizontalRange(0, 0)
	self:SetVerticalRange(0, 0)
	self:SetLineWidth(2.2)
	-- self:EnableThinking()
end
function gui.Curve:RebuildRenderCommandBuffer()
	local pcb = prosper.PreparedCommandBuffer()
	if
		self.m_shader:GetWrapper():Record(
			pcb,
			self.m_lineBuffer,
			self.m_vertexCount,
			self.m_lineWidth,
			self.m_xRange,
			self.m_yRange,
			self:GetColor()
		) == false
	then
		pcb = nil
	end

	self:SetRenderCommandBuffer(pcb)
end
function gui.Curve:SetLineWidth(lineWidth)
	self.m_lineWidth = lineWidth
end
function gui.Curve:GetLineWidth()
	return self.m_lineWidth
end
function gui.Curve:GetHorizontalRange()
	return self.m_xRange
end
function gui.Curve:GetVerticalRange()
	return self.m_yRange
end
function gui.Curve:SetHorizontalRange(min, max)
	self.m_xRange = Vector2(min, max)
	if self.m_lineBuffer ~= nil then
		self:RebuildRenderCommandBuffer()
	end
end
function gui.Curve:CoordinatesToValues(x, y)
	x = x / self:GetWidth()
	y = y / self:GetHeight()
	local xRange = self.m_xRange
	local yRange = self.m_yRange
	local xVal = x * (xRange.y - xRange.x) + xRange.x
	local yVal = y * (yRange.x - yRange.y) + yRange.y
	return Vector2(xVal, yVal)
end
function gui.Curve:ValueToNormalizedCoordinates(xVal, yVal)
	local xRange = self.m_xRange
	local yRange = self.m_yRange
	local x = (xVal - xRange.x) / (xRange.y - xRange.x)
	local y = (yVal - yRange.y) / (yRange.x - yRange.y)
	return Vector2(x, y)
end
function gui.Curve:ValueToUiCoordinates(xVal, yVal)
	local c = self:ValueToNormalizedCoordinates(xVal, yVal)
	c.x = c.x * self:GetWidth()
	c.y = c.y * self:GetHeight()
	return c
end
function gui.Curve:SetVerticalRange(min, max)
	self.m_yRange = Vector2(min, max)
	if self.m_lineBuffer ~= nil then
		self:RebuildRenderCommandBuffer()
	end
end
function gui.Curve:UpdateCurveValue(i, xVal, yVal)
	if self.m_lineBuffer == nil then
		return
	end
	local offset = util.SIZEOF_VECTOR2 * i

	local buf = self.m_lineBuffer
	g_updateBufCmd = g_updateBufCmd or prosper.create_primary_command_buffer()
	local cmd = g_updateBufCmd
	cmd:StartRecording(false, false)
	cmd:RecordBufferBarrier(
		buf,
		prosper.PIPELINE_STAGE_HOST_BIT,
		prosper.PIPELINE_STAGE_VERTEX_INPUT_BIT,
		prosper.ACCESS_HOST_WRITE_BIT,
		prosper.ACCESS_VERTEX_ATTRIBUTE_READ_BIT
	)
	cmd:RecordUpdateBuffer(buf, offset, udm.TYPE_VECTOR2, Vector2(xVal, yVal))
	cmd:RecordBufferBarrier(
		buf,
		prosper.PIPELINE_STAGE_VERTEX_INPUT_BIT,
		prosper.PIPELINE_STAGE_HOST_BIT,
		prosper.ACCESS_VERTEX_ATTRIBUTE_READ_BIT,
		prosper.ACCESS_HOST_WRITE_BIT
	)
	cmd:Flush()
end
function gui.Curve:BuildCurve(curveValues)
	if #curveValues == 0 then
		return
	end

	local verts = {}
	if #curveValues > 0 and util.get_type_name(curveValues[1]) == "Vector2" then
		verts = table.copy(curveValues)
	else
		for _, v in ipairs(curveValues) do
			table.insert(verts, Vector2(v[1], v[2]))
		end
	end

	local ds = util.DataStream(util.SIZEOF_VECTOR2 * #verts)
	for _, v in ipairs(verts) do
		ds:WriteVector2(v)
	end
	local buf = prosper.util.allocate_temporary_buffer(ds) -- TODO: Manage our own buffer
	self:SetLineBuffer(buf, #verts)
end
function gui.Curve:SetLineBuffer(buffer, vertexCount)
	self.m_lineBuffer = buffer
	self.m_vertexCount = vertexCount
	self:RebuildRenderCommandBuffer()
end
gui.register("WICurve", gui.Curve)

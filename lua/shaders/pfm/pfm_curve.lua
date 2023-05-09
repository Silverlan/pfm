--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMCurve", shader.BaseGUI)

shader.PFMCurve.FragmentShader = "pfm/fs_curve"
shader.PFMCurve.VertexShader = "pfm/vs_curve"

local PUSH_CONSTANT_SIZE = util.SIZEOF_MAT4 + util.SIZEOF_VECTOR4 + util.SIZEOF_VECTOR2 * 2 + util.SIZEOF_INT

function shader.PFMCurve:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGUI.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
	})

	pipelineInfo:AttachPushConstantRange(0, PUSH_CONSTANT_SIZE, prosper.SHADER_STAGE_VERTEX_BIT)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_STRIP)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT, true)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMCurve:Record(pcb, vertexBuffer, vertexCount, lineWidth, xRange, yRange, color)
	local shader = self:GetShader()
	if shader:IsValid() == false then
		return false
	end

	local dsPushConstants = util.DataStream(PUSH_CONSTANT_SIZE - util.SIZEOF_MAT4 - util.SIZEOF_INT)
	dsPushConstants:Seek(0)
	dsPushConstants:WriteVector4(color:ToVector4())
	dsPushConstants:WriteVector2(xRange)
	dsPushConstants:WriteVector2(yRange)

	local DynArg = prosper.PreparedCommandBuffer.DynArg
	self:RecordBeginDraw(pcb)
	pcb:RecordSetLineWidth(lineWidth)
	shader:RecordBindVertexBuffers(pcb, { vertexBuffer })
	shader:RecordPushConstants(pcb, udm.TYPE_MAT4, DynArg("matDraw"))
	shader:RecordPushConstants(pcb, dsPushConstants, util.SIZEOF_MAT4)
	shader:RecordPushConstants(
		pcb,
		udm.TYPE_UINT32,
		DynArg("viewportSize"),
		util.SIZEOF_MAT4 + dsPushConstants:GetSize()
	)
	shader:RecordDraw(pcb, vertexCount)
	shader:RecordEndDraw(pcb)
	return true
end
shader.register("pfm_curve", shader.PFMCurve)

-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.PFMCurve", shader.BaseGUI)

shader.PFMCurve.FragmentShader = "programs/pfm/curve"
shader.PFMCurve.VertexShader = "programs/pfm/curve"

local PUSH_CONSTANT_SIZE = util.SIZEOF_MAT4 + util.SIZEOF_VECTOR4 + util.SIZEOF_VECTOR2 * 2 + util.SIZEOF_INT

function shader.PFMCurve:InitializeShaderResources()
	shader.BaseGUI.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
	})
	self:AttachPushConstantRange(
		0,
		PUSH_CONSTANT_SIZE,
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function shader.PFMCurve:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGUI.InitializePipeline(self, pipelineInfo, pipelineIdx)

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

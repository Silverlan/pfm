-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.PFMTimeline", shader.BaseGUI)

shader.PFMTimeline.FragmentShader = "programs/pfm/timeline"
shader.PFMTimeline.VertexShader = "programs/pfm/timeline"

local PUSH_CONSTANT_SIZE = util.SIZEOF_MAT4
	+ util.SIZEOF_VECTOR4
	+ util.SIZEOF_INT
	+ util.SIZEOF_FLOAT
	+ util.SIZEOF_FLOAT
	+ util.SIZEOF_INT
	+ util.SIZEOF_INT

function shader.PFMTimeline:InitializeShaderResources()
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
function shader.PFMTimeline:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGUI.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_SCISSOR_BIT, true)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMTimeline:Record(pcb, lineCount, strideX, color, yMultiplier, horizontal)
	local shader = self:GetShader()
	if shader:IsValid() == false then
		return false
	end

	local dsPushConstants = util.DataStream(PUSH_CONSTANT_SIZE - util.SIZEOF_MAT4 - util.SIZEOF_INT)
	dsPushConstants:Seek(0)
	dsPushConstants:WriteVector4(color:ToVector4())
	dsPushConstants:WriteUInt32(lineCount)
	dsPushConstants:WriteFloat(strideX * 2.0)
	dsPushConstants:WriteFloat(yMultiplier)
	dsPushConstants:WriteUInt32(horizontal and 1 or 0)

	local vertexBuffer = prosper.util.get_line_vertex_buffer()
	local DynArg = prosper.PreparedCommandBuffer.DynArg
	self:RecordBeginDraw(pcb)
	shader:RecordBindVertexBuffers(pcb, { vertexBuffer })
	shader:RecordPushConstants(pcb, udm.TYPE_MAT4, DynArg("matDraw"))
	shader:RecordPushConstants(pcb, dsPushConstants, util.SIZEOF_MAT4)
	shader:RecordPushConstants(
		pcb,
		udm.TYPE_UINT32,
		DynArg("viewportSize"),
		util.SIZEOF_MAT4 + dsPushConstants:GetSize()
	)
	shader:RecordDraw(pcb, 2, lineCount)
	shader:RecordEndDraw(pcb)
	return true
end
shader.register("pfm_timeline", shader.PFMTimeline)

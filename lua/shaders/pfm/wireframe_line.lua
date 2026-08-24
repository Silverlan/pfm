-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Shader = util.register_class("shader.PFMWireframeLine", shader.BaseTexturedLit3D)

Shader.FragmentShader = "programs/pfm/selection/selection"
Shader.VertexShader = "programs/pfm/selection/selection"
Shader.ShaderMaterial = "basic"
function Shader:Initialize()
	self:SetDepthPrepassEnabled(false)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function Shader:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetLineWidth(2)
	pipelineInfo:SetDepthWritesEnabled(true)
end
function Shader:InitializeGfxPipelinePushConstantRanges()
	self:AttachPushConstantRange(
		0,
		shader.TexturedLit3D.PUSH_CONSTANTS_SIZE + self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function Shader:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(Color.White:ToVector4())
	self:RecordPushConstants(self.m_dsPushConstants, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("pfm_wireframe_line", Shader)

local Shader = util.register_class("shader.PFMWireframeLineNoDepth", shader.PFMWireframeLine)

function Shader:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.PFMWireframeLine.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(false)
end
shader.register("pfm_wireframe_line_no_depth", Shader)

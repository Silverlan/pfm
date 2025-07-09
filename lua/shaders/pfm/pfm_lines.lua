-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.PFMLines", shader.BaseGraphics)

shader.PFMLines.FragmentShader = "programs/pfm/lines/lines"
shader.PFMLines.VertexShader = "programs/pfm/lines/lines"

function shader.PFMLines:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 + util.SIZEOF_VECTOR4)
end
function shader.PFMLines:InitializeRenderPass(pipelineIdx)
	return { shader.Scene3D.get_render_pass() }
end
function shader.PFMLines:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT), -- Position
	})

	self:AttachPushConstantRange(
		0,
		self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_VERTEX_BIT, prosper.SHADER_STAGE_FRAGMENT_BIT)
	)
end
function shader.PFMLines:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_STRIP)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetCommonAlphaBlendProperties()
	pipelineInfo:SetLineWidth(2)
end
function shader.PFMLines:Draw(drawCmd, vertexBuffer, numVerts, mvp)
	local bindState = shader.BindState(drawCmd)
	local baseShader = self:GetShader()
	if baseShader:IsValid() == false or baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	baseShader:RecordBindVertexBuffers(bindState, { vertexBuffer })

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(mvp)
	self.m_dsPushConstants:WriteVector4(Color(95, 95, 95):ToVector4())

	baseShader:RecordPushConstants(bindState, self.m_dsPushConstants)
	baseShader:RecordDraw(bindState, numVerts)
	baseShader:RecordEndDraw(bindState)
end
shader.register("pfm_lines", shader.PFMLines)

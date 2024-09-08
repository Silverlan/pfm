local Shader = util.register_class("shader.PFMWireframeLine", shader.BaseTexturedLit3D)

Shader.FragmentShader = "programs/pfm/selection/selection"
Shader.VertexShader = "programs/pfm/selection/selection"
Shader.LINE_COLOR = Color(0, 128, 255, 16):ToVector4()
Shader.SetLineColor = function(color)
	Shader.LINE_COLOR = color:ToVector4()
end
function Shader:Initialize()
	self:SetDepthPrepassEnabled(false)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function Shader:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
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
	self.m_dsPushConstants:WriteVector4(Color.White:ToVector4()) --Shader.LINE_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("pfm_wireframe_line", Shader)

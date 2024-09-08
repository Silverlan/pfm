util.register_class("shader.PFMSelectionWireframe", shader.BaseTexturedLit3D)

shader.PFMSelectionWireframe.FragmentShader = "programs/pfm/selection/selection"
shader.PFMSelectionWireframe.VertexShader = "programs/pfm/selection/selection"
shader.PFMSelectionWireframe.SELECTION_COLOR = Color(255, 255, 0, 16):ToVector4()
shader.PFMSelectionWireframe.SetSelectionColor = function(color)
	shader.PFMSelectionWireframe.SELECTION_COLOR = color:ToVector4()
end
function shader.PFMSelectionWireframe:__init()
	shader.BaseTexturedLit3D.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.PFMSelectionWireframe:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetLineWidth(1)
end
function shader.PFMSelectionWireframe:InitializeGfxPipelinePushConstantRanges()
	self:AttachPushConstantRange(
		0,
		shader.TexturedLit3D.PUSH_CONSTANTS_SIZE + self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function shader.PFMSelectionWireframe:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(shader.PFMSelectionWireframe.SELECTION_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants, shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("pfm_selection_wireframe", shader.PFMSelectionWireframe)

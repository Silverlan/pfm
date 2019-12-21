util.register_class("shader.PFMSelection",shader.BaseTexturedLit3D)

shader.PFMSelection.FragmentShader = "pfm/selection/fs_selection"
shader.PFMSelection.VertexShader = "pfm/selection/vs_selection"
shader.PFMSelection.SELECTION_COLOR = Color(0,128,255,16):ToVector4()
shader.PFMSelection.SetSelectionColor = function(color)
	shader.PFMSelection.SELECTION_COLOR = color:ToVector4()
end
function shader.PFMSelection:__init()
	shader.BaseTexturedLit3D.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.PFMSelection:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)

	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
end
function shader.PFMSelection:InitializeGfxPipelinePushConstantRanges(pipelineInfo,pipelineIdx)
	pipelineInfo:AttachPushConstantRange(0,shader.TexturedLit3D.PUSH_CONSTANTS_SIZE +self.m_dsPushConstants:GetSize(),bit.bor(vulkan.SHADER_STAGE_FRAGMENT_BIT,vulkan.SHADER_STAGE_VERTEX_BIT))
end
function shader.PFMSelection:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(shader.PFMSelection.SELECTION_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants,shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("pfm_selection",shader.PFMSelection)

util.register_class("shader.PFMWireframeLine",shader.BaseTexturedLit3D)

shader.PFMWireframeLine.FragmentShader = "pfm/selection/fs_selection"
shader.PFMWireframeLine.VertexShader = "pfm/selection/vs_selection"
shader.PFMWireframeLine.LINE_COLOR = Color(0,128,255,16):ToVector4()
shader.PFMWireframeLine.SetLineColor = function(color)
	shader.PFMWireframeLine.LINE_COLOR = color:ToVector4()
end
function shader.PFMWireframeLine:__init()
	shader.BaseTexturedLit3D.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.PFMWireframeLine:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
end
function shader.PFMWireframeLine:InitializeGfxPipelinePushConstantRanges(pipelineInfo,pipelineIdx)
	pipelineInfo:AttachPushConstantRange(0,shader.TexturedLit3D.PUSH_CONSTANTS_SIZE +self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))
end
function shader.PFMWireframeLine:OnBindEntity(ent)
	local drawCmd = self:GetCurrentCommandBuffer()

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(Color.White:ToVector4())--shader.PFMWireframeLine.LINE_COLOR)
	self:RecordPushConstants(self.m_dsPushConstants,shader.TexturedLit3D.PUSH_CONSTANTS_USER_DATA_OFFSET)
end
shader.register("pfm_wireframe_line",shader.PFMWireframeLine)

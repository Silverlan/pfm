util.register_class("shader.PFMFlat",shader.BaseTexturedLit3D)

shader.PFMFlat.FragmentShader = "pfm/fs_gizmo"
shader.PFMFlat.VertexShader = "world/vs_textured"
function shader.PFMFlat:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function shader.PFMFlat:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)

	-- TODO
	-- pipelineInfo:SetDepthBiasEnabled(true)
	-- pipelineInfo:SetDepthBiasConstantFactor(-1)
end
shader.register("pfm_gizmo",shader.PFMFlat)

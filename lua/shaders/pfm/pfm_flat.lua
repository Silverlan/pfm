util.register_class("shader.PFMFlat",shader.BaseTexturedLit3D)

shader.PFMFlat.FragmentShader = "pfm/flat/fs_flat"
shader.PFMFlat.VertexShader = "pfm/flat/vs_flat"
function shader.PFMFlat:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function shader.PFMFlat:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(false)
end
shader.register("pfm_flat",shader.PFMFlat)

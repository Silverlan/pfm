util.register_class("shader.PFMFlat", shader.BaseTexturedLit3D)

shader.PFMFlat.FragmentShader = "pfm/fs_gizmo"
shader.PFMFlat.VertexShader = "world/vs_textured"
function shader.PFMFlat:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function shader.PFMFlat:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
end
shader.register("pfm_gizmo", shader.PFMFlat)

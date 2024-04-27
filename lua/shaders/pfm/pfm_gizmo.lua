util.register_class("shader.PFMGizmo", shader.BaseTexturedLit3D)

shader.PFMGizmo.FragmentShader = "pfm/fs_gizmo"
shader.PFMGizmo.VertexShader = "world/vs_textured"
function shader.PFMGizmo:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function shader.PFMGizmo:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
end
shader.register("pfm_gizmo", shader.PFMGizmo)

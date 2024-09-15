util.register_class("shader.PFMGizmo", shader.BaseTexturedLit3D)

shader.PFMGizmo.FragmentShader = "programs/pfm/gizmo"
shader.PFMGizmo.VertexShader = "programs/scene/textured"
shader.PFMGizmo.ShaderMaterial = "albedo"
function shader.PFMGizmo:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function shader.PFMGizmo:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
end
shader.register("pfm_gizmo", shader.PFMGizmo)

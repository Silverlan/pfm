local Shader = util.register_class("shader.PFMFlat", shader.BaseTexturedLit3D)

Shader.FragmentShader = "programs/pfm/flat/flat"
Shader.VertexShader = "programs/pfm/flat/flat"
Shader.ShaderMaterial = "albedo"
function Shader:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(false)
end
shader.register("pfm_flat", Shader)

local ShaderWdt = util.register_class("shader.PFMFlatWdt", Shader)
function ShaderWdt:InitializePipeline(pipelineInfo, pipelineIdx)
	Shader.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetDepthTestEnabled(true)
end
shader.register("pfm_flat_wdt", ShaderWdt)

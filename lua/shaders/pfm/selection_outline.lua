-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Shader = util.register_class("shader.PfmSelectionOutline", shader.BaseTexturedLit3D)

Shader.FragmentShader = "programs/pfm/selection_outline"
Shader.VertexShader = "programs/pfm/selection_outline"
Shader.ShaderMaterial = "pfm_selection_outline"

function Shader:Initialize() end
function Shader:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetFrontFace(prosper.FRONT_FACE_CLOCKWISE)
end
function Shader:InitializeGfxPipelinePushConstantRanges()
	shader.BaseTexturedLit3D.InitializeGfxPipelinePushConstantRanges(self)
end
shader.register("pfm_selection_outline", Shader)

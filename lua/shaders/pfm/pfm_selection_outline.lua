--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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

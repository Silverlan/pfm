--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Shader = util.register_class("shader.PfmSelectionOutline",shader.BaseTexturedLit3D)

Shader.FragmentShader = "pfm/fs_selection_outline"
Shader.VertexShader = "pfm/vs_selection_outline"

function Shader:__init()
	shader.BaseTexturedLit3D.__init(self)
end
function Shader:Initialize()
end
function Shader:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseTexturedLit3D.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:SetFrontFace(prosper.FRONT_FACE_CLOCKWISE)
end
function Shader:InitializeGfxPipelinePushConstantRanges(pipelineInfo,pipelineIdx)
end
function Shader:InitializeMaterialDescriptorSet(mat)
	local descSet = self:GetShader():CreateDescriptorSet(self:GetShader():GetMaterialDescriptorSetIndex())
	self:InitializeMaterialBuffer(descSet,mat)
	return descSet
end
function Shader:InitializeMaterialData(mat,matData)
	shader.BaseTexturedLit3D.InitializeMaterialData(self,mat,matData)

	local data = mat:GetDataBlock()
	matData.glowScale = data:GetFloat("glow_factor",0.0)
	matData.parallaxHeightScale = data:GetFloat("outline_width",0.005)
	matData.aoFactor = data:GetFloat("scale_by_distance_factor",1)
end
shader.register("pfm_selection_outline",Shader)

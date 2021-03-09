--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMSceneComposition",shader.BaseGraphics)

shader.PFMSceneComposition.FragmentShader = "pfm/post_processing/fs_scene_composition"
shader.PFMSceneComposition.VertexShader = "screen/vs_screen_uv"

shader.PFMSceneComposition.DESCRIPTOR_SET_TEXTURE = 0
shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR = 0
shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM = 1
shader.PFMSceneComposition.TEXTURE_BINDING_GLOW = 2

function shader.PFMSceneComposition:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_FLOAT *2)
end
function shader.PFMSceneComposition:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT), -- Base HDR image
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT), -- Bloom
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT) -- Glow
	}))
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),prosper.SHADER_STAGE_FRAGMENT_BIT)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMSceneComposition:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		prosper.FORMAT_R16G16B16A16_SFLOAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	)
	return {prosper.create_render_pass(rpCreateInfo)}
end
function shader.PFMSceneComposition:Draw(drawCmd,dsTex,bloomScale,glowScale)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	local buf,numVerts = prosper.util.get_square_vertex_uv_buffer()
	self:RecordBindVertexBuffers({buf})
	self:RecordBindDescriptorSet(dsTex)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteFloat(bloomScale)
	self.m_dsPushConstants:WriteFloat(glowScale)
	self:RecordPushConstants(self.m_dsPushConstants)

	self:RecordDraw(prosper.util.get_square_vertex_count())
	self:RecordEndDraw()
end
shader.register("pfm_scene_composition",shader.PFMSceneComposition)

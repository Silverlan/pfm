-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.PFMSceneComposition", shader.BaseGraphics)

shader.PFMSceneComposition.FragmentShader = "programs/pfm/post_processing/scene_composition"
shader.PFMSceneComposition.VertexShader = "programs/image/noop_uv"

shader.PFMSceneComposition.DESCRIPTOR_SET_TEXTURE = 0
shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR = 0
shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM = 1
shader.PFMSceneComposition.TEXTURE_BINDING_GLOW = 2

function shader.PFMSceneComposition:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_FLOAT * 2)
end
function shader.PFMSceneComposition:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- UV
	})
	self:AttachDescriptorSetInfo(shader.DescriptorSetInfo("TEXTURES", {
		shader.DescriptorSetBinding(
			"HDR_IMAGE",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			prosper.SHADER_STAGE_FRAGMENT_BIT
		),
		shader.DescriptorSetBinding(
			"BLOOM",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			prosper.SHADER_STAGE_FRAGMENT_BIT
		),
		shader.DescriptorSetBinding(
			"GLOW",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			prosper.SHADER_STAGE_FRAGMENT_BIT
		),
	}))
	self:AttachPushConstantRange(0, self.m_dsPushConstants:GetSize(), prosper.SHADER_STAGE_FRAGMENT_BIT)
end
function shader.PFMSceneComposition:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMSceneComposition:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		prosper.FORMAT_R16G16B16A16_SFLOAT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,
		prosper.ATTACHMENT_STORE_OP_STORE
	)
	return { prosper.create_render_pass(rpCreateInfo) }
end
function shader.PFMSceneComposition:Draw(drawCmd, dsTex, bloomScale, glowScale)
	local bindState = shader.BindState(drawCmd)
	local baseShader = self:GetShader()
	if baseShader:IsValid() == false or baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	local buf, numVerts = prosper.util.get_square_vertex_uv_buffer()
	baseShader:RecordBindVertexBuffers(bindState, { buf })
	baseShader:RecordBindDescriptorSet(bindState, dsTex)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteFloat(bloomScale)
	self.m_dsPushConstants:WriteFloat(glowScale)
	baseShader:RecordPushConstants(bindState, self.m_dsPushConstants)

	baseShader:RecordDraw(bindState, prosper.util.get_square_vertex_count())
	baseShader:RecordEndDraw(bindState)
end
shader.register("pfm_scene_composition", shader.PFMSceneComposition)

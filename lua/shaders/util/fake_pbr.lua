--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.FakePbr",shader.BaseGraphics)
local Shader = shader.FakePbr

Shader.FragmentShader = "util/fs_pbr_to_fake_pbr"
Shader.VertexShader = "screen/vs_screen_uv"

Shader.DESCRIPTOR_SET_TEXTURE = 0
Shader.TEXTURE_BINDING_ALBEDO_MAP = 0
Shader.TEXTURE_BINDING_NORMAL_MAP = 1
Shader.TEXTURE_BINDING_RMA_MAP = 2

Shader.RENDER_PASS_ALBEDO_MAP_FORMAT = prosper.FORMAT_R8G8B8A8_UNORM
Shader.RENDER_PASS_CH_MASK_FORMAT = prosper.FORMAT_R8G8B8A8_UNORM
Shader.RENDER_PASS_EXPONENT_MAP_FORMAT = prosper.FORMAT_R8G8B8A8_UNORM
Shader.RENDER_PASS_NORMAL_MAP_FORMAT = prosper.FORMAT_R32G32B32A32_SFLOAT

function Shader:__init()
	shader.BaseGraphics.__init(self)
end
function Shader:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT), -- Albedo map
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT), -- Normal map
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT) -- RMA map
	}))

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetColorBlendAttachmentProperties(
		0 --[[ attId ]],true --[[ blendingEnabled --]],
		prosper.BLEND_OP_ADD,prosper.BLEND_OP_ADD,
		prosper.BLEND_FACTOR_ONE,prosper.BLEND_FACTOR_ONE,
		prosper.BLEND_FACTOR_ONE,prosper.BLEND_FACTOR_ONE_MINUS_SRC_COLOR,
		bit.bor(prosper.COLOR_COMPONENT_R_BIT,prosper.COLOR_COMPONENT_G_BIT,prosper.COLOR_COMPONENT_B_BIT,prosper.COLOR_COMPONENT_A_BIT)
	)
end
function Shader:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		Shader.RENDER_PASS_ALBEDO_MAP_FORMAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	) -- Albedo map
	rpCreateInfo:AddAttachment(
		Shader.RENDER_PASS_CH_MASK_FORMAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	) -- CH Mask
	rpCreateInfo:AddAttachment(
		Shader.RENDER_PASS_EXPONENT_MAP_FORMAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	) -- Exponent Map
	rpCreateInfo:AddAttachment(
		Shader.RENDER_PASS_NORMAL_MAP_FORMAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	) -- Normal Map
	return {prosper.create_render_pass(rpCreateInfo)}
end
function Shader:Draw(drawCmd,dsTex)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	local buf,numVerts = prosper.util.get_square_vertex_uv_buffer()
	self:RecordBindVertexBuffers({buf})
	self:RecordBindDescriptorSet(dsTex)

	self:RecordDraw(prosper.util.get_square_vertex_count())
	self:RecordEndDraw()
end
shader.register("util_pbr_to_fake_pbr",Shader)

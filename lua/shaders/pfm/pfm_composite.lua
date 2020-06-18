--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMComposite",shader.BaseGraphics)

shader.PFMComposite.FragmentShader = "screen/fs_screen"
shader.PFMComposite.VertexShader = "screen/vs_screen_uv"

function shader.PFMComposite:__init()
	shader.BaseGraphics.__init(self)
end
function shader.PFMComposite:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT)
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
function shader.PFMComposite:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		prosper.FORMAT_R8G8B8A8_UNORM,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	)
	return {prosper.create_render_pass(rpCreateInfo)}
end
function shader.PFMComposite:Draw(drawCmd,dsTex)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	local buf,numVerts = prosper.util.get_square_vertex_uv_buffer()
	self:RecordBindVertexBuffers({buf})
	self:RecordBindDescriptorSet(dsTex)

	self:RecordDraw(prosper.util.get_square_vertex_count())
	self:RecordEndDraw()
end
shader.register("pfm_composite",shader.PFMComposite)

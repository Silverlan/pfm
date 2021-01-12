--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMTonemapping",shader.BaseGraphics)

shader.PFMTonemapping.FragmentShader = "pfm/post_processing/fs_tonemapping"
shader.PFMTonemapping.VertexShader = "wgui/vs_wgui_textured_cheap"

shader.PFMTonemapping.DESCRIPTOR_SET_TEXTURE = 0
shader.PFMTonemapping.TEXTURE_BINDING_HDR_COLOR = 0

shader.PFMTonemapping.TONE_MAPPING_WARD = shader.TONE_MAPPING_COUNT
shader.PFMTonemapping.TONE_MAPPING_FERWERDA = shader.PFMTonemapping.TONE_MAPPING_WARD +1
shader.PFMTonemapping.TONE_MAPPING_SCHLICK = shader.PFMTonemapping.TONE_MAPPING_FERWERDA +1
shader.PFMTonemapping.TONE_MAPPING_TUMBLIN_RUSHMEIER = shader.PFMTonemapping.TONE_MAPPING_SCHLICK +1
shader.PFMTonemapping.TONE_MAPPING_DRAGO = shader.PFMTonemapping.TONE_MAPPING_TUMBLIN_RUSHMEIER +1
shader.PFMTonemapping.TONE_MAPPING_REINHARD_DEVLIN = shader.PFMTonemapping.TONE_MAPPING_DRAGO +1
shader.PFMTonemapping.TONE_MAPPING_FILMLIC1 = shader.PFMTonemapping.TONE_MAPPING_REINHARD_DEVLIN +1
shader.PFMTonemapping.TONE_MAPPING_FILMLIC2 = shader.PFMTonemapping.TONE_MAPPING_FILMLIC1 +1
shader.PFMTonemapping.TONE_MAPPING_INSOMNIAC = shader.PFMTonemapping.TONE_MAPPING_FILMLIC2 +1

function shader.PFMTonemapping:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_FLOAT *2 +util.SIZEOF_INT *2 +util.SIZEOF_VECTOR4 +util.SIZEOF_FLOAT *3 +util.SIZEOF_FLOAT *5)
end
function shader.PFMTonemapping:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		prosper.FORMAT_R16G16B16A16_SFLOAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	)
	return {prosper.create_render_pass(rpCreateInfo)}
end
function shader.PFMTonemapping:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT) -- HDR image
	}))
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMTonemapping:Draw(drawCmd,mvp,dsTex,exposure,toneMapping,isInputImageGammaCorrected,luminance,args)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	local buf,numVerts = prosper.util.get_square_vertex_uv_buffer()
	self:RecordBindVertexBuffers({buf})
	self:RecordBindDescriptorSet(dsTex)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(mvp)
	self.m_dsPushConstants:WriteFloat(exposure)
	self.m_dsPushConstants:WriteInt32(toneMapping)

	self.m_dsPushConstants:WriteUInt32(isInputImageGammaCorrected and 1 or 0)
	self.m_dsPushConstants:WriteFloat(0.0) -- Placeholder

	local avgIntensity = luminance:GetAvgIntensity()
	self.m_dsPushConstants:WriteVector4(Vector4(avgIntensity.r,avgIntensity.g,avgIntensity.b,luminance:GetAvgLuminance()))
	self.m_dsPushConstants:WriteFloat(luminance:GetMinLuminance())
	self.m_dsPushConstants:WriteFloat(luminance:GetMaxLuminance())
	self.m_dsPushConstants:WriteFloat(luminance:GetAvgLuminanceLog())

	for _,arg in ipairs(args) do
		self.m_dsPushConstants:WriteFloat(arg)
	end
	self:RecordPushConstants(self.m_dsPushConstants)

	self:RecordDraw(prosper.util.get_square_vertex_count())
	self:RecordEndDraw()
end
shader.register("pfm_tonemapping",shader.PFMTonemapping)

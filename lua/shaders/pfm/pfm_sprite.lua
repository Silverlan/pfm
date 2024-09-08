--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMSprite", shader.BaseGraphics)

shader.PFMSprite.FragmentShader = "programs/pfm/sprite/sprite"
shader.PFMSprite.VertexShader = "programs/pfm/sprite/sprite"

function shader.PFMSprite:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 + util.SIZEOF_VECTOR4 * 2 + util.SIZEOF_VECTOR2)
end
function shader.PFMSprite:InitializeRenderPass(pipelineIdx)
	return { shader.Scene3D.get_render_pass() }
end
function shader.PFMSprite:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- UV
	})
	self:AttachDescriptorSetInfo(shader.DescriptorSetInfo("TEXTURE", {
		shader.DescriptorSetBinding(
			"TEXTURE",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			prosper.SHADER_STAGE_FRAGMENT_BIT
		),
	}))

	self:AttachPushConstantRange(
		0,
		self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_VERTEX_BIT, prosper.SHADER_STAGE_FRAGMENT_BIT)
	)
end
function shader.PFMSprite:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetCommonAlphaBlendProperties()
	pipelineInfo:SetLineWidth(4)
end
function shader.PFMSprite:Draw(drawCmd, origin, size, color, mvp)
	local baseShader = self:GetShader()
	if self.m_dsInitialized ~= true then
		self.m_dsInitialized = true
		local mat = game.load_material("pfm/bone_transform_path_node", false, true)
		local texInfo = (mat ~= nil) and mat:GetTextureInfo("albedo_map") or nil
		local tex = (texInfo ~= nil) and texInfo:GetTexture() or nil
		local vkTex = (tex ~= nil) and tex:GetVkTexture() or nil
		local ds = (vkTex ~= nil) and baseShader:CreateDescriptorSet(0) or nil
		if ds ~= nil then
			self.m_dsTex = ds
			ds:SetBindingTexture(0, vkTex)
		end
	end

	local bindState = shader.BindState(drawCmd)
	if baseShader:IsValid() == false or self.m_dsTex == nil or baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	local buf, numVerts = prosper.util.get_square_vertex_uv_buffer()
	baseShader:RecordBindVertexBuffers(bindState, { buf })
	baseShader:RecordBindDescriptorSet(bindState, self.m_dsTex)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(mvp)
	self.m_dsPushConstants:WriteVector4(Vector4(origin.x, origin.y, origin.z, 0.0))
	self.m_dsPushConstants:WriteVector4(color:ToVector4())
	self.m_dsPushConstants:WriteVector2(size)

	baseShader:RecordPushConstants(bindState, self.m_dsPushConstants)
	baseShader:RecordDraw(bindState, prosper.util.get_square_vertex_count())
	baseShader:RecordEndDraw(bindState)
end
shader.register("pfm_sprite", shader.PFMSprite)

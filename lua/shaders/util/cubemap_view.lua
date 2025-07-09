-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("shader.CubemapView", shader.BaseGraphics)

shader.CubemapView.FragmentShader = "programs/util/cubemap_view"
shader.CubemapView.VertexShader = "programs/util/cubemap_view"

shader.CubemapView.DESCRIPTOR_SET_TEXTURE = 0
shader.CubemapView.TEXTURE_BINDING_TEXTURE = 0

local PUSH_CONSTANT_SIZE = util.SIZEOF_MAT4

function shader.CubemapView:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- UV
	})
	self:AttachPushConstantRange(0, PUSH_CONSTANT_SIZE, prosper.SHADER_STAGE_VERTEX_BIT)
	self:AttachDescriptorSetInfo(shader.DescriptorSetInfo("TEXTURE", {
		shader.DescriptorSetBinding(
			"TEXTURE",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			prosper.SHADER_STAGE_FRAGMENT_BIT
		),
	}))
end
function shader.CubemapView:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.CubemapView:Record(drawCmd, ds, vp, vertexBuffer, vertexCount, lineWidth, xRange, yRange, color)
	local baseShader = self:GetShader()
	if baseShader:IsValid() == false then
		return false
	end

	local dsPushConstants = util.DataStream(PUSH_CONSTANT_SIZE)
	dsPushConstants:Seek(0)
	dsPushConstants:WriteMat4(vp)

	local DynArg = prosper.PreparedCommandBuffer.DynArg
	local bindState = shader.BindState(drawCmd)
	if baseShader:RecordBeginDraw(bindState) then
		baseShader:RecordBindDescriptorSet(bindState, ds, 0)
		baseShader:RecordBindVertexBuffers(bindState, { vertexBuffer })
		baseShader:RecordPushConstants(bindState, dsPushConstants)
		baseShader:RecordDraw(bindState, vertexCount)
		baseShader:RecordEndDraw(bindState)
	end
	return true
end
shader.register("cubemap_view", shader.CubemapView)

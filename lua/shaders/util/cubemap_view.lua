--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.CubemapView",shader.BaseGraphics)

shader.CubemapView.FragmentShader = "util/fs_cubemap_view"
shader.CubemapView.VertexShader = "util/vs_cubemap_view"

shader.CubemapView.DESCRIPTOR_SET_TEXTURE = 0
shader.CubemapView.TEXTURE_BINDING_TEXTURE = 0

local PUSH_CONSTANT_SIZE = util.SIZEOF_MAT4

function shader.CubemapView:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})

	pipelineInfo:AttachPushConstantRange(0,PUSH_CONSTANT_SIZE,prosper.SHADER_STAGE_VERTEX_BIT)

	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT)
	}))
	
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.CubemapView:Record(drawCmd,ds,vp,vertexBuffer,vertexCount,lineWidth,xRange,yRange,color)
	local shader = self:GetShader()
	if(shader:IsValid() == false) then return false end

	local dsPushConstants = util.DataStream(PUSH_CONSTANT_SIZE)
	dsPushConstants:Seek(0)
	dsPushConstants:WriteMat4(vp)

	local DynArg = prosper.PreparedCommandBuffer.DynArg
	local bindState = shader.BindState(drawCmd)
	if(shader:RecordBeginDraw(bindState)) then
		shader:RecordBindDescriptorSet(bindState,ds,0)
		shader:RecordBindVertexBuffers(bindState,{vertexBuffer})
		shader:RecordPushConstants(bindState,dsPushConstants)
		shader:RecordDraw(bindState,vertexCount)
		shader:RecordEndDraw(bindState)
	end
	return true
end
shader.register("cubemap_view",shader.CubemapView)

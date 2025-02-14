--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMGrid3D", shader.BaseGraphics)

local SHADER_VERTEX_BUFFER_LOCATION = 0
local SHADER_VERTEX_BUFFER_BINDING = 0

shader.PFMGrid3D.FragmentShader = "programs/pfm/grid"
shader.PFMGrid3D.VertexShader = "programs/pfm/grid"

function shader.PFMGrid3D:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsPushConstants =
		util.DataStream(util.SIZEOF_MAT4 + util.SIZEOF_VECTOR4 + util.SIZEOF_INT32 * 3 + util.SIZEOF_FLOAT * 2)
end
function shader.PFMGrid3D:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT), -- Position
	})
	self:AttachDescriptorSetInfo(shader.DescriptorSetInfo("SCENE", {
		shader.DescriptorSetBinding(
			"CAMERA",
			prosper.DESCRIPTOR_TYPE_UNIFORM_BUFFER,
			bit.bor(
				prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.SHADER_STAGE_VERTEX_BIT,
				prosper.SHADER_STAGE_GEOMETRY_BIT
			)
		),
		shader.DescriptorSetBinding(
			"RENDER_SETTINGS",
			prosper.DESCRIPTOR_TYPE_UNIFORM_BUFFER,
			bit.bor(
				prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.SHADER_STAGE_VERTEX_BIT,
				prosper.SHADER_STAGE_GEOMETRY_BIT
			)
		),
		shader.DescriptorSetBinding(
			"SSAO_MAP",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT)
		),
		shader.DescriptorSetBinding(
			"LIGHT_MAP",
			prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT)
		),
	}))
	self:AttachPushConstantRange(
		0,
		self.m_dsPushConstants:GetSize(),
		bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT, prosper.SHADER_STAGE_VERTEX_BIT)
	)
end
function shader.PFMGrid3D:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT, true)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMGrid3D:InitializeRenderPass(pipelineIdx)
	return { shader.Scene3D.get_render_pass() }
end
function shader.PFMGrid3D:InitializeBuffer()
	if self.m_bBufferInitialized == true then
		return self.m_bufVerts
	end
	self.m_bBufferInitialized = true

	local dsVerts = util.DataStream()
	local maxRadius = 1000.0
	for x = 0, maxRadius, 1 do
		dsVerts:WriteVector(Vector(x, 0, -maxRadius))
		dsVerts:WriteVector(Vector(x, 0, maxRadius))

		dsVerts:WriteVector(Vector(-maxRadius, 0, x))
		dsVerts:WriteVector(Vector(maxRadius, 0, x))

		dsVerts:WriteVector(Vector(-x, 0, -maxRadius))
		dsVerts:WriteVector(Vector(-x, 0, maxRadius))

		dsVerts:WriteVector(Vector(-maxRadius, 0, -x))
		dsVerts:WriteVector(Vector(maxRadius, 0, -x))
	end
	local bufCreateInfo = prosper.BufferCreateInfo()
	bufCreateInfo.size = dsVerts:GetSize()
	bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
	bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	local bufVerts = prosper.create_buffer(bufCreateInfo, dsVerts)
	if bufVerts == nil then
		return
	end
	self.m_bufVerts = bufVerts
	return bufVerts
end
function shader.PFMGrid3D:OnDraw(drawCmd)
	drawCmd:RecordSetLineWidth(2.0)
end
function shader.PFMGrid3D:Draw(drawCmd, origin, spacing, radius, scene, m)
	local bindState = shader.BindState(drawCmd)
	local baseShader = self:GetShader()
	if baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	local vertexBuffer = self:InitializeBuffer()
	if util.is_valid(vertexBuffer) == false then
		return
	end
	local vertCount = math.ceil((radius * 8) / spacing)
	baseShader:RecordBindVertexBuffers(bindState, { vertexBuffer })
	baseShader:RecordBindDescriptorSet(bindState, scene:GetCameraDescriptorSet())
	self:OnDraw(drawCmd)
	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(m)
	self.m_dsPushConstants:WriteVector4(Vector4(origin.x, origin.y, origin.z, spacing))
	self.m_dsPushConstants:WriteFloat(radius)
	baseShader:RecordPushConstants(bindState, self.m_dsPushConstants)
	drawCmd:RecordDraw(bindState, vertCount, 1, 0)

	baseShader:RecordEndDraw(bindState)
end
shader.register("pfm_grid_3d", shader.PFMGrid3D)

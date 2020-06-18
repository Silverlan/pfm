--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMGrid3D",shader.BaseGraphics)

local SHADER_VERTEX_BUFFER_LOCATION = 0
local SHADER_VERTEX_BUFFER_BINDING = 0

shader.PFMGrid3D.FragmentShader = "pfm/grid/fs_grid"
shader.PFMGrid3D.VertexShader = "pfm/grid/vs_grid"

function shader.PFMGrid3D:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_VECTOR4 +util.SIZEOF_FLOAT)
end
function shader.PFMGrid3D:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT) -- Position
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_UNIFORM_BUFFER,bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT,prosper.SHADER_STAGE_GEOMETRY_BIT)), -- Camera
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_UNIFORM_BUFFER,bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT,prosper.SHADER_STAGE_GEOMETRY_BIT)), -- Render settings
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT)), -- SSAO Map
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT)) -- Light Map
	}))

	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_LINE_WIDTH_BIT,true)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMGrid3D:InitializeRenderPass(pipelineIdx)
	return {shader.Scene3D.get_render_pass()}
end
function shader.PFMGrid3D:InitializeBuffer()
	if(self.m_bBufferInitialized == true) then return self.m_bufVerts end
	self.m_bBufferInitialized = true
	
	local dsVerts = util.DataStream()
	local maxRadius = 1000.0
	for x=0,maxRadius,1 do
		dsVerts:WriteVector(Vector(x,0,-maxRadius))
		dsVerts:WriteVector(Vector(x,0,maxRadius))
		
		dsVerts:WriteVector(Vector(-maxRadius,0,x))
		dsVerts:WriteVector(Vector(maxRadius,0,x))
		
		dsVerts:WriteVector(Vector(-x,0,-maxRadius))
		dsVerts:WriteVector(Vector(-x,0,maxRadius))
		
		dsVerts:WriteVector(Vector(-maxRadius,0,-x))
		dsVerts:WriteVector(Vector(maxRadius,0,-x))
	end
	local bufCreateInfo = prosper.BufferCreateInfo()
	bufCreateInfo.size = dsVerts:GetSize()
	bufCreateInfo.usageFlags = prosper.BUFFER_USAGE_VERTEX_BUFFER_BIT
	bufCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	local bufVerts = prosper.create_buffer(bufCreateInfo,dsVerts)
	if(bufVerts == nil) then return end
	self.m_bufVerts = bufVerts
	return bufVerts
end
function shader.PFMGrid3D:OnDraw(drawCmd)
	drawCmd:RecordSetLineWidth(2.0)
end
function shader.PFMGrid3D:Draw(drawCmd,origin,spacing,radius,scene,m)
	if(self:RecordBeginDraw(drawCmd) == false) then return end
	local vertexBuffer = self:InitializeBuffer()
	if(util.is_valid(vertexBuffer) == false) then return end
	local vertCount = math.ceil((radius *8) /spacing)
	self:RecordBindVertexBuffers({vertexBuffer})
	self:RecordBindDescriptorSet(scene:GetCameraDescriptorSet())
	self:OnDraw(drawCmd)
	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(m)
	self.m_dsPushConstants:WriteVector4(Vector4(origin.x,origin.y,origin.z,spacing))
	self.m_dsPushConstants:WriteFloat(radius)
	self:RecordPushConstants(self.m_dsPushConstants)
	drawCmd:RecordDraw(vertCount,1,0)
	
	self:RecordEndDraw()
end
shader.register("pfm_grid_3d",shader.PFMGrid3D)

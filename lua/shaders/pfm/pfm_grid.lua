--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMGrid",shader.BaseGraphics)

shader.PFMGrid.FragmentShader = "pfm/fs_grid"
shader.PFMGrid.VertexShader = "pfm/vs_grid"

function shader.PFMGrid:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsTransformMatrix = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_VECTOR4 +util.SIZEOF_INT +util.SIZEOF_FLOAT +util.SIZEOF_FLOAT +util.SIZEOF_INT)
end
function shader.PFMGrid:InitializeRenderPass(pipelineIdx)
	return {shader.Graphics.GetRenderPass()}
end
function shader.PFMGrid:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(vulkan.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(vulkan.FORMAT_R32G32_SFLOAT), -- Position
	})

	pipelineInfo:AttachPushConstantRange(0,self.m_dsTransformMatrix:GetSize(),bit.bor(vulkan.SHADER_STAGE_VERTEX_BIT,vulkan.SHADER_STAGE_FRAGMENT_BIT))
	
	pipelineInfo:SetDynamicStateEnabled(vulkan.DYNAMIC_STATE_SCISSOR_BIT,true)
	pipelineInfo:SetDynamicStateEnabled(vulkan.DYNAMIC_STATE_LINE_WIDTH_BIT,true)
	pipelineInfo:SetPolygonMode(vulkan.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(vulkan.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMGrid:Draw(drawCmd,transformMatrix,x,y,w,h,lineCount,strideX,color,yMultiplier,lineWidth,horizontal)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	yMultiplier = yMultiplier or 1.0
	
	local vertexBuffer = vulkan.util.get_line_vertex_buffer()
	self:RecordBindVertexBuffers({vertexBuffer})
	drawCmd:RecordSetScissor(w,h,x,y)
	drawCmd:RecordSetLineWidth(lineWidth or 1)

	self.m_dsTransformMatrix:Seek(0)
	self.m_dsTransformMatrix:WriteMat4(transformMatrix)
	self.m_dsTransformMatrix:WriteVector4(color:ToVector4())
	self.m_dsTransformMatrix:WriteUInt32(lineCount)
	self.m_dsTransformMatrix:WriteFloat(strideX *2.0)
	self.m_dsTransformMatrix:WriteFloat(yMultiplier)
	self.m_dsTransformMatrix:WriteUInt32(horizontal and 1 or 0)
	self:RecordPushConstants(self.m_dsTransformMatrix)

	self:RecordDraw(2,lineCount)
	self:RecordEndDraw()
end
shader.register("pfm_grid",shader.PFMGrid)

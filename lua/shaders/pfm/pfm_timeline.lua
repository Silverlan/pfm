--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMTimeline",shader.BaseGraphics)

shader.PFMTimeline.FragmentShader = "pfm/fs_timeline"
shader.PFMTimeline.VertexShader = "pfm/vs_timeline"

function shader.PFMTimeline:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsTransformMatrix = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_VECTOR4 +util.SIZEOF_INT +util.SIZEOF_FLOAT +util.SIZEOF_FLOAT)
end
function shader.PFMTimeline:InitializeRenderPass(pipelineIdx)
	return {shader.Graphics.get_render_pass()}
end
function shader.PFMTimeline:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
	})

	pipelineInfo:AttachPushConstantRange(0,self.m_dsTransformMatrix:GetSize(),prosper.SHADER_STAGE_VERTEX_BIT)
	
	pipelineInfo:SetDynamicStateEnabled(prosper.DYNAMIC_STATE_SCISSOR_BIT,true)
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_LIST)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMTimeline:Draw(drawCmd,transformMatrix,x,y,w,h,lineCount,strideX,color,yMultiplier)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	yMultiplier = yMultiplier or 1.0
	
	local vertexBuffer = prosper.util.get_line_vertex_buffer()
	self:RecordBindVertexBuffers({vertexBuffer})
	drawCmd:RecordSetScissor(w,h,x,y)

	self.m_dsTransformMatrix:Seek(0)
	self.m_dsTransformMatrix:WriteMat4(transformMatrix)
	self.m_dsTransformMatrix:WriteVector4(color:ToVector4())
	self.m_dsTransformMatrix:WriteUInt32(lineCount)
	self.m_dsTransformMatrix:WriteFloat(strideX *2.0)
	self.m_dsTransformMatrix:WriteFloat(yMultiplier)
	self:RecordPushConstants(self.m_dsTransformMatrix)

	self:RecordDraw(2,lineCount)
	self:RecordEndDraw()
end
shader.register("pfm_timeline",shader.PFMTimeline)

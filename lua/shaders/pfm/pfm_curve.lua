--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMCurve",shader.BaseGraphics)

shader.PFMCurve.FragmentShader = "pfm/fs_curve"
shader.PFMCurve.VertexShader = "pfm/vs_curve"

function shader.PFMCurve:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4 +util.SIZEOF_VECTOR2 *2)
end
function shader.PFMCurve:InitializeRenderPass(pipelineIdx)
	return {shader.Graphics.get_render_pass()}
end
function shader.PFMCurve:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
	})

	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),prosper.SHADER_STAGE_VERTEX_BIT)
	
	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_STRIP)
	pipelineInfo:SetDepthTestEnabled(false)
	pipelineInfo:SetDepthWritesEnabled(false)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMCurve:Draw(drawCmd,vertexBuffer,vertexCount,xRange,yRange,color,x,y,w,h)
	local bindState = shader.BindState(drawCmd)
	if(self:IsValid() == false or self:RecordBeginDraw(bindState) == false) then return end
	self:RecordBindVertexBuffers(bindState,{vertexBuffer})
	drawCmd:RecordSetScissor(bindState,w,h,x,y)
	drawCmd:RecordSetViewport(bindState,w,h,x,y)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4(color:ToVector4())
	self.m_dsPushConstants:WriteVector2(xRange)
	self.m_dsPushConstants:WriteVector2(yRange)
	self:RecordPushConstants(bindState,self.m_dsPushConstants)

	self:RecordDraw(bindState,vertexCount)
	self:RecordEndDraw(bindState)
end
shader.register("pfm_curve",shader.PFMCurve)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMLines",shader.BaseGraphics)

shader.PFMLines.FragmentShader = "pfm/lines/fs_pfm_lines"
shader.PFMLines.VertexShader = "pfm/lines/vs_pfm_lines"

function shader.PFMLines:__init()
	shader.BaseGraphics.__init(self)
	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_VECTOR4)
end
function shader.PFMLines:InitializeRenderPass(pipelineIdx)
	return {shader.Scene3D.GetRenderPass()}
end
function shader.PFMLines:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32B32_SFLOAT) -- Position
	})

	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_VERTEX_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT))

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_LINE)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_LINE_STRIP)
	pipelineInfo:SetDepthTestEnabled(true)
	pipelineInfo:SetDepthWritesEnabled(true)
	pipelineInfo:SetDepthBiasEnabled(true)
	pipelineInfo:SetDepthBiasSlopeFactor(-0.001)
	pipelineInfo:SetCommonAlphaBlendProperties()
	pipelineInfo:SetLineWidth(2)
end
function shader.PFMLines:Draw(drawCmd,vertexBuffer,numVerts,mvp)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	self:RecordBindVertexBuffers({vertexBuffer})

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(mvp)
	self.m_dsPushConstants:WriteVector4(Color(95,95,95):ToVector4())

	self:RecordPushConstants(self.m_dsPushConstants)
	self:RecordDraw(numVerts)
	self:RecordEndDraw()
end
shader.register("pfm_lines",shader.PFMLines)

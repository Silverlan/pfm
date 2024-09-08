--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.TestColor", shader.BaseGraphics)

shader.TestColor.FragmentShader = "programs/test/test_color"
shader.TestColor.VertexShader = "programs/image/noop"

------------------

function shader.TestColor:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_VECTOR4)
end
function shader.TestColor:InitializeShaderResources()
	shader.BaseGraphics.InitializeShaderResources(self)
	self:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX), {
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
	})
	self:AttachPushConstantRange(0, self.m_dsPushConstants:GetSize(), bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT))
end
function shader.TestColor:InitializePipeline(pipelineInfo, pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self, pipelineInfo, pipelineIdx)

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.TestColor:Draw(drawCmd, color)
	local bindState = shader.BindState(drawCmd)
	local baseShader = self:GetShader()
	if baseShader:IsValid() == false or baseShader:RecordBeginDraw(bindState) == false then
		return
	end
	local buf, numVerts = prosper.util.get_square_vertex_buffer()
	baseShader:RecordBindVertexBuffers(bindState, { buf })

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteVector4((color or Color.Red):ToVector4())
	baseShader:RecordPushConstants(bindState, self.m_dsPushConstants)

	baseShader:RecordDraw(bindState, prosper.util.get_square_vertex_count())
	baseShader:RecordEndDraw(bindState)
end
shader.register("test_color", shader.TestColor)

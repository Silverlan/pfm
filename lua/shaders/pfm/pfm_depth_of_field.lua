--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMDepthOfField",shader.BaseGraphics)

util.register_class("shader.PFMDepthOfField.DOFSettings")
shader.PFMDepthOfField.DOFSettings.FLAG_NONE = 0
shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_FOCUS = 1
shader.PFMDepthOfField.DOFSettings.FLAG_BIT_ENABLE_VIGNETTE = bit.lshift(shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_FOCUS,1)
shader.PFMDepthOfField.DOFSettings.FLAG_BIT_PENTAGON_BOKEH_SHAPE = bit.lshift(shader.PFMDepthOfField.DOFSettings.FLAG_BIT_ENABLE_VIGNETTE,1)
shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_DEPTH = bit.lshift(shader.PFMDepthOfField.DOFSettings.FLAG_BIT_PENTAGON_BOKEH_SHAPE,1)
function shader.PFMDepthOfField.DOFSettings:__init()
	self:SetFocalDistance(200)
	self:SetFocalLength(24)
	self:SetFStop(0.5)
	self:SetRingCount(3)
	self:SetRingSamples(3)
	self:SetCircleOfConfusionSize(0.03)
	self:SetMaxBlur(1.0)
	self:SetDitherAmount(0.0001)
	self:SetVignettingInnerBorder(0.0)
	self:SetVignettingOuterBorder(1.3)
	self:SetPentagonShapeFeather(0.4)
	self:SetFlags(shader.PFMDepthOfField.DOFSettings.FLAG_BIT_ENABLE_VIGNETTE)
end
function shader.PFMDepthOfField.DOFSettings:SetFocalDistance(dist) self.m_focalDistance = dist end
function shader.PFMDepthOfField.DOFSettings:GetFocalDistance() return self.m_focalDistance end
function shader.PFMDepthOfField.DOFSettings:SetFocalLength(len) self.m_focalLength = len end
function shader.PFMDepthOfField.DOFSettings:GetFocalLength() return self.m_focalLength end
function shader.PFMDepthOfField.DOFSettings:SetFStop(fstop) self.m_fstop = fstop end
function shader.PFMDepthOfField.DOFSettings:GetFStop() return self.m_fstop end
function shader.PFMDepthOfField.DOFSettings:SetRingCount(num) self.m_numRings = num end
function shader.PFMDepthOfField.DOFSettings:GetRingCount() return self.m_numRings end
function shader.PFMDepthOfField.DOFSettings:SetRingSamples(num) self.m_numRingSamples = num end
function shader.PFMDepthOfField.DOFSettings:GetRingSamples() return self.m_numRingSamples end
function shader.PFMDepthOfField.DOFSettings:SetCircleOfConfusionSize(sz) self.m_cocSize = sz end
function shader.PFMDepthOfField.DOFSettings:GetCircleOfConfusionSize() return self.m_cocSize end
function shader.PFMDepthOfField.DOFSettings:SetMaxBlur(blur) self.m_maxBlur = blur end
function shader.PFMDepthOfField.DOFSettings:GetMaxBlur() return self.m_maxBlur end
function shader.PFMDepthOfField.DOFSettings:SetDitherAmount(am) self.m_ditherAmount = am end
function shader.PFMDepthOfField.DOFSettings:GetDitherAmount() return self.m_ditherAmount end
function shader.PFMDepthOfField.DOFSettings:SetVignettingInnerBorder(border) self.m_vignIn = border end
function shader.PFMDepthOfField.DOFSettings:GetVignettingInnerBorder() return self.m_vignIn end
function shader.PFMDepthOfField.DOFSettings:SetVignettingOuterBorder(border) self.m_vignOut = border end
function shader.PFMDepthOfField.DOFSettings:GetVignettingOuterBorder() return self.m_vignOut end
function shader.PFMDepthOfField.DOFSettings:SetPentagonShapeFeather(feather) self.m_pentagonShapeFeather = feather end
function shader.PFMDepthOfField.DOFSettings:GetPentagonShapeFeather() return self.m_pentagonShapeFeather end
function shader.PFMDepthOfField.DOFSettings:SetFlags(flags) self.m_flags = flags end
function shader.PFMDepthOfField.DOFSettings:GetFlags() return self.m_flags end

shader.PFMDepthOfField.FragmentShader = "pfm/post_processing/fs_depth_of_field"
shader.PFMDepthOfField.VertexShader = "wgui/vs_wgui_textured_cheap"

shader.PFMDepthOfField.DESCRIPTOR_SET_TEXTURE = 0
shader.PFMDepthOfField.TEXTURE_BINDING_HDR_COLOR = 0
shader.PFMDepthOfField.TEXTURE_BINDING_DEPTH = 1

------------------

function shader.PFMDepthOfField:__init()
	shader.BaseGraphics.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_MAT4 +util.SIZEOF_FLOAT *11 +util.SIZEOF_INT *5)
end
function shader.PFMDepthOfField:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseGraphics.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachVertexAttribute(shader.VertexBinding(prosper.VERTEX_INPUT_RATE_VERTEX),{
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT), -- Position
		shader.VertexAttribute(prosper.FORMAT_R32G32_SFLOAT) -- UV
	})
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT), -- Rendered texture
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_FRAGMENT_BIT) -- Depth texture
	}))
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),bit.bor(prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_VERTEX_BIT))

	pipelineInfo:SetPolygonMode(prosper.POLYGON_MODE_FILL)
	pipelineInfo:SetPrimitiveTopology(prosper.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST)
	pipelineInfo:SetCommonAlphaBlendProperties()
end
function shader.PFMDepthOfField:InitializeRenderPass(pipelineIdx)
	local rpCreateInfo = prosper.RenderPassCreateInfo()
	rpCreateInfo:AddAttachment(
		prosper.FORMAT_R16G16B16A16_SFLOAT,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ATTACHMENT_LOAD_OP_LOAD,prosper.ATTACHMENT_STORE_OP_STORE
	)
	return {prosper.create_render_pass(rpCreateInfo)}
end
function shader.PFMDepthOfField:Draw(drawCmd,mvp,dsColDepth,dofSettings,width,height,zNear,zFar)
	if(self:IsValid() == false or self:RecordBeginDraw(drawCmd) == false) then return end
	local buf,numVerts = prosper.util.get_square_vertex_uv_buffer()
	self:RecordBindVertexBuffers({buf})
	self:RecordBindDescriptorSet(dsColDepth)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteMat4(mvp)
	self.m_dsPushConstants:WriteUInt32(width)
	self.m_dsPushConstants:WriteUInt32(height)

	self.m_dsPushConstants:WriteFloat(dofSettings:GetFocalDistance())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetFocalLength())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetFStop())

	self.m_dsPushConstants:WriteFloat(zNear)
	self.m_dsPushConstants:WriteFloat(zFar)

	self.m_dsPushConstants:WriteUInt32(dofSettings:GetFlags())
	self.m_dsPushConstants:WriteInt32(dofSettings:GetRingCount())
	self.m_dsPushConstants:WriteInt32(dofSettings:GetRingSamples())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetCircleOfConfusionSize())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetMaxBlur())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetDitherAmount())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetVignettingInnerBorder())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetVignettingOuterBorder())
	self.m_dsPushConstants:WriteFloat(dofSettings:GetPentagonShapeFeather())
	self:RecordPushConstants(self.m_dsPushConstants)

	self:RecordDraw(prosper.util.get_square_vertex_count())
	self:RecordEndDraw()
end
shader.register("pfm_dof",shader.PFMDepthOfField)

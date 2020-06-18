--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("shader.PFMCalcImageLuminance",shader.BaseCompute)

shader.PFMCalcImageLuminance.ComputeShader = "pfm/cs_calc_image_luminance"

shader.PFMCalcImageLuminance.DESCRIPTOR_SET_DATA = 0
shader.PFMCalcImageLuminance.DATA_BINDING_HDR_IMAGE = 0
shader.PFMCalcImageLuminance.DATA_BINDING_LUMINANCE = 1

function shader.PFMCalcImageLuminance:__init()
	shader.BaseCompute.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_INT *2)
end
function shader.PFMCalcImageLuminance:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseCompute.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_COMPUTE_BIT), -- HDR image
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_STORAGE_BUFFER,prosper.SHADER_STAGE_COMPUTE_BIT) -- Output data buffer
	}))
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),prosper.SHADER_STAGE_COMPUTE_BIT)
end
function shader.PFMCalcImageLuminance:Compute(computeCmd,dsData,w,h)
	if(self:IsValid() == false or self:RecordBeginCompute(computeCmd) == false) then return end

	self:RecordBindDescriptorSet(dsData)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteUInt32(w)
	self.m_dsPushConstants:WriteUInt32(h)
	self:RecordPushConstants(self.m_dsPushConstants)

	-- Work groups can't be synchronized, so we have to
	-- use a single work group
	self:RecordDispatch()

	self:RecordEndCompute()
end
shader.register("pfm_calc_image_luminance",shader.PFMCalcImageLuminance)

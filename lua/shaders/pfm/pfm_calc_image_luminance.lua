--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("util.Luminance")
function util.Luminance:__init(avgLuminance,minLuminance,maxLuminance,avgIntensity,logAvgLuminance)
	self:SetAvgLuminance(avgLuminance or 0.0)
	self:SetMinLuminance(minLuminance or 0.0)
	self:SetMaxLuminance(maxLuminance or 0.0)
	self:SetAvgIntensity(avgIntensity or Vector())
	self:SetAvgLuminanceLog(logAvgLuminance or 0.0)
end
function util.Luminance:__tostring()
	return "Luminance[Avg: " .. self:GetAvgLuminance() .. "][Min: " .. self:GetMinLuminance() .. "][Max: " .. self:GetMaxLuminance() .. "][Avg Intensity: " .. tostring(self:GetAvgIntensity()) .. "][AvgLog: " .. self:GetAvgLuminanceLog() .. "]"
end
function util.Luminance:SetAvgLuminance(avgLuminance) self.m_avgLuminance = avgLuminance end
function util.Luminance:GetAvgLuminance() return self.m_avgLuminance end
function util.Luminance:SetMinLuminance(minLuminance) self.m_minLuminance = minLuminance end
function util.Luminance:GetMinLuminance() return self.m_minLuminance end
function util.Luminance:SetMaxLuminance(maxLuminance) self.m_maxLuminance = maxLuminance end
function util.Luminance:GetMaxLuminance() return self.m_maxLuminance end
function util.Luminance:SetAvgLuminanceLog(avgLuminanceLog) self.m_avgLuminanceLog = avgLuminanceLog end
function util.Luminance:GetAvgLuminanceLog() return self.m_avgLuminanceLog end
function util.Luminance:SetAvgIntensity(avgIntensity) self.m_avgIntensity = avgIntensity end
function util.Luminance:GetAvgIntensity() return self.m_avgIntensity end

function util.Luminance.get_material_luminance(mat)
	local db = mat:GetDataBlock()
	local lum = db:FindBlock("luminance")
	if(lum == nil) then return end
	local luminance = util.Luminance()
	luminance:SetAvgLuminance(lum:GetFloat("average"))
	luminance:SetMinLuminance(lum:GetFloat("minimum"))
	luminance:SetMaxLuminance(lum:GetFloat("maximum"))
	luminance:SetAvgIntensity(lum:GetVector("average_intensity"))
	luminance:SetAvgLuminanceLog(lum:GetFloat("average_log"))
	return luminance
end

function util.Luminance.set_material_luminance(mat,luminance)
	local db = mat:GetDataBlock()
	local lum = db:AddBlock("luminance")
	lum:SetValue("float","average",tostring(luminance:GetAvgLuminance()))
	lum:SetValue("float","average_log",tostring(luminance:GetAvgLuminanceLog()))
	lum:SetValue("float","minimum",tostring(luminance:GetMinLuminance()))
	lum:SetValue("float","maximum",tostring(luminance:GetMaxLuminance()))
	lum:SetValue("vector","average_intensity",tostring(luminance:GetAvgIntensity()))
end

------------------

util.register_class("shader.PFMCalcImageLuminance",shader.BaseCompute)

shader.PFMCalcImageLuminance.ComputeShader = "pfm/cs_calc_image_luminance"

shader.PFMCalcImageLuminance.DESCRIPTOR_SET_DATA = 0
shader.PFMCalcImageLuminance.DATA_BINDING_HDR_IMAGE = 0
shader.PFMCalcImageLuminance.DATA_BINDING_LUMINANCE = 1

function shader.PFMCalcImageLuminance.read_luminance(buf)
	local lumData = buf:ReadMemory()
	local avgLuminance = lumData:ReadFloat()
	local minLuminance = lumData:ReadFloat()
	local maxLuminance = lumData:ReadFloat()
	local logAvgLuminance = lumData:ReadFloat()
	local avgIntensity = lumData:ReadVector()
	return util.Luminance(avgLuminance,minLuminance,maxLuminance,avgIntensity,logAvgLuminance)
end

function shader.PFMCalcImageLuminance:__init()
	shader.BaseCompute.__init(self)

	self.m_dsPushConstants = util.DataStream(util.SIZEOF_INT *3)
end
function shader.PFMCalcImageLuminance:InitializePipeline(pipelineInfo,pipelineIdx)
	shader.BaseCompute.InitializePipeline(self,pipelineInfo,pipelineIdx)
	pipelineInfo:AttachDescriptorSetInfo(shader.DescriptorSetInfo({
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,prosper.SHADER_STAGE_COMPUTE_BIT), -- HDR image
		shader.DescriptorSetBinding(prosper.DESCRIPTOR_TYPE_STORAGE_BUFFER,prosper.SHADER_STAGE_COMPUTE_BIT) -- Output data buffer
	}))
	pipelineInfo:AttachPushConstantRange(0,self.m_dsPushConstants:GetSize(),prosper.SHADER_STAGE_COMPUTE_BIT)
end
function shader.PFMCalcImageLuminance:CalcImageLuminance(tex,useBlackAsTransparency,drawCmd)
	local computeAndFlush = (drawCmd == nil)
	if(computeAndFlush) then drawCmd = game.get_setup_command_buffer() end
	local bufResult = prosper.util.allocate_temporary_buffer(util.SIZEOF_FLOAT *4 +util.SIZEOF_VECTOR3)
	drawCmd:RecordBufferBarrier(
		bufResult,
		prosper.PIPELINE_STAGE_COMPUTE_SHADER_BIT,prosper.PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		bit.bor(prosper.ACCESS_SHADER_WRITE_BIT,prosper.ACCESS_HOST_READ_BIT),prosper.ACCESS_SHADER_WRITE_BIT
	)
	local dsData = self:CreateDescriptorSet(shader.PFMCalcImageLuminance.DESCRIPTOR_SET_DATA)
	dsData:SetBindingTexture(shader.PFMCalcImageLuminance.DATA_BINDING_HDR_IMAGE,tex)
	dsData:SetBindingStorageBuffer(shader.PFMCalcImageLuminance.DATA_BINDING_LUMINANCE,bufResult)
	self:Compute(drawCmd,dsData,tex:GetWidth(),tex:GetHeight(),useBlackAsTransparency)
	drawCmd:RecordBufferBarrier(
		bufResult,
		prosper.PIPELINE_STAGE_COMPUTE_SHADER_BIT,prosper.PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		prosper.ACCESS_SHADER_WRITE_BIT,prosper.ACCESS_HOST_READ_BIT
	)
	if(computeAndFlush) then
		game.flush_setup_command_buffer()
		return shader.PFMCalcImageLuminance.read_luminance(bufResult)
	end
	return bufResult
end
function shader.PFMCalcImageLuminance:Compute(computeCmd,dsData,w,h,useBlackAsTransparency)
	if(self:IsValid() == false or self:RecordBeginCompute(computeCmd) == false) then return end

	self:RecordBindDescriptorSet(dsData)

	self.m_dsPushConstants:Seek(0)
	self.m_dsPushConstants:WriteUInt32(w)
	self.m_dsPushConstants:WriteUInt32(h)
	self.m_dsPushConstants:WriteUInt32(useBlackAsTransparency and 1 or 0)
	self:RecordPushConstants(self.m_dsPushConstants)

	-- Work groups can't be synchronized, so we have to
	-- use a single work group
	self:RecordDispatch()

	self:RecordEndCompute()
end
shader.register("pfm_calc_image_luminance",shader.PFMCalcImageLuminance)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_tonemapping.lua")
include("/shaders/pfm/pfm_depth_of_field.lua")
include("/util/image_processor.lua")
include("/gui/vr_view.lua")

util.register_class("gui.ToneMappedImage",gui.Base,gui.VRView)

function gui.ToneMappedImage:__init()
	gui.Base.__init(self)
	gui.VRView.__init(self)
end
function gui.ToneMappedImage:OnInitialize()
	gui.Base.OnInitialize(self)
	self.m_shader = shader.get("pfm_tonemapping")
	self.m_shaderDof = shader.get("pfm_dof")

	self:SetExposure(1.0)
	self:SetToneMappingAlgorithm(shader.TONE_MAPPING_ACES)
	self:SetToneMappingAlgorithmArgs({})
	self:SetLuminance(util.Luminance())
	self:SetVRCamera(game.get_scene():GetActiveCamera())

	--local test = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	--self.m_test = test
	--test:SetColor(Color.Lime)

	self.m_dofSettings = shader.PFMDepthOfField.DOFSettings()
	self.m_dofEnabled = false
	self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes",function(drawSceneInfo)
		self:PreRenderScenes(drawSceneInfo)
	end)

	self.m_dsTonemapping = self.m_shader:CreateDescriptorSet(shader.PFMTonemapping.DESCRIPTOR_SET_TEXTURE)
	self:SetDOFEnabled(false)
end
function gui.ToneMappedImage:SetPrimaryInterface(interface)
	self:SetCursorInputMovementEnabled(true,interface)
end
function gui.ToneMappedImage:PreRenderScenes(drawSceneInfo)
	--local tex = self.m_imgProcessor:Apply(drawSceneInfo.commandBuffer)
end
function gui.ToneMappedImage:OnRemove()
	util.remove(self.m_cbPreRenderScenes)
	self:SetDOFState(false)
end
function gui.ToneMappedImage:SetTexture(tex,depthTex)
	self.m_texture = tex
	self:SetVisible(tex ~= nil)

	self:UpdateDescriptorSets()
	self:InitializeImageProcessor()
end
function gui.ToneMappedImage:InitializeImageProcessor()
	local tex = self.m_texture
	if(tex == nil) then
		self.m_imgProcessor = nil
		return
	end
	if(self.m_imgProcessor ~= nil and tex:GetWidth() == self.m_imgProcessor:GetWidth() and tex:GetHeight() == self.m_imgProcessor:GetHeight()) then return end
	self.m_imgProcessor = util.ImageProcessor(tex:GetWidth(),tex:GetHeight())
	self.m_imgProcessor:AddStage("tone_mapping",function(drawCmd,dsTex,rtDst)
		-- TODO: Apply scissor
		local tex = rtDst:GetTexture()
		local img = tex:GetImage()
		local exposure = self:GetExposure()
		-- TODO
		--toneMapping = toneMapping or self:GetToneMappingAlgorithm()
		local toneMapping = 0 -- TODO
		local isGammaCorrected = (img:GetFormat() ~= prosper.FORMAT_R16G16B16A16_SFLOAT) -- Assume the image is gamma corrected if it's not a HDR image
		local args = self:GetToneMappingAlgorithmArgs()
		local pose = Mat4(1.0) -- self.m_drawPose
		self.m_shader:Draw(drawCmd,pose,dsTex,exposure,toneMapping,isGammaCorrected,self.m_luminance,args)
	end)
	self.m_imgProcessor:AddStage("vr",function(drawCmd,dsTex,rtDst)
		self:ApplyVR(drawCmd,dsTex)
	end)
	self.m_imgProcessor:SetInputTexture(tex)
	self.m_imgProcessor:AddStagingTexture(self.m_texture:GetImage():GetCreateInfo())
	self.m_imgProcessor:AddStagingTexture(self.m_texture:GetImage():GetCreateInfo())
end
function gui.ToneMappedImage:ApplyVR(drawCmd,dsTex)
	self:DrawVR(drawCmd,dsTex)
end
function gui.ToneMappedImage:SetDepthTexture(depthTex) self.m_depthTex = depthTex end
function gui.ToneMappedImage:SetDepthBounds(zNear,zFar)
	self.m_nearZ = zNear
	self.m_farZ = zFar
end
function gui.ToneMappedImage:UpdateDescriptorSets()
	local tex = (self.m_rtStaging ~= nil) and self.m_rtStaging:GetTexture() or self.m_texture
	if(tex ~= nil) then self.m_dsTonemapping:SetBindingTexture(shader.PFMTonemapping.TEXTURE_BINDING_HDR_COLOR,tex) end
	if(self.m_dsDof ~= nil) then
		if(self.m_texture ~= nil) then self.m_dsDof:SetBindingTexture(shader.PFMDepthOfField.TEXTURE_BINDING_HDR_COLOR,self.m_texture) end
		if(self.m_depthTex ~= nil) then self.m_dsDof:SetBindingTexture(shader.PFMDepthOfField.TEXTURE_BINDING_DEPTH,self.m_depthTex) end
	end
end
function gui.ToneMappedImage:SetDOFState(b)
	if(b == false) then
		if(util.is_valid(self.m_cbPreGUIDraw)) then self.m_cbPreGUIDraw:Remove() end
		if(util.is_valid(self.m_test)) then self.m_test:Remove() end
		self.m_rtStaging = nil
		self.m_dsDof = nil
		self:UpdateDescriptorSets()
		collectgarbage()
		return
	end
	if(self.m_dsDof ~= nil or self.m_texture == nil or self.m_depthTex == nil) then return end
	if(util.is_valid(self.m_cbPreGUIDraw)) then self.m_cbPreGUIDraw:Remove() end
	self.m_cbPreGUIDraw = game.add_callback("PreGUIDraw",function(drawCmd)
		self:RenderDOF(drawCmd)
		-- _x:RenderPragmaParticleSystems(self.m_rtStaging:GetTexture(),drawCmd)
	end)
	if(util.is_valid(self.m_test)) then self.m_test:Remove() end
	self.m_test = game.add_callback("PreRenderScenes",function()
		--self:RenderParticleSystems()
	end)
	self.m_dsDof = self.m_shaderDof:CreateDescriptorSet(shader.PFMDepthOfField.DESCRIPTOR_SET_TEXTURE)

	 if(self.m_rtStaging == nil or self.m_rtStaging:GetTexture():GetWidth() ~= self.m_texture:GetWith() or self.m_rtStaging:GetTexture():GetHeight() ~= self.m_texture:GetHeight()) then
		local createInfo = self.m_texture:GetImage():GetCreateInfo()
		createInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_TRANSFER_DST_BIT,prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
		createInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
		createInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
		createInfo.format = prosper.FORMAT_R8G8B8A8_UNORM
		local img = prosper.create_image(createInfo)
		local samplerCreateInfo = prosper.SamplerCreateInfo()
		samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
		samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
		samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
		local texStaging = prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
		self.m_rtStaging = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{texStaging},self.m_shaderDof:GetRenderPass())

		self.m_dsTonemapping:SetBindingTexture(shader.PFMTonemapping.TEXTURE_BINDING_HDR_COLOR,texStaging)
	end
	self:UpdateDescriptorSets()
end
function gui.ToneMappedImage:RenderParticleSystems()
	local drawCmd = game.get_draw_command_buffer()
	-- _x:RenderPragmaParticleSystems(self.m_rtStaging:GetTexture(),drawCmd,self.m_rtStaging)
	--drawCmd:RecordClearImage(self.m_rtStaging:GetTexture():GetImage(),Color.Red)
	
	-- self.m_rtStaging
end
function gui.ToneMappedImage:RenderDOF(drawCmd)
	if(self.m_nearZ == nil or self.m_texture == nil) then return end
	local texStaging = self.m_rtStaging:GetTexture()
	drawCmd:RecordImageBarrier(
		self.m_texture:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		texStaging:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_WRITE_BIT
	)
	drawCmd:RecordBlitImage(self.m_texture:GetImage(),texStaging:GetImage(),prosper.BlitInfo())
	drawCmd:RecordImageBarrier(
		self.m_texture:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)

	drawCmd:RecordImageBarrier(
		texStaging:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_TRANSFER_WRITE_BIT,bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
	)
	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(self.m_rtStaging))) then
		self.m_shaderDof:Draw(drawCmd,Mat4(1.0),self.m_dsDof,self.m_dofSettings,texStaging:GetWidth(),texStaging:GetHeight(),self.m_nearZ,self.m_farZ)

		drawCmd:RecordEndRenderPass()
	end
	drawCmd:RecordImageBarrier(
		texStaging:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT),prosper.ACCESS_SHADER_READ_BIT
	)
	self:RenderParticleSystems()
end
function gui.ToneMappedImage:GetTexture() return self.m_texture end
function gui.ToneMappedImage:GetDescriptorSet() return self.m_dsTonemapping end
function gui.ToneMappedImage:SetExposure(exposure) self.m_exposure = exposure end
function gui.ToneMappedImage:GetExposure() return self.m_exposure end
function gui.ToneMappedImage:SetToneMappingAlgorithm(toneMapping) self.m_toneMapping = toneMapping end
function gui.ToneMappedImage:GetToneMappingAlgorithm() return self.m_toneMapping end
function gui.ToneMappedImage:SetToneMappingAlgorithmArgs(args) self.m_toneMappingArgs = args end
function gui.ToneMappedImage:GetToneMappingAlgorithmArgs() return self.m_toneMappingArgs end
function gui.ToneMappedImage:SetLuminance(luminance) self.m_luminance = luminance end
function gui.ToneMappedImage:GetLuminance() return self.m_luminance end
function gui.ToneMappedImage:SetDOFEnabled(b)
	if(b == self.m_dofEnabled) then return end
	self.m_dofEnabled = b
	self:SetDOFState(b)
end
function gui.ToneMappedImage:IsDOFEnabled() return self.m_dofEnabled end
function gui.ToneMappedImage:GetDOFSettings() return self.m_dofSettings end
function gui.ToneMappedImage:Render(drawCmd,pose,toneMapping)
	if(self.m_shader == nil or self.m_texture == nil) then return end
	local parent = self:GetParent()
	local x,y,w,h = gui.get_render_scissor_rect()

	local exposure = self:GetExposure()
	toneMapping = toneMapping or self:GetToneMappingAlgorithm()
	if(self:IsDOFEnabled() and bit.band(self.m_dofSettings:GetFlags(),shader.PFMDepthOfField.DOFSettings.FLAG_BIT_DEBUG_SHOW_DEPTH) ~= 0) then toneMapping = -1 end
	local args = self:GetToneMappingAlgorithmArgs()
	-- TODO: Apply scissor
	local img = self.m_texture:GetImage()
	local isGammaCorrected = (img:GetFormat() ~= prosper.FORMAT_R16G16B16A16_SFLOAT) -- Assume the image is gamma corrected if it's not a HDR image
	self.m_shader:Draw(drawCmd,pose,self.m_dsTonemapping,exposure,toneMapping,isGammaCorrected,self.m_luminance,args)

	--self.m_imgProcessor:Apply(drawCmd)
end
function gui.ToneMappedImage:OnDraw(drawInfo,pose)
	--self:Render(game.get_draw_command_buffer(),pose)
	--self.m_drawPose = pose
	--if(self.m_imgProcessor ~= nil) then self.m_imgProcessor:Apply(game.get_draw_command_buffer(),self.m_texture) end
end
gui.register("WIToneMappedImage",gui.ToneMappedImage)

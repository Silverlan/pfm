--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")
-- include("/shaders/pfm/pfm_composite.lua")
include("/shaders/pfm/pfm_scene_composition.lua")
include("/shaders/pfm/pfm_calc_image_luminance.lua")
include("/shaders/pfm/pfm_depth_of_field.lua")
include("tonemappedimage.lua")

util.register_class("gui.RaytracedViewport",gui.Base)
function gui.RaytracedViewport:__init()
	gui.Base.__init(self)
end
function gui.RaytracedViewport:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128,128)

	self.m_tex = gui.create("WIToneMappedImage",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_renderSettings = pfm.RaytracingRenderJob.Settings()
	self.m_renderSettings:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self.m_renderSettings:SetSamples(40)
	self.m_renderSettings:SetSkyStrength(30)
	self.m_renderSettings:SetSkyYaw(0.0)
	self.m_renderSettings:SetEmissionStrength(1.0)
	self.m_renderSettings:SetMaxTransparencyBounces(128)
	self.m_renderSettings:SetDenoise(true)
	self.m_renderSettings:SetHDROutput(true)
	self.m_renderSettings:SetDeviceType(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU)
	self.m_renderSettings:SetCamType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
	self.m_renderSettings:SetPanoramaType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA)

	self:SetToneMapping(shader.TONE_MAPPING_GAMMA_CORRECTION)
end
function gui.RaytracedViewport:SetUseElementSizeAsRenderResolution(b) self.m_useElementSizeAsRenderResolution = b end
function gui.RaytracedViewport:GetRenderSettings() return self.m_renderSettings end
function gui.RaytracedViewport:SetGameScene(gameScene) self.m_gameScene = gameScene end
function gui.RaytracedViewport:GetGameScene() return self.m_gameScene or game.get_scene() end
function gui.RaytracedViewport:OnRemove()
	self:CancelRendering()
end
function gui.RaytracedViewport:CancelRendering()
	if(self.m_rtJob == nil) then return end
	self.m_rtJob:CancelRendering()
end
function gui.RaytracedViewport:IsRendering()
	return (self.m_rtJob ~= nil) and self.m_rtJob:IsRendering() or false
end
function gui.RaytracedViewport:UpdateThinkState()
	if(self.m_rendering == true) then
		self:EnableThinking()
		self:SetAlwaysUpdate(true)
		return
	end
	self:DisableThinking()
	self:SetAlwaysUpdate(false)
end
function gui.RaytracedViewport:OnThink()
	if(self.m_rendering ~= true) then return end
	local progress = self.m_rtJob:GetProgress()
	local state = self.m_rtJob:Update()
	local newProgress = self.m_rtJob:GetProgress()
	if(newProgress ~= progress) then
		self:CallCallbacks("OnProgressChanged",newProgress)
	end
	if((state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE)) then
		local preStageScene = self.m_rtJob:GetPreStageScene()
		if(preStageScene ~= nil) then
			self:CallCallbacks("OnSceneComplete",preStageScene)
		else
			local tex = self.m_rtJob:GetRenderResultTexture()
			local imgBuf = self.m_rtJob:GetRenderResult()
			if(tex ~= nil) then
				-- The scene has been completely rendered with Cycles with the exception of
				-- particles. Particle effects are rendered in post-processing with Pragma.
				self.m_renderResultSettings = self.m_rtJob:GetSettings():Copy()
				self:ApplyPostProcessing(tex)
			end

			self:CallCallbacks("OnFrameComplete",state,self.m_rtJob)
		end
	end
	if(state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FAILED) then
		self.m_rendering = false
		self:UpdateThinkState()

		self:CallCallbacks("OnComplete",state,self.m_rtJob)
	elseif(state == pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE or state == pfm.RaytracingRenderJob.STATE_SUB_FRAME_COMPLETE) then self.m_rtJob:RenderNextImage() end
end
function gui.RaytracedViewport:ApplyDepthOfField()
	local shaderDof = shader.get("pfm_dof")

	self:InitializeSceneTexture(w,h)
	local sceneHdrTex = renderer:GetHDRPresentationTexture()
	local sceneBloomTex = renderer:GetBloomTexture()
	local sceneGlowTex = renderer:GetGlowTexture()

	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR,sceneHdrTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM,sceneBloomTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_GLOW,sceneGlowTex)

	-- Scene HDR texture is in transfer-src layout
	-- Bloom texture is in shader-read-only layout
	-- Glow texture is in color-attachment layout
	-- Move them all to shader-read-only layout
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	--

	-- Move target image to color-attachment layout
	drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--

	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(self.m_hdrRt))) then
		local shaderComposition = shader.get("pfm_scene_composition")
		-- TODO
		local bloomScale = 1.0
		local glowScale = 1.0
		shaderComposition:Draw(drawCmd,self.m_dsSceneComposition,bloomScale,glowScale)
		drawCmd:RecordEndRenderPass()
	end
	-- (Render pass has already moved target image to shader-read layout)
	--[[drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)]]
	--

	-- Move scene textures back to original layouts
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
end
function gui.RaytracedViewport:ComposeSceneTextures(drawCmd,w,h,renderer,rtOut)
	self:InitializeSceneTexture(w,h)
	rtOut = rtOut or self.m_hdrRt
	local sceneHdrTex = renderer:GetHDRPresentationTexture()
	local sceneBloomTex = renderer:GetBloomTexture()
	local sceneGlowTex = renderer:GetGlowTexture()

	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR,sceneHdrTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM,sceneBloomTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_GLOW,sceneGlowTex)

	-- Scene HDR texture is in transfer-src layout
	-- Bloom texture is in shader-read-only layout
	-- Glow texture is in color-attachment layout
	-- Move them all to shader-read-only layout
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	--

	-- Move target image to color-attachment layout
	drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--

	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(rtOut))) then
		local shaderComposition = shader.get("pfm_scene_composition")
		-- TODO
		local bloomScale = 1.0
		local glowScale = 1.0
		shaderComposition:Draw(drawCmd,self.m_dsSceneComposition,bloomScale,glowScale)
		drawCmd:RecordEndRenderPass()
	end
	-- (Render pass has already moved target image to shader-read layout)
	--[[drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)]]
	--

	-- Move scene textures back to original layouts
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--
	return rtOut
end
function gui.RaytracedViewport:ComputeLuminance(drawCmd)
	return shader.get("pfm_calc_image_luminance"):CalcImageLuminance(self.m_hdrTex,false,drawCmd)
end
function gui.RaytracedViewport:SetToneMapping(toneMapping)
	if(toneMapping == self:GetToneMapping()) then return end
	self.m_tex:SetToneMappingAlgorithm(toneMapping)
end
function gui.RaytracedViewport:SetToneMappingArguments(toneMapArgs) self.m_tex:SetToneMappingAlgorithmArgs(toneMapArgs) end
function gui.RaytracedViewport:GetToneMappingArguments() return self.m_tex:GetToneMappingAlgorithmArgs() end
function gui.RaytracedViewport:GetToneMapping() return self.m_tex:GetToneMappingAlgorithm() end
function gui.RaytracedViewport:GetDOFSettings() return self.m_tex:GetDOFSettings() end
function gui.RaytracedViewport:SetDOFEnabled(b) self.m_tex:SetDOFEnabled(b) end
function gui.RaytracedViewport:SetLuminance(luminance) return self.m_tex:SetLuminance(luminance) end
function gui.RaytracedViewport:GetLuminance() return self.m_tex:GetLuminance() end
function gui.RaytracedViewport:SetExposure(exposure) self.m_tex:SetExposure(exposure) end
function gui.RaytracedViewport:GetExposure() return self.m_tex:GetExposure() end
function gui.RaytracedViewport:GetToneMappedImageElement() return self.m_tex end
function gui.RaytracedViewport:GetSceneTexture() return self.m_hdrTex end
function gui.RaytracedViewport:GetRenderResultRenderSettings() return self.m_renderResultSettings end
function gui.RaytracedViewport:InitializeSceneTexture(w,h)
	if(self.m_hdrTex ~= nil and self.m_hdrTex:GetWidth() == w and self.m_hdrTex:GetHeight() == h) then return self.m_hdrTex end
	self.m_hdrTex = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = shader.Scene3D.RENDER_PASS_COLOR_FORMAT
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local imgHdr = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local texHdr = prosper.create_texture(imgHdr,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	self.m_hdrTex = texHdr

	self.m_tex:SetTexture(texHdr)

	local shaderComposition = shader.get("pfm_scene_composition")
	self.m_hdrRt = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{self.m_hdrTex},shaderComposition:GetRenderPass())

	self.m_dsSceneComposition = shaderComposition:CreateDescriptorSet(shader.PFMSceneComposition.DESCRIPTOR_SET_TEXTURE)
	return texHdr
end
function gui.RaytracedViewport:InitializeDepthTexture(w,h,nearZ,farZ)
	self.m_tex:SetDepthBounds(nearZ,farZ)
	if(self.m_depthTex ~= nil and self.m_depthTex:GetWidth() == w and self.m_depthTex:GetHeight() == h) then return end
	self.m_depthTex = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = shader.Scene3D.RENDER_PASS_DEPTH_FORMAT
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local imgDepth = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local texDepth = prosper.create_texture(imgDepth,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	self.m_depthTex = texDepth
	self.m_tex:SetDepthTexture(texDepth)
end
function gui.RaytracedViewport:UpdateGameSceneTextures()
	local gameScene = self:GetGameScene()
	local cam = gameScene:GetActiveCamera()
	local renderer = self.m_testRenderer--gameScene:GetRenderer()
	if(renderer == nil or cam == nil) then return end
	self:InitializeDepthTexture(gameScene:GetWidth(),gameScene:GetHeight(),cam:GetNearZ(),cam:GetFarZ())

	local drawCmd = game.get_setup_command_buffer()
	local depthTex = renderer:GetPostPrepassDepthTexture()
	drawCmd:RecordImageBarrier(
		depthTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		bit.bor(prosper.ACCESS_MEMORY_READ_BIT,prosper.ACCESS_MEMORY_WRITE_BIT),prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordBlitImage(depthTex:GetImage(),self.m_depthTex:GetImage(),prosper.BlitInfo())
	drawCmd:RecordImageBarrier(
		depthTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,bit.bor(prosper.ACCESS_MEMORY_READ_BIT,prosper.ACCESS_MEMORY_WRITE_BIT)
	)
	self:RenderParticleSystemDepth(drawCmd)
	game.flush_setup_command_buffer()
end
function gui.RaytracedViewport:RenderParticleSystemDepth(drawCmd)
	-- TODO: Skip this step if we're not using DOF
	-- Particle systems are usually not written to the depth buffer,
	-- however to properly calculate depth of field for particles, they
	-- need to be included. We'll add a render pass specifically for rendering
	-- particle depths here.
	drawCmd:RecordImageBarrier(
		self.m_depthTex:GetImage(),
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
		bit.bor(prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT,prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT),bit.bor(prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT,prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
	)
	local rtDepth = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{self.m_depthTex},shader.BaseParticle2D.get_depth_pipeline_render_pass())
	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(rtDepth))) then
		local gameScene = self:GetGameScene()
		local renderer = self.m_testRenderer--gameScene:GetRenderer()
		local particleSystems = renderer:GetRenderParticleSystems()
		for _,pts in ipairs(particleSystems) do
			pts:Render(drawCmd,renderer,ents.ParticleSystemComponent.RENDER_FLAG_BIT_DEPTH_ONLY)
		end
		drawCmd:RecordEndRenderPass()
	end
end
function gui.RaytracedViewport:Refresh(preview)
	self:CancelRendering()
	local r = engine.load_library("cycles/pr_cycles")
	if(r ~= true) then
		print("WARNING: An error occured trying to load the 'pr_cycles' module: ",r)
		return
	end

	local settings = self.m_renderSettings
	if(self.m_useElementSizeAsRenderResolution) then
		settings:SetWidth(self:GetWidth())
		settings:SetHeight(self:GetHeight())
	end

	settings:SetRenderPreview(preview)
	self.m_rtJob = pfm.RaytracingRenderJob(settings)
	self.m_rtJob:SetStartFrame(tool.get_filmmaker():GetClampedFrameOffset())
	if(self.m_gameScene ~= nil) then self.m_rtJob:SetGameScene(self.m_gameScene) end

	pfm.log("Rendering image with resolution " .. settings:GetWidth() .. "x" .. settings:GetHeight() .. " and " .. settings:GetSamples() .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self.m_rtJob:Start()

	self.m_rendering = true
	self:UpdateThinkState()
end
gui.register("WIRaytracedViewport",gui.RaytracedViewport)

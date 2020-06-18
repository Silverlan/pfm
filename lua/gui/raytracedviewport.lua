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
		local tex = self.m_rtJob:GetRenderResultTexture()
		local imgBuf = self.m_rtJob:GetRenderResult()
		if(tex ~= nil) then
			-- The scene has been completely rendered with Cycles with the exception of
			-- particles. Particle effects are rendered in post-processing with Pragma.

			-- Temporarily change the resolution of our scene to match the raytraced scene.
			-- It will be changed back afterwards.
			local w = tex:GetWidth()
			local h = tex:GetHeight()
			local gameScene = self.m_rtJob:GetGameScene()
			local oldResolution = gameScene:GetSize()
			gameScene:Resize(w,h)

			local renderer = gameScene:GetRenderer()
			local drawCmd = game.get_setup_command_buffer()

			local drawSceneInfo = game.DrawSceneInfo()
			drawSceneInfo.scene = gameScene
			drawSceneInfo.commandBuffer = drawCmd
			-- We want to apply tonemapping manually ourselves, so we just care about the HDR output for now
			drawSceneInfo.renderFlags = bit.bor(game.RENDER_FLAG_ALL,game.RENDER_FLAG_HDR_BIT)

			-- We want to render the whole scene in the depth pre-pass, but only particles
			-- in the lighting pass. This way the particles will get obstructed by objects
			-- properly.
			drawSceneInfo:SetEntityRenderFilter(function(ent)
				-- TODO
				return ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM)
			end)

			local sceneTexHdr = renderer:GetRenderTarget():GetTexture()
			-- We'll blit the Cycles image into the current scene texture.
			-- Since we don't clear the scene, this will make it so the Cycles image
			-- is effectively our background.
			drawCmd:RecordImageBarrier(
				tex:GetImage(),
				prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
			)
			drawCmd:RecordImageBarrier( -- TODO: Confirm that this texture is in the transfer-src layout at this point in time
				sceneTexHdr:GetImage(),
				prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_TRANSFER_WRITE_BIT
			)
			drawCmd:RecordBlitImage(tex:GetImage(),sceneTexHdr:GetImage(),prosper.BlitInfo())
			drawCmd:RecordImageBarrier(
				sceneTexHdr:GetImage(),
				prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				prosper.ACCESS_TRANSFER_WRITE_BIT,prosper.ACCESS_TRANSFER_READ_BIT
			)
			drawCmd:RecordImageBarrier(
				tex:GetImage(),
				prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
				prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
				prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
			)

			game.draw_scene(drawSceneInfo)

			-- Compose scene texture outputs into a single HDR texture
			self:ComposeSceneTextures(drawCmd,w,h,renderer)
			local bufLuminance = self:ComputeLuminance(drawCmd)

			-- Initiate rendering and wait for completion
			game.flush_setup_command_buffer()

			-- These should match closely! (Unless the image has a lot of bloom or glow effects)
			-- print("Compute shader values: ",avgLuminance,minLuminance,maxLuminance,avgIntensity,logAvgLuminance)
			-- print("Precise values: ",imgBuf:CalcLuminance())

			-- We'll need these for some tone-mapping algorithms
			self.m_tex:SetLuminance(self:ReadLuminance(bufLuminance))

			-- Resize back to the original resolution
			gameScene:Resize(oldResolution.x,oldResolution.y)
		end

		self:CallCallbacks("OnFrameComplete",state,self.m_rtJob)
	end
	if(state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FAILED) then
		self.m_rendering = false
		self:UpdateThinkState()

		self:CallCallbacks("OnComplete",state,self.m_rtJob)
	end
end
function gui.RaytracedViewport:ComposeSceneTextures(drawCmd,w,h,renderer)
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
	--
end
function gui.RaytracedViewport:ComputeLuminance(drawCmd)
	local tex = self.m_hdrTex
	local buf = prosper.util.allocate_temporary_buffer(util.SIZEOF_FLOAT *4 +util.SIZEOF_VECTOR3)
	drawCmd:RecordBufferBarrier(
		buf,
		prosper.SHADER_STAGE_COMPUTE_BIT,prosper.SHADER_STAGE_COMPUTE_BIT,
		bit.bor(prosper.ACCESS_SHADER_WRITE_BIT,prosper.ACCESS_HOST_READ_BIT),prosper.ACCESS_SHADER_WRITE_BIT
	)
	local shaderCalcLuminance = shader.get("pfm_calc_image_luminance")
	local dsData = shaderCalcLuminance:CreateDescriptorSet(shader.PFMCalcImageLuminance.DESCRIPTOR_SET_DATA)
	dsData:SetBindingTexture(shader.PFMCalcImageLuminance.DATA_BINDING_HDR_IMAGE,tex)
	dsData:SetBindingStorageBuffer(shader.PFMCalcImageLuminance.DATA_BINDING_LUMINANCE,buf)
	shaderCalcLuminance:Compute(drawCmd,dsData,tex:GetWidth(),tex:GetHeight())
	drawCmd:RecordBufferBarrier(
		buf,
		prosper.SHADER_STAGE_COMPUTE_BIT,prosper.SHADER_STAGE_COMPUTE_BIT,
		prosper.ACCESS_SHADER_WRITE_BIT,prosper.ACCESS_HOST_READ_BIT
	)
	return buf
end
function gui.RaytracedViewport:ReadLuminance(buf)
	local lumData = buf:ReadMemory()
	local avgLuminance = lumData:ReadFloat()
	local minLuminance = lumData:ReadFloat()
	local maxLuminance = lumData:ReadFloat()
	local logAvgLuminance = lumData:ReadFloat()
	local avgIntensity = lumData:ReadVector()
	return shader.PFMTonemapping.Luminance(avgLuminance,minLuminance,maxLuminance,avgIntensity,logAvgLuminance)
end
function gui.RaytracedViewport:SetToneMapping(toneMapping)
	if(toneMapping == self:GetToneMapping()) then return end
	self.m_tex:SetToneMappingAlgorithm(toneMapping)
end
function gui.RaytracedViewport:SetToneMappingArguments(toneMapArgs) self.m_tex:SetToneMappingAlgorithmArgs(toneMapArgs) end
function gui.RaytracedViewport:GetToneMappingArguments() return self.m_tex:GetToneMappingAlgorithmArgs() end
function gui.RaytracedViewport:GetToneMapping() return self.m_tex:GetToneMappingAlgorithm() end
function gui.RaytracedViewport:SetLuminance(luminance) return self.m_tex:SetLuminance(luminance) end
function gui.RaytracedViewport:GetLuminance() return self.m_tex:GetLuminance() end
function gui.RaytracedViewport:SetExposure(exposure) self.m_tex:SetExposure(exposure) end
function gui.RaytracedViewport:GetExposure() return self.m_tex:GetExposure() end
function gui.RaytracedViewport:GetToneMappedImageElement() return self.m_tex end
function gui.RaytracedViewport:GetSceneTexture() return self.m_hdrTex end
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
	if(self.m_gameScene ~= nil) then self.m_rtJob:SetGameScene(self.m_gameScene) end

	pfm.log("Rendering image with resolution " .. settings:GetWidth() .. "x" .. settings:GetHeight() .. " and " .. settings:GetSamples() .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self.m_rtJob:Start()

	self.m_rendering = true
	self:UpdateThinkState()
end
gui.register("WIRaytracedViewport",gui.RaytracedViewport)

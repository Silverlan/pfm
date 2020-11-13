--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")
-- include("/shaders/pfm/pfm_composite.lua")
include("/shaders/pfm/pfm_calc_image_luminance.lua")
include("renderimage.lua")

util.register_class("gui.RaytracedViewport",gui.Base)
function gui.RaytracedViewport:__init()
	gui.Base.__init(self)
end
function gui.RaytracedViewport:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128,128)

	self.m_tex = gui.create("WIRenderImage",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_renderSettings = pfm.RaytracingRenderJob.Settings()
	self.m_renderSettings:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self.m_renderSettings:SetSamples(40)
	self.m_renderSettings:SetSkyStrength(30)
	self.m_renderSettings:SetSkyYaw(0.0)
	self.m_renderSettings:SetEmissionStrength(1.0)
	self.m_renderSettings:SetMaxTransparencyBounces(128)
	self.m_renderSettings:SetDenoiseMode(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_DETAILED)
	self.m_renderSettings:SetHDROutput(false)
	self.m_renderSettings:SetDeviceType(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU)
	self.m_renderSettings:SetCamType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
	self.m_renderSettings:SetPanoramaType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA)

	self:SetToneMapping(shader.TONE_MAPPING_GAMMA_CORRECTION)
end
function gui.RaytracedViewport:SetTextureFromImageBuffer(imgBuf)
	-- Test:
	-- lua_run_cl imgJob = util.load_image("render/new_project/shot08b/frame0001.hdr",true,util.ImageBuffer.FORMAT_RGBA_HDR) imgJob:Start()
	-- lua_run_cl tool.get_filmmaker():GetRenderTab().m_rt:SetTextureFromImageBuffer(imgJob:GetResult())
	local img
	local imgCreateInfo = prosper.create_image_create_info(imgBuf)
	imgCreateInfo.usageFlags = bit.bor(imgCreateInfo.usageFlags,prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_TRANSFER_SRC_BIT,prosper.IMAGE_USAGE_TRANSFER_DST_BIT)
	img = prosper.create_image(imgBuf,imgCreateInfo)

	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	self.m_tex:SetTexture(prosper.create_texture(img,prosper.TextureCreateInfo(),imgViewCreateInfo,samplerCreateInfo))
end
function gui.RaytracedViewport:SaveImage(path,imgFormat,hdr)
	hdr = hdr or false
	local img
	local imgBufFormat
	if(imgFormat == util.IMAGE_FORMAT_HDR) then
		-- Image is not tonemapped, we'll save it with the original HDR colors
		hdr = true
		img = self.m_tex:GetTexture():GetImage()
		imgBufFormat = util.ImageBuffer.FORMAT_RGBA_HDR
	else
		-- Apply Tonemapping
		--[[img = self:ApplyToneMapping()
		if(img == nil) then return false end]]
		img = self.m_rtJob:GetRenderResultTexture():GetImage()
		imgBufFormat = util.ImageBuffer.FORMAT_RGBA_HDR
		--imgBufFormat = util.ImageBuffer.FORMAT_RGBA_LDR
	end

	local buf = prosper.util.allocate_temporary_buffer(img:GetWidth() *img:GetHeight() *prosper.get_byte_size(img:GetFormat()))
	local drawCmd = game.get_setup_command_buffer()
	drawCmd:RecordImageBarrier(
		img,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordCopyImageToBuffer(img,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,buf,prosper.BufferImageCopyInfo())
	drawCmd:RecordImageBarrier(
		img,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	game.flush_setup_command_buffer()
	local imgData = buf:ReadMemory()
	local imgBuf = util.ImageBuffer.Create(img:GetWidth(),img:GetHeight(),imgBufFormat,imgData)
	if(hdr == false) then imgBuf:ToLDR() end

	local result = util.save_image(imgBuf,path,imgFormat)
	if(result == false) then
		pfm.log("Unable to save image as '" .. path .. "'!",pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_WARNING)
	else
		pfm.log("Successfully saved image as '" .. path .. "'!",pfm.LOG_CATEGORY_PFM_RENDER)
	end
	buf = nil
	collectgarbage()
	return result
end
function gui.RaytracedViewport:ApplyToneMapping(toneMapping)
	if(true) then return end -- Deprecated (for now)
	local hdrTex = self.m_tex:GetTexture()
	if(hdrTex == nil) then return end
	local w = hdrTex:GetWidth()
	local h = hdrTex:GetHeight()
	local rt = self:InitializeLDRRenderTarget(w,h)

	local tonemappedImg = self.m_tex
	local wasDofEnabled = tonemappedImg:IsDOFEnabled()
	tonemappedImg:SetDOFEnabled(false)

	local drawCmd = game.get_setup_command_buffer()
	local exportImg = rt:GetTexture():GetImage()
	drawCmd:RecordImageBarrier(
		exportImg,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
	)

	local rpInfo = prosper.RenderPassInfo(rt)
	if(drawCmd:RecordBeginRenderPass(rpInfo)) then
		tonemappedImg:Render(drawCmd,Mat4(1.0),toneMapping)
		drawCmd:RecordEndRenderPass()
	end

	drawCmd:RecordImageBarrier(
		exportImg,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT),prosper.ACCESS_SHADER_READ_BIT
	)
	game.flush_setup_command_buffer()
	rt = nil
	collectgarbage() -- Clear render target
	tonemappedImg:SetDOFEnabled(wasDofEnabled)
	return exportImg
end
function gui.RaytracedViewport:InitializeLDRRenderTarget(w,h)
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = prosper.FORMAT_R8G8B8A8_UNORM
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local img = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	return prosper.create_render_target(prosper.RenderTargetCreateInfo(),{tex},shader.Graphics.get_render_pass())
end
function gui.RaytracedViewport:SetUseElementSizeAsRenderResolution(b) self.m_useElementSizeAsRenderResolution = b end
function gui.RaytracedViewport:GetRenderSettings() return self.m_renderSettings end
function gui.RaytracedViewport:SetRenderSettings(renderSettings) self.m_renderSettings = renderSettings end
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

				self.m_tex:SetTexture(tex)
				-- self:ApplyPostProcessing(tex)
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
function gui.RaytracedViewport:ComputeLuminance(drawCmd)
	return shader.get("pfm_calc_image_luminance"):CalcImageLuminance(self.m_hdrTex,false,drawCmd)
end
function gui.RaytracedViewport:SetToneMapping(toneMapping)
	if(toneMapping == self:GetToneMapping()) then return end
	self.m_tex:SetToneMappingAlgorithm(toneMapping)
end
function gui.RaytracedViewport:SetProjectManager(pm) self.m_projectManager = pm end
function gui.RaytracedViewport:GetProjectManager() return self.m_projectManager end
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
function gui.RaytracedViewport:GetRenderScene()
	if(self.m_rtJob == nil or self:IsRendering() == false) then return end
	local scene = self.m_rtJob:GetRenderScene()
	return util.is_valid(scene) and scene or nil
end
function gui.RaytracedViewport:RestartRendering()
	if(self.m_rtJob == nil) then return end
	self.m_rtJob:RestartRendering()
end
function gui.RaytracedViewport:Refresh(preview,rtJobCallback)
	preview = preview or false
	if(self.m_projectManager == nil) then
		console.print_warning("Unable to render raytraced viewport: No valid project manager specified!")
		return
	end
	self:CancelRendering()
	if(pfm.load_cycles() == false) then return end

	local settings = self.m_renderSettings
	if(self.m_useElementSizeAsRenderResolution) then
		settings:SetWidth(self:GetWidth())
		settings:SetHeight(self:GetHeight())
	end

	settings:SetRenderPreview(preview)
	self.m_rtJob = pfm.RaytracingRenderJob(self.m_projectManager,settings)
	self.m_rtJob:SetStartFrame(self.m_projectManager:GetClampedFrameOffset())
	self.m_rtJob:AddCallback("OnFrameStart",function()
		if(self.m_rtJob:IsProgressive() == false) then return end
		local tex = self.m_rtJob:GetProgressiveTexture()
		self.m_tex:SetTexture(tex)
	end)
	if(rtJobCallback ~= nil) then rtJobCallback(self.m_rtJob) end
	if(self.m_gameScene ~= nil) then self.m_rtJob:SetGameScene(self.m_gameScene) end

	pfm.log("Rendering image with resolution " .. settings:GetWidth() .. "x" .. settings:GetHeight() .. " and " .. settings:GetSamples() .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self.m_rtJob:Start()

	self.m_rendering = true
	self:UpdateThinkState()
end
gui.register("WIRaytracedViewport",gui.RaytracedViewport)

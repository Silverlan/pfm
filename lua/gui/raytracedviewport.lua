--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")
-- include("/shaders/pfm/pfm_composite.lua")
include("/shaders/pfm/pfm_calc_image_luminance.lua")
include("renderimage.lua")

util.register_class("gui.RaytracedViewport",gui.Base)

gui.RaytracedViewport.STATE_INITIAL = 0
gui.RaytracedViewport.STATE_RENDERING = 1
gui.RaytracedViewport.STATE_COMPLETE = 2
gui.RaytracedViewport.STATE_CANCELLED = 3

function gui.RaytracedViewport:__init()
	gui.Base.__init(self)
end
function gui.RaytracedViewport:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128,128)

	self.m_tex = gui.create("WIRenderImage",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_tex:SetShouldGammaCorrect(true)
	self.m_renderSettings = pfm.RaytracingRenderJob.Settings()
	self.m_renderSettings:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self.m_renderSettings:SetSamples(40)
	self.m_renderSettings:SetSkyStrength(30)
	self.m_renderSettings:SetSkyYaw(0.0)
	self.m_renderSettings:SetEmissionStrength(1.0)
	self.m_renderSettings:SetMaxTransparencyBounces(128)
	self.m_renderSettings:SetDenoiseMode(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_DETAILED)
	self.m_renderSettings:SetHDROutput(false)
	self.m_renderSettings:SetDeviceType(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU)
	self.m_renderSettings:SetCamType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
	self.m_renderSettings:SetPanoramaType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA)

	self.m_state = gui.RaytracedViewport.STATE_INITIAL

	self:SetToneMapping(shader.TONE_MAPPING_GAMMA_CORRECTION)

	self.m_threadPool = util.ThreadPool(4,"rendered_image_saver")
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
	self.m_tex:SetDebugName("raytraced_viewport_tex")
end
function gui.RaytracedViewport:SaveImage(path,imgFormat,hdr)
	hdr = hdr or false

	local ent = ents.create("entity")
	ent:RemoveSafely()

	self.m_threadPool:WaitForPendingCount(15)
	local imgBuf = self.m_rtJob:GetRenderResult()
	local task = util.ThreadPool.ThreadTask()
	if(hdr == false) then imgBuf:ToLDR(task) end

	local result = util.save_image(imgBuf,path,imgFormat,1.0,task)
	self.m_threadPool:AddTask(task)
	if(result == nil) then
		pfm.log("Unable to save image as '" .. path .. "'!",pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_WARNING)
	else
		pfm.log("Saving image as '" .. path .. "'...!",pfm.LOG_CATEGORY_PFM_RENDER)
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
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
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
		prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
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
	tex:SetDebugName("raytraced_viewport_ldr_tex")
	return prosper.create_render_target(prosper.RenderTargetCreateInfo(),{tex},shader.Graphics.get_render_pass())
end
function gui.RaytracedViewport:SetUseElementSizeAsRenderResolution(b) self.m_useElementSizeAsRenderResolution = b end
function gui.RaytracedViewport:GetRenderSettings() return self.m_renderSettings end
function gui.RaytracedViewport:SetRenderSettings(renderSettings) self.m_renderSettings = renderSettings end
function gui.RaytracedViewport:SetGameScene(gameScene) self.m_gameScene = gameScene end
function gui.RaytracedViewport:GetGameScene() return self.m_gameScene or game.get_scene() end
function gui.RaytracedViewport:GetState() return self.m_state end
function gui.RaytracedViewport:OnRemove()
	self:CancelRendering()
	self:ClearJob()
end
function gui.RaytracedViewport:ClearJob()
	self.m_rendering = false
	self.m_rtJob = nil
	collectgarbage()
end
function gui.RaytracedViewport:CancelRendering()
	if(self.m_rtJob == nil) then return end
	self.m_state = gui.RaytracedViewport.STATE_CANCELLED
	self.m_rtJob:CancelRendering()
	self:UpdateThinkState()
	-- self.m_rtJob = nil
end
function gui.RaytracedViewport:IsRendering()
	return (self.m_rtJob ~= nil) and self.m_rtJob:IsRendering() or false
end
function gui.RaytracedViewport:UpdateThinkState()
	if(self.m_rendering == true and self.m_rtJob:IsCancelled() == false) then
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
	if(self.m_rtJob:IsCancelled()) then return end
	if(newProgress ~= progress) then
		self:CallCallbacks("OnProgressChanged",newProgress)
	end
	if((state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE)) then
		local preStageScene = self.m_rtJob:GetPreStageScene()
		if(preStageScene ~= nil) then
			self:CallCallbacks("OnSceneComplete",preStageScene)
		else
			local tex = self.m_rtJob:GetRenderResultPreviewTexture()
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
		-- self:ClearJob()
		self.m_state = gui.RaytracedViewport.STATE_COMPLETE
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
function gui.RaytracedViewport:Refresh(preview,rtJobCallback,startFrame,frameHandler)
	preview = preview or false
	self:CancelRendering()
	if(pfm.load_unirender() == false) then return end

	if(self.m_projectManager ~= nil) then
		startFrame = self.m_projectManager:GetClampedFrameOffset()
		frameHandler = function(frameIdx) self.m_projectManager:GoToFrame(frameIdx) end
	end

	local settings = self.m_renderSettings
	if(self.m_useElementSizeAsRenderResolution) then
		settings:SetWidth(self:GetWidth())
		settings:SetHeight(self:GetHeight())
	end
	settings = self:InitializeRenderSettings(settings)
	self:SetToneMapping(settings:GetHDROutput() and shader.TONE_MAPPING_GAMMA_CORRECTION or shader.TONE_MAPPING_NONE)

	settings:SetRenderPreview(preview)
	self.m_rtJob = pfm.RaytracingRenderJob(settings,frameHandler)
	self.m_rtJob:SetStartFrame(startFrame or 0)
	self.m_rtJob:AddCallback("OnFrameStart",function()
		self:CallCallbacks("OnFrameStart")
		if(self.m_rtJob:IsProgressive() == false) then return end
		local tex = self.m_rtJob:GetProgressiveTexture()
		self.m_tex:SetTexture(tex)
	end)
	if(rtJobCallback ~= nil) then rtJobCallback(self.m_rtJob) end
	if(self.m_gameScene ~= nil) then self.m_rtJob:SetGameScene(self.m_gameScene) end

	pfm.log("Rendering image with resolution " .. settings:GetWidth() .. "x" .. settings:GetHeight() .. " and " .. settings:GetSamples() .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self.m_state = gui.RaytracedViewport.STATE_RENDERING
	self.m_rtJob:Start()

	self.m_rendering = true
	self:OnRenderStart()
	self:UpdateThinkState()
	return self.m_rtJob
end
function gui.RaytracedViewport:InitializeRenderSettings(settings) return settings end
function gui.RaytracedViewport:OnRenderStart() self:CallCallbacks("OnRenderStart") end
gui.register("WIRaytracedViewport",gui.RaytracedViewport)


util.register_class("gui.RealtimeRaytracedViewport",gui.RaytracedViewport)
function gui.RealtimeRaytracedViewport:OnInitialize()
	gui.RaytracedViewport.OnInitialize(self)
	self:SetRenderer("cycles")
	self.m_dirtyActors = {}
	self.m_hasDirtyActors = false
end
function gui.RealtimeRaytracedViewport:SetRenderer(renderer) self.m_renderer = renderer end
function gui.RealtimeRaytracedViewport:InitializeRenderSettings(settings)
	settings = settings:Copy()
	settings:SetRenderEngine(self.m_renderer)
	-- settings:SetProgressive(true)
	settings:SetSamples(100000)
	settings:SetLiveEditingEnabled(true)
	settings:SetWidth(self:GetWidth())
	settings:SetHeight(self:GetHeight())
	settings:SetColorTransform("filmic-blender")
	settings:SetColorTransformLook("Medium Contrast")
	return settings
end
function gui.RealtimeRaytracedViewport:OnRenderStart()
	gui.RaytracedViewport.OnRenderStart(self)

	local pos = Vector()
	local rot = Quaternion()
	local scene = self:GetGameScene()
	local cam = util.is_valid(scene) and scene:GetActiveCamera() or nil
	if(util.is_valid(cam)) then
		local ent = cam:GetEntity()
		pos = ent:GetPos()
		rot = ent:GetRotation()
	end
	self.m_tLastUpdate = time.real_time()
end
function gui.RealtimeRaytracedViewport:MarkActorAsDirty(ent)
	self.m_dirtyActors[ent] = true
	self.m_hasDirtyActors = true
end
function gui.RealtimeRaytracedViewport:OnThink()
	gui.RaytracedViewport.OnThink(self)

	if(self.m_tLastUpdate == nil) then return end
	local scene = self:GetGameScene()
	local cam = util.is_valid(scene) and scene:GetActiveCamera() or nil
	if(util.is_valid(cam) == false) then return end

	local t = time.real_time()
	local dt = t -self.m_tLastUpdate
	if(dt < (1.0 /24.0)) then return end -- Update at roughly 24 FPS
	self.m_tLastUpdate = t

	if(self.m_hasDirtyActors ~= true) then return end

	if(self.m_hasDirtyActors) then
		self.m_hasDirtyActors = false

		local renderer = self.m_rtJob:GetRenderer()
		if(renderer:BeginSceneEdit()) then
			for ent,_ in pairs(self.m_dirtyActors) do
				if(ent:IsValid()) then
					renderer:SyncActor(ent)
				end
			end
			self.m_dirtyActors = {}

			renderer:EndSceneEdit()
		end
	end
end
gui.register("WIRealtimeRaytracedViewport",gui.RealtimeRaytracedViewport)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/class_property.lua")
include("/shaders/pfm/pfm_calc_image_luminance.lua")
include("unirender.lua")
include("pragma_render_job.lua")

include_component("pfm_sky")

pfm = pfm or {}

util.register_class("pfm.RaytracingRenderJob", util.CallbackHandler)

util.register_class("pfm.RaytracingRenderJob.Settings")
-- Note: These have to match the enums defined in the unirender binary module!
pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE = 0
pfm.RaytracingRenderJob.Settings.CAM_TYPE_ORTHOGRAPHIC = 1
pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA = 2

pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR = 0
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT = 1
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID = 2
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_MIRRORBALL = 3
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP = 4

pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED = 0
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_AMBIENT_OCCLUSION = 1
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_NORMALS = 2
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_DIFFUSE_LIGHTING = 3
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_DIFFUSE_LIGHTING_SEPARATE = 4
pfm.RaytracingRenderJob.Settings.RENDER_MODE_ALBEDO = 5
pfm.RaytracingRenderJob.Settings.RENDER_MODE_NORMALS = 6
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DEPTH = 7
pfm.RaytracingRenderJob.Settings.RENDER_MODE_ALPHA = 8
pfm.RaytracingRenderJob.Settings.RENDER_MODE_GEOMETRY_NORMAL = 9
pfm.RaytracingRenderJob.Settings.RENDER_MODE_SHADING_NORMAL = 10
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_DIFFUSE = 11
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_DIFFUSE_REFLECT = 12
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_DIFFUSE_TRANSMIT = 13
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_GLOSSY = 14
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_GLOSSY_REFLECT = 15
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DIRECT_GLOSSY_TRANSMIT = 16
pfm.RaytracingRenderJob.Settings.RENDER_MODE_EMISSION = 17
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_DIFFUSE = 18
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_DIFFUSE_REFLECT = 19
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_DIFFUSE_TRANSMIT = 20
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_GLOSSY = 21
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_GLOSSY_REFLECT = 22
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_GLOSSY_TRANSMIT = 23
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_SPECULAR = 24
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_SPECULAR_REFLECT = 25
pfm.RaytracingRenderJob.Settings.RENDER_MODE_INDIRECT_SPECULAR_TRANSMIT = 26
pfm.RaytracingRenderJob.Settings.RENDER_MODE_UV = 27
pfm.RaytracingRenderJob.Settings.RENDER_MODE_IRRADIANCE = 28
pfm.RaytracingRenderJob.Settings.RENDER_MODE_NOISE = 29
pfm.RaytracingRenderJob.Settings.RENDER_MODE_CAUSTIC = 30
pfm.RaytracingRenderJob.Settings.RENDER_MODE_COUNT = 31

pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU = 0
pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU = 1

pfm.RaytracingRenderJob.Settings.DENOISE_MODE_NONE = 0
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_FAST = 1
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_DETAILED = 2
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_OPTIX = 3
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_OPEN_IMAGE = 4

util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderMode")
util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderEngine", "cycles")
util.register_class_property(pfm.RaytracingRenderJob.Settings, "samples", 80.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "sky", "")
util.register_class_property(pfm.RaytracingRenderJob.Settings, "skyStrength", 1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "emissionStrength", 1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "skyYaw", 0.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "maxTransparencyBounces", 128)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "lightIntensityFactor", 1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "frameCount", 1)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "supersamplingFactor", 2)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "preStageOnly", false, {
	getter = "IsPreStageOnly",
})
util.register_class_property(
	pfm.RaytracingRenderJob.Settings,
	"denoiseMode",
	pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_DETAILED
)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "transparentSky", false, {
	getter = "IsSkyTransparent",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "hdrOutput", false, {
	getter = "GetHDROutput",
	setter = "SetHDROutput",
})
util.register_class_property(
	pfm.RaytracingRenderJob.Settings,
	"deviceType",
	pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU
)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderWorld", true)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderGameEntities", true)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderPlayer", false)
util.register_class_property(
	pfm.RaytracingRenderJob.Settings,
	"camType",
	pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE
)
util.register_class_property(
	pfm.RaytracingRenderJob.Settings,
	"panoramaType",
	pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR
)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "renderPreview", false, {
	getter = "IsRenderPreview",
})

util.register_class_property(pfm.RaytracingRenderJob.Settings, "cameraFrustumCullingEnabled", true, {
	getter = "IsCameraFrustumCullingEnabled",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "pvsCullingEnabled", true, {
	setter = "SetPVSCullingEnabled",
	getter = "IsPVSCullingEnabled",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "panoramaHorizontalRange", 360.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "stereoscopic", true, {
	getter = "IsStereoscopic",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "useProgressiveRefinement", false, {
	getter = "ShouldUseProgressiveRefinement",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "progressive", false, {
	getter = "IsProgressive",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "preCalculateLight", false, {
	getter = "ShouldPreCalculateLight",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "exposure", 1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "colorTransform", "filmic-blender")
util.register_class_property(pfm.RaytracingRenderJob.Settings, "colorTransformLook", "")
util.register_class_property(pfm.RaytracingRenderJob.Settings, "liveEditingEnabled", false, {
	getter = "IsLiveEditingEnabled",
})
util.register_class_property(pfm.RaytracingRenderJob.Settings, "useOptix", false)
util.register_class_property(pfm.RaytracingRenderJob.Settings, "tileSize", 512)

function pfm.RaytracingRenderJob.Settings:__init()
	self:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self:SetWidth(512)
	self:SetHeight(512)
end
function pfm.RaytracingRenderJob.Settings:IsCubemapPanorama()
	return self:GetCamType() == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA
		and self:GetPanoramaType() == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP
end
function pfm.RaytracingRenderJob.Settings:GetWidth()
	return self.m_width
end
function pfm.RaytracingRenderJob.Settings:GetHeight()
	return self.m_height
end
function pfm.RaytracingRenderJob.Settings:SetWidth(w)
	w = math.max(w, 2)
	-- Resolution has to be dividable by 2
	if (w % 2) ~= 0 then
		w = w + 1
	end
	self.m_width = w
end
function pfm.RaytracingRenderJob.Settings:SetHeight(h)
	h = math.max(h, 2)
	-- Resolution has to be dividable by 2
	if (h % 2) ~= 0 then
		h = h + 1
	end
	self.m_height = h
end
function pfm.RaytracingRenderJob.Settings:Copy()
	local cpy = pfm.RaytracingRenderJob.Settings()
	cpy:SetRenderMode(self:GetRenderMode())
	cpy:SetRenderEngine(self:GetRenderEngine())
	cpy:SetSamples(self:GetSamples())
	cpy:SetSky(self:GetSky())
	cpy:SetSkyStrength(self:GetSkyStrength())
	cpy:SetEmissionStrength(self:GetEmissionStrength())
	cpy:SetSkyYaw(self:GetSkyYaw())
	cpy:SetMaxTransparencyBounces(self:GetMaxTransparencyBounces())
	cpy:SetLightIntensityFactor(self:GetLightIntensityFactor())
	cpy:SetFrameCount(self:GetFrameCount())
	cpy:SetSupersamplingFactor(self:GetSupersamplingFactor())
	cpy:SetPreStageOnly(self:IsPreStageOnly())
	cpy:SetDenoiseMode(self:GetDenoiseMode())
	cpy:SetTransparentSky(self:IsSkyTransparent())
	cpy:SetHDROutput(self:GetHDROutput())
	cpy:SetDeviceType(self:GetDeviceType())
	cpy:SetRenderWorld(self:GetRenderWorld())
	cpy:SetRenderGameEntities(self:GetRenderGameEntities())
	cpy:SetRenderPlayer(self:GetRenderPlayer())
	cpy:SetCamType(self:GetCamType())
	cpy:SetPanoramaType(self:GetPanoramaType())
	cpy:SetRenderPreview(self:IsRenderPreview())
	cpy:SetWidth(self:GetWidth())
	cpy:SetHeight(self:GetHeight())
	cpy:SetCameraFrustumCullingEnabled(self:IsCameraFrustumCullingEnabled())
	cpy:SetPVSCullingEnabled(self:IsPVSCullingEnabled())
	cpy:SetPanoramaHorizontalRange(self:GetPanoramaHorizontalRange())
	cpy:SetStereoscopic(self:IsStereoscopic())
	cpy:SetUseProgressiveRefinement(self:ShouldUseProgressiveRefinement())
	cpy:SetPreCalculateLight(self:ShouldPreCalculateLight())
	cpy:SetProgressive(self:IsProgressive())
	cpy:SetExposure(self:GetExposure())
	cpy:SetColorTransform(self:GetColorTransform())
	cpy:SetColorTransformLook(self:GetColorTransformLook())
	cpy:SetLiveEditingEnabled(self:IsLiveEditingEnabled())
	cpy:SetUseOptix(self:GetUseOptix())
	cpy:SetTileSize(self:GetTileSize())
	return cpy
end

pfm.RaytracingRenderJob.STATE_IDLE = 0
pfm.RaytracingRenderJob.STATE_RENDERING = 1
pfm.RaytracingRenderJob.STATE_FAILED = 2
pfm.RaytracingRenderJob.STATE_COMPLETE = 3
pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE = 4
pfm.RaytracingRenderJob.STATE_SUB_FRAME_COMPLETE = 5
function pfm.RaytracingRenderJob:__init(settings, frameHandler)
	util.CallbackHandler.__init(self)
	pfm.load_unirender()
	self.m_settings = (settings and settings:Copy()) or pfm.RaytracingRenderJob.Settings()
	self.m_startFrame = 0
	self.m_frameHandler = frameHandler
	self.m_gameScene = game.get_scene()
	self:SetAutoAdvanceSequence(false)
end
pfm.RaytracingRenderJob.generate_job_batch_script = function(jobFiles)
	if #jobFiles == 0 then
		return
	end
	local shellFileName
	local toolName
	if os.SYSTEM_WINDOWS then
		shellFileName = "render.bat"
		toolName = "bin/render_raytracing.exe"
	else
		shellFileName = "render.sh"
		toolName = "lib/render_raytracing"
	end

	local path = file.get_file_path(jobFiles[1])
	if file.exists(path) == false then
		file.create_path(path)
	end
	local f = file.open(path .. shellFileName, bit.bor(file.OPEN_MODE_BINARY, file.OPEN_MODE_WRITE))
	if f ~= nil then
		local workingPath = engine.get_working_directory()
		local files = {}
		for _, f in ipairs(jobFiles) do
			table.insert(files, file.get_file_name(f))
		end
		local jobListPath = path .. "job_list.txt"
		file.write(jobListPath, string.join(files, "\n"))

		local absJobListPath = file.find_absolute_path(jobListPath) or jobListPath

		local cmd = '"' .. workingPath .. toolName .. '" -job="' .. workingPath .. absJobListPath .. '"'
		f:WriteString(cmd)
		f:Close()

		util.open_path_in_explorer(path, shellFileName)
	end
end
function pfm.RaytracingRenderJob:GetPreStageScene()
	return self.m_preStage
end
function pfm.RaytracingRenderJob:SetGameScene(scene)
	self.m_gameScene = scene
end
function pfm.RaytracingRenderJob:GetGameScene()
	return self.m_gameScene
end
function pfm.RaytracingRenderJob:GetSettings()
	return self.m_settings
end
function pfm.RaytracingRenderJob:SetStartFrame(startFrame)
	self.m_startFrame = startFrame
end
function pfm.RaytracingRenderJob:SetAutoAdvanceSequence(autoAdvance)
	self.m_autoAdvanceSequence = autoAdvance
end

function pfm.RaytracingRenderJob:IsComplete()
	if self.m_raytracingJob == nil then
		return true
	end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress()
	if self.m_raytracingJob == nil then
		return 1.0
	end
	return self.m_raytracingJob:GetProgress()
end
function pfm.RaytracingRenderJob:GetRenderTime()
	return self.m_tRender
end
function pfm.RaytracingRenderJob:IsProgressive()
	return self.m_progressiveRendering or false
end
function pfm.RaytracingRenderJob:GetProgressiveTexture()
	return self.m_progressiveRendering and self.m_prt ~= nil and self.m_prt:GetTexture() or nil
end
function pfm.RaytracingRenderJob:GetRenderResultPreviewTexture()
	return self.m_renderResult
end
function pfm.RaytracingRenderJob:GetRenderResult()
	return self.m_currentImageBuffer
end
function pfm.RaytracingRenderJob:GetRenderResultFrameIndex()
	return self.m_renderResultFrameIndex
end
function pfm.RaytracingRenderJob:GetRenderResultRemainingSubStages()
	return self.m_renderResultRemainingSubStages
end
function pfm.RaytracingRenderJob:GenerateResult()
	if #self.m_imageBuffers == 0 then
		return
	end
	local cubemap = (#self.m_imageBuffers > 1)
	local imgCreateInfo = prosper.create_image_create_info(self.m_imageBuffers[1], cubemap)
	if cubemap == false then
		self.m_currentImageBuffer = self.m_imageBuffers[1]
	else
		self.m_currentImageBuffer = util.ImageBuffer.CreateCubemap(self.m_imageBuffers)
	end
	self.m_imageBuffers = {}
	self.m_renderResult = pfm.util.generate_thumbnail_texture(self.m_currentImageBuffer, imgCreateInfo)
	self.m_renderResult:SetDebugName("raytracing_render_job_result_tex")
end
function pfm.RaytracingRenderJob:Update()
	if self.m_tRenderStart ~= nil then
		if time.cur_time() >= self.m_tRenderStart then
			self:RenderCurrentFrame()
		end
		return
	end

	local isFrameComplete = (self.m_remainingSubStages == 0) -- No sub-stages remaining
	if (self.m_raytracingJob == nil and self.m_preStage == nil) or self.m_frameComplete then
		return pfm.RaytracingRenderJob.STATE_IDLE
	end
	local progress = (self.m_raytracingJob ~= nil) and self.m_raytracingJob:GetProgress() or 1.0
	self.m_lastProgress = progress
	local successful = true
	local resultCode
	if self.m_raytracingJob ~= nil then
		if self:IsComplete() == false then
			return pfm.RaytracingRenderJob.STATE_RENDERING
		end
		successful = self.m_raytracingJob:IsSuccessful()
		resultCode = self.m_raytracingJob:GetResultCode()
		if successful then
			local imgBuffer = self.m_raytracingJob:GetImage()
			-- util.save_image(imgBuffer,"luxcorerender.hdr",util.IMAGE_FORMAT_HDR)
			--local result,err = unirender.apply_color_transform(imgBuffer)
			--if(result == false) then console.print_warning(err) end
			table.insert(self.m_imageBuffers, imgBuffer)

			if isFrameComplete then
				self:GenerateResult()
			end
		end
		self.m_prt = nil
		self.m_raytracingJob = nil
		collectgarbage()
	end
	self.m_renderResultFrameIndex = self.m_currentFrame
	self.m_renderResultRemainingSubStages = self.m_remainingSubStages

	if successful then
		self.m_tRender = (time.time_since_epoch() - self.m_renderStartTime) / 1000000000.0
		local nextFrame = self.m_currentFrame
		if self.m_remainingSubStages == 0 then
			nextFrame = nextFrame + 1
		end

		if nextFrame == self.m_endFrame + 1 then
			local msg
			local renderSettings = self.m_settings
			if renderSettings:IsRenderPreview() then
				msg = "Preview rendering complete!"
			else
				msg = "Rendering complete! " .. renderSettings:GetFrameCount() .. " frames have been rendered!"
			end
			pfm.log(msg, pfm.LOG_CATEGORY_PFM_RENDER)

			self:OnRenderEnd()
			self.m_frameComplete = isFrameComplete
			return pfm.RaytracingRenderJob.STATE_COMPLETE
		end
		if self.m_autoAdvanceSequence then
			self:RenderNextImage()
		end
		return isFrameComplete and pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE
			or pfm.RaytracingRenderJob.STATE_SUB_FRAME_COMPLETE
	end
	return pfm.RaytracingRenderJob.STATE_FAILED
end
function pfm.RaytracingRenderJob:Start()
	self.m_remainingSubStages = 0
	self.m_imageBuffers = {}
	self.m_currentFrame = self.m_startFrame - 1
	self.m_endFrame = self.m_currentFrame + self:GetSettings():GetFrameCount()
	self.m_cancelled = false
	self:RenderNextImage()
end
function pfm.RaytracingRenderJob:OnRenderEnd() end
function pfm.RaytracingRenderJob:RenderCurrentFrame()
	self.m_tRenderStart = nil

	self:CallCallbacks("PrepareFrame")

	local cam = self.m_gameScene:GetActiveCamera()
	if cam == nil then
		return
	end

	self.m_renderStartTime = time.time_since_epoch()

	local renderSettings = self.m_settings
	if renderSettings:GetRenderEngine() ~= "pragma" then
		local createInfo = unirender.Scene.CreateInfo()
		createInfo.denoiseMode = renderSettings:GetDenoiseMode()
		createInfo.hdrOutput = renderSettings:GetHDROutput()
		createInfo.deviceType = renderSettings:GetDeviceType()
		createInfo.progressiveRefine = renderSettings:ShouldUseProgressiveRefinement()
		createInfo.preCalculateLight = renderSettings:ShouldPreCalculateLight()
		createInfo.progressive = renderSettings:IsProgressive()
		createInfo.exposure = renderSettings:GetExposure()
		createInfo.renderer = renderSettings:GetRenderEngine()
		createInfo:SetSamplesPerPixel(renderSettings:GetSamples())

		local colorTransform = renderSettings:GetColorTransform()
		local colorTransformLook = renderSettings:GetColorTransformLook()
		if colorTransformLook ~= nil then
			createInfo:SetColorTransform(colorTransform, colorTransformLook)
		else
			createInfo:SetColorTransform(colorTransform)
		end

		local w = renderSettings:GetWidth()
		local h = renderSettings:GetHeight()
		if renderSettings:IsCubemapPanorama() then
			local subStageAngles = {
				EulerAngles(0, -90, 0), -- Right
				EulerAngles(0, 90, 0), -- Left
				EulerAngles(-90, 0, 0), -- Up
				EulerAngles(90, 0, 0), -- Down
				EulerAngles(0, 0, 0), -- Forward
				EulerAngles(0, 180, 0), -- Backward
			}
			local ang = subStageAngles[6 - subStageIdx]
			cam:GetEntity():SetAngles(ang)
			cam:SetFOV(90.0)
			cam:UpdateMatrices()

			h = w
		end

		local ent = ents.create("unirender")
		util.remove(ent, true)
		local unirenderC = ent:AddComponent("unirender")

		unirender.PBRShader.set_global_renderer_identifier(renderSettings:GetRenderEngine())

		local scene = unirender.create_scene(renderSettings:GetRenderMode(), createInfo)
		local pos = cam:GetEntity():GetPos()
		local rot = cam:GetEntity():GetRotation()
		local nearZ = cam:GetNearZ()
		local farZ = cam:GetFarZ()
		local fov = cam:GetFOV()
		local vp = cam:GetProjectionMatrix() * cam:GetViewMatrix()
		local sceneFlags = unirender.Scene.SCENE_FLAG_NONE
		if renderSettings:IsCameraFrustumCullingEnabled() then
			sceneFlags = bit.bor(sceneFlags, unirender.Scene.SCENE_FLAG_BIT_CULL_OBJECTS_OUTSIDE_CAMERA_FRUSTUM)
		end
		if renderSettings:IsPVSCullingEnabled() then
			sceneFlags = bit.bor(sceneFlags, unirender.Scene.SCENE_FLAG_BIT_CULL_OBJECTS_OUTSIDE_PVS)
		end

		-- Note: Settings have to be initialized before setting up the game scene
		scene:SetSkyAngles(EulerAngles(0, renderSettings:GetSkyYaw(), 0))
		scene:SetSkyTransparent(renderSettings:IsSkyTransparent())
		scene:SetSkyStrength(renderSettings:GetSkyStrength())
		scene:SetEmissionStrength(renderSettings:GetEmissionStrength())
		scene:SetMaxTransparencyBounces(renderSettings:GetMaxTransparencyBounces())
		-- TODO: Add user options for these
		scene:SetMaxDiffuseBounces(4)
		scene:SetMaxGlossyBounces(4)
		scene:SetLightIntensityFactor(renderSettings:GetLightIntensityFactor())
		scene:SetResolution(w, h)

		self:CallCallbacks("InitializeScene", scene)

		local camType = renderSettings:GetCamType()
		local panoramaTypeToClType = {
			[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR] = unirender.Camera.PANORAMA_TYPE_EQUIRECTANGULAR,
			[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT] = unirender.Camera.PANORAMA_TYPE_FISHEYE_EQUIDISTANT,
			[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID] = unirender.Camera.PANORAMA_TYPE_FISHEYE_EQUISOLID,
			[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_MIRRORBALL] = unirender.Camera.PANORAMA_TYPE_MIRRORBALL,
			[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP] = unirender.Camera.PANORAMA_TYPE_EQUIRECTANGULAR,
		}
		local camTypeToClType = {
			[pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE] = unirender.Camera.TYPE_PERSPECTIVE,
			[pfm.RaytracingRenderJob.Settings.CAM_TYPE_ORTHOGRAPHIC] = unirender.Camera.TYPE_ORTHOGRAPHIC,
			[pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA] = unirender.Camera.TYPE_PANORAMA,
		}

		local panoramaType = renderSettings:GetPanoramaType()
		if panoramaType == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP then
			camType = unirender.Camera.TYPE_PERSPECTIVE
		end

		local clCam = scene:GetCamera()
		clCam:SetCameraType(camTypeToClType[camType])
		clCam:SetPanoramaType(panoramaTypeToClType[panoramaType])

		-- TODO: This doesn't belong here!
		local pfmCam = cam:GetEntity():GetComponent("pfm_camera")
		--[[if(pfmCam ~= nil) then
			local camData = pfmCam:GetCameraData()
			-- print("Using focal distance: ",camData:GetFocalDistance())
			clCam:SetFocalDistance(camData:GetFocalDistance())
			clCam:SetBokehRatio(camData:GetApertureBokehRatio())
			clCam:SetBladeCount(camData:GetApertureBladeCount())
			clCam:SetBladesRotation(camData:GetApertureBladesRotation())
			clCam:SetDepthOfFieldEnabled(false)--camData:IsDepthOfFieldEnabled())
			clCam:SetApertureSizeFromFStop(camData:GetFStop(),math.calc_focal_length_from_fov(fov,camData:GetSensorSize()))
		else clCam:SetDepthOfFieldEnabled(false) end]]
		clCam:SetDepthOfFieldEnabled(false)

		clCam:SetEquirectangularHorizontalRange(renderSettings:GetPanoramaHorizontalRange())
		clCam:SetStereoscopic(renderSettings:IsStereoscopic())
		if #renderSettings:GetSky() > 0 then
			scene:SetSky(renderSettings:GetSky())
		end

		unirenderC:InvokeEventCallbacks(ents.UnirenderComponent.EVENT_INITIALIZE_SCENE, { scene, renderSettings })
		local entSky, skyC = ents.citerator(ents.COMPONENT_PFM_SKY)()
		if skyC ~= nil then
			skyC:ApplySceneSkySettings(scene)
		end

		local function is_static_cache_entity(ent)
			if ent:IsMapEntity() then
				return true
			end
			local pfmActorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if pfmActorC ~= nil and pfmActorC:IsStatic() then
				return true
			end
			return false
		end

		local pm = tool.get_filmmaker()
		local staticGeometryCache
		if util.is_valid(pm) then
			staticGeometryCache = pm:GetStaticGeometryCache()
			if staticGeometryCache == nil and renderSettings:GetRenderWorld() then
				staticGeometryCache = unirender.create_cache()
				staticGeometryCache:InitializeFromGameScene(self.m_gameScene, is_static_cache_entity)

				pm:SetStaticGeometryCache(staticGeometryCache)
			end
		end

		scene:InitializeFromGameScene(self.m_gameScene, pos, rot, vp, nearZ, farZ, fov, sceneFlags, function(ent)
			if is_static_cache_entity(ent) then
				return false
			end
			if ent:IsWorld() then
				return renderSettings:GetRenderWorld()
			end
			if ent:IsPlayer() then
				return renderSettings:GetRenderPlayer()
			end

			local owner = ent:GetOwner()
			if owner ~= nil and owner:IsPlayer() and renderSettings:GetRenderPlayer() == false then
				return false
			end

			if
				ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM)
				or ent:HasComponent("util_transform_arrow") --[[or ent:HasComponent("pfm_light")]]
				or ent:HasComponent("pfm_camera")
			then
				return false
			end
			return renderSettings:GetRenderGameEntities() or ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
		end, function(ent)
			return true
		end)
		if renderSettings:GetRenderWorld() and staticGeometryCache ~= nil then
			scene:AddCache(staticGeometryCache)
		end

		-- We want particle effects with bloom to emit light, so we'll add a light source for each particle.
		for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PARTICLE_SYSTEM) }) do
			local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
			if ptC:IsBloomEnabled() then
				local mat = ptC:GetMaterial()
				if mat ~= nil then
					-- print("Adding light source for particles of particle system " .. tostring(ent) .. ", which uses material '" .. mat:GetName() .. "'...")
					-- print("Particle system uses " .. util.get_type_name(ptC:GetRenderers()[1]) .. " renderer!")
					-- To get the correct color for the particles, we need to know the color of the texture.
					-- If we don't know the color, we'll compute it using the luminance shader (and store it
					-- in the material for future use).
					local luminance = util.Luminance.get_material_luminance(mat)
					if luminance == nil then
						pfm.log(
							"Particle system "
								.. tostring(ent)
								.. " uses material '"
								.. mat:GetName()
								.. "', but material has no luminance information, which is required to determine emission color! Computing...",
							pfm.LOG_CATEGORY_PFM_RENDER
						)
						local texInfo = (mat ~= nil) and mat:GetTextureInfo("albedo_map") or nil
						local tex = (texInfo ~= nil) and texInfo:GetTexture() or nil
						local vkTex = (tex ~= nil) and tex:GetVkTexture() or nil
						if vkTex ~= nil then
							-- No luminance information available; Calculate it now
							local alphaMode = ptC:GetEffectiveAlphaMode()
							local useBlackAsTransparency = (
								alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE_BY_COLOR
							)
							luminance = shader
								.get("pfm_calc_image_luminance")
								:GetWrapper()
								:CalcImageLuminance(vkTex, useBlackAsTransparency)
							-- TODO: What about animated textures?

							local msg = "Computed luminance: " .. tostring(luminance)
							if useBlackAsTransparency then
								msg = msg .. " (Black was interpreted as transparency)"
							end
							msg = msg .. "! Applying to material..."
							pfm.log(msg, pfm.LOG_CATEGORY_PFM_RENDER)

							util.Luminance.set_material_luminance(mat, luminance)
							mat:Save()
						end
					end
					if luminance ~= nil then
						local avgIntensity = luminance:GetAvgIntensity()
						local bloomCol = ptC:GetEffectiveBloomColorFactor()
						local numRenderParticles = ptC:GetRenderParticleCount()
						-- print("Adding light source(s) for " .. numRenderParticles .. " particles...")
						local intensityFactor = 1.0
						-- TODO: Handle this differently
						if util.get_type_name(ptC:GetRenderers()[1]) == "RendererSpriteTrail" then
							intensityFactor = 0.05
						end
						for i = 1, numRenderParticles do
							local ptIdx = ptC:GetParticleIndexFromParticleBufferIndex(i - 1)
							local pt = ptC:GetParticle(ptIdx)
							local radius = pt:GetRadius()
							-- TODO: Take length into account, as well as the particle shader?
							local alpha = pt:GetAlpha()
							local col = pt:GetColor() * bloomCol
							col = Color(col * Vector4(avgIntensity, 1.0))
							col.a = 255

							local pos = pt:GetPosition()
							local light = scene:AddLightSource(unirender.LightSource.TYPE_POINT, pos)
							light:SetColor(col)
							local intensity = intensityFactor * math.pow(10.0 * (alpha ^ 2.0) * radius, 1.0 / 1.5) -- Decline growth for larger factors
							-- print("Light: ",intensity,alpha,radius,intensityFactor)
							light:SetIntensity(intensity) -- TODO: This may require some tweaking
						end
					end
				end
			end
		end

		local ang = rot:ToEulerAngles()
		pfm.log(
			"Starting render job for frame "
				.. (self.m_currentFrame + 1)
				.. " with camera position ("
				.. pos.x
				.. ","
				.. pos.y
				.. ","
				.. pos.z
				.. ") and angles ("
				.. ang.p
				.. ","
				.. ang.y
				.. ","
				.. ang.r
				.. ").",
			pfm.LOG_CATEGORY_PFM_RENDER
		)

		self.m_frameComplete = false
		if renderSettings:IsPreStageOnly() then
			self.m_preStage = scene
			self.m_lastProgress = 0.0
			return
		end
		self.m_preStage = nil

		scene:Finalize()
		local flags = unirender.Renderer.FLAG_NONE
		if renderSettings:IsLiveEditingEnabled() then
			flags = bit.bor(flags, unirender.Renderer.FLAG_ENABLE_LIVE_EDITING_BIT)
		end
		self.m_renderEngine = renderSettings:GetRenderEngine()
		local renderer, err = unirender.create_renderer(scene, self.m_renderEngine, flags)
		if renderer == false then
			local msg = "Unable to create renderer for render engine '"
				.. renderSettings:GetRenderEngine()
				.. "': "
				.. err
				.. "!"
			pfm.log(msg, pfm.LOG_CATEGORY_PFM_RENDER, pfm.LOG_SEVERITY_WARNING)
			error(msg)
			return
		end

		local apiData = renderer:GetApiData()
		if
			renderSettings:GetDeviceType() == pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU
			and self.m_renderEngine == "cycles"
		then
			apiData:GetFromPath("cycles"):SetValue("enableOptix", udm.TYPE_BOOLEAN, renderSettings:GetUseOptix())
		end

		--[[
		-- Some Cycles debugging options:
		apiData:GetFromPath("cycles/debug"):SetValue("dump_shader_graphs",udm.TYPE_BOOLEAN,true)
		apiData:GetFromPath("cycles/debug"):SetValue("use_debug_mesh_shader",udm.TYPE_BOOLEAN,true)
		apiData:GetFromPath("cycles/shader"):SetValue("dontSimplifyGraphs",udm.TYPE_BOOLEAN,true)

		local udmDebugScene = apiData:GetFromPath("cycles/debug/debugScene")
		udmDebugScene:SetValue("enabled",udm.TYPE_BOOLEAN,true)
		udmDebugScene:SetValue("outputFileName",udm.TYPE_STRING,"E:/projects/cycles/examples/scene_monkey.png")
		udmDebugScene:AddArray("xmlFiles",1,udm.TYPE_STRING):Set(0,"E:/projects/cycles/examples/scene_monkey.xml")

		local udmDebugStandalone = apiData:GetFromPath("cycles/debug/debugStandalone")
		udmDebugStandalone:SetValue("xmlFile",udm.TYPE_STRING,"E:\\projects\\cycles\\examples\\scene_monkey.xml")
		udmDebugStandalone:SetValue("outputFile",udm.TYPE_STRING,"E:\\projects\\cycles\\build_winx64\\bin\\RelWithDebInfo\\output.png")
		udmDebugStandalone:SetValue("samples",udm.TYPE_STRING,"20")
		udmDebugStandalone:SetValue("device",udm.TYPE_STRING,"OPTIX")

		local udmDebugStandalone = apiData:GetFromPath("cycles/debug/debugStandalone")
		udmDebugStandalone:SetValue("xmlFile",udm.TYPE_STRING,"E:\\projects\\cycles\\examples\\scene_monkey.xml")
		udmDebugStandalone:SetValue("outputFile",udm.TYPE_STRING,"E:\\projects\\cycles\\build_winx64\\bin\\RelWithDebInfo\\output.png")
		udmDebugStandalone:SetValue("samples",udm.TYPE_STRING,"20")
		udmDebugStandalone:SetValue("device",udm.TYPE_STRING,"OPTIX")

		-- LuxCoreRender:
		apiData:GetFromPath("luxCoreRender/debug"):SetValue("rawOutputFileName",udm.TYPE_STRING,"debug_render_output.hdr")

		-- General:
		apiData:GetFromPath("debug"):SetValue("dumpRenderStageImages",udm.TYPE_BOOLEAN,true)
		apiData:GetFromPath("cycles/scene/actors/27707b26-1f7f-4829-a979-bb0df9a22450"):SetValue("maxBounces",udm.TYPE_UINT32,1)
		]]

		local job = renderer:StartRender()
		job:Start()
		self.m_rtScene = scene
		self.m_rtRenderer = renderer

		self.m_raytracingJob = job
		self.m_progressiveRendering = createInfo.progressive
		if self.m_progressiveRendering then
			self.m_prt = renderer:CreateProgressiveImageHandler()
		end
	else
		local job = pfm.PragmaRenderJob(renderSettings)
		job:Start()
		self.m_raytracingJob = job
		self.m_rtRenderer = pfm.PragmaRenderer(job, self)
	end

	self.m_lastProgress = 0.0
	self:CallCallbacks("OnFrameStart")
end
function pfm.RaytracingRenderJob:RenderNextImage()
	if self.m_remainingSubStages == 0 then
		self.m_currentFrame = self.m_currentFrame + 1
		self.m_remainingSubStages = self:GetSettings():IsCubemapPanorama() and 6 or 1
	end
	self.m_remainingSubStages = self.m_remainingSubStages - 1
	local subStageIdx = self.m_remainingSubStages

	local renderSettings = self.m_settings
	--[[if(self.m_currentFrame == self.m_endFrame +1) then
		local msg
		if(renderSettings:IsRenderPreview()) then msg = "Preview rendering complete!"
		else msg = "Rendering complete! " .. renderSettings:GetFrameCount() .. " frames have been rendered!" end
		pfm.log(msg,pfm.LOG_CATEGORY_PFM_RENDER)
		return true
	end]]

	-- Make sure we're at the right frame
	if self.m_frameHandler ~= nil then
		self.m_frameHandler(self.m_currentFrame)
	end
	-- We want to wait for a bit before rendering, to make sure
	-- everything for this frame has been set up properly.
	-- If the scene contains particle systems, the frame must not be
	-- changed until rendering has been completed!
	self.m_tRenderStart = time.cur_time() + 0.2
	return false
end
function pfm.RaytracingRenderJob:IsRendering()
	return (self.m_raytracingJob ~= nil and self.m_raytracingJob:IsComplete() == false and self.m_cancelled ~= true)
end
function pfm.RaytracingRenderJob:GetRenderScene()
	return self.m_rtScene
end
function pfm.RaytracingRenderJob:GetRenderer()
	return self.m_rtRenderer
end
function pfm.RaytracingRenderJob:IsCancelled()
	return self.m_cancelled or false
end
function pfm.RaytracingRenderJob:RestartRendering()
	if self:IsRendering() == false then
		return
	end
	self.m_rtRenderer:Restart()
	self.m_cancelled = false
end
function pfm.RaytracingRenderJob:CancelRendering()
	self.m_prt = nil
	self.m_tRenderStart = nil
	self.m_cancelled = true
	if self:IsRendering() == false then
		return
	end
	self.m_raytracingJob:Cancel()
	self:OnRenderEnd()
end
function pfm.RaytracingRenderJob:IsComplete()
	if self.m_raytracingJob == nil then
		return true
	end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress()
	return self.m_lastProgress
end

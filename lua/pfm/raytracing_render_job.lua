--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/class_property.lua")
include("/shaders/pfm/pfm_calc_image_luminance.lua")
include("cycles.lua")

pfm = pfm or {}

util.register_class("pfm.RaytracingRenderJob",util.CallbackHandler)

util.register_class("pfm.RaytracingRenderJob.Settings")
pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE = 0
pfm.RaytracingRenderJob.Settings.CAM_TYPE_ORTHOGRAPHIC = 1
pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA = 2

pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR = 0
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT = 1
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID = 2
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_MIRRORBALL = 3
pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP = 4

-- Note: These map to cycles enums and are redundant, but at this
-- point in time it cannot be guaranteed that the Cycles module has
-- been loaded.
pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED = 0
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_AMBIENT_OCCLUSION = 1
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_NORMALS = 2
pfm.RaytracingRenderJob.Settings.RENDER_MODE_BAKE_DIFFUSE_LIGHTING = 3
pfm.RaytracingRenderJob.Settings.RENDER_MODE_ALBEDO = 4
pfm.RaytracingRenderJob.Settings.RENDER_MODE_NORMALS = 5
pfm.RaytracingRenderJob.Settings.RENDER_MODE_DEPTH = 6

pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU = 0
pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU = 1

pfm.RaytracingRenderJob.Settings.DENOISE_MODE_NONE = 0
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_FAST = 1
pfm.RaytracingRenderJob.Settings.DENOISE_MODE_DETAILED = 2

util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderMode")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"samples",80.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"sky","")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"skyStrength",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"emissionStrength",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"skyYaw",0.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"maxTransparencyBounces",128)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"lightIntensityFactor",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"frameCount",1)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"preStageOnly",false,{
	getter = "IsPreStageOnly"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"denoiseMode",pfm.RaytracingRenderJob.Settings.DENOISE_MODE_DETAILED)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"hdrOutput",false,{
	getter = "GetHDROutput",
	setter = "SetHDROutput"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"deviceType",pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderWorld",true)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderGameEntities",true)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderPlayer",false)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"camType",pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"panoramaType",pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderPreview",false,{
	getter = "IsRenderPreview"
})

util.register_class_property(pfm.RaytracingRenderJob.Settings,"cameraFrustumCullingEnabled",true,{
	getter = "IsCameraFrustumCullingEnabled"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"pvsCullingEnabled",true,{
	setter = "SetPVSCullingEnabled",
	getter = "IsPVSCullingEnabled"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"panoramaHorizontalRange",360.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"stereoscopic",true,{
	getter = "IsStereoscopic"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"useProgressiveRefinement",false,{
	getter = "ShouldUseProgressiveRefinement"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"progressive",false,{
	getter = "IsProgressive"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"exposure",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"colorTransform","filmic-blender")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"colorTransformLook","")

function pfm.RaytracingRenderJob.Settings:__init()
	self:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self:SetWidth(512)
	self:SetHeight(512)
end
function pfm.RaytracingRenderJob.Settings:IsCubemapPanorama()
	return self:GetCamType() == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA and self:GetPanoramaType() == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP
end
function pfm.RaytracingRenderJob.Settings:GetWidth() return self.m_width end
function pfm.RaytracingRenderJob.Settings:GetHeight() return self.m_height end
function pfm.RaytracingRenderJob.Settings:SetWidth(w)
	w = math.max(w,2)
	-- Resolution has to be dividable by 2
	if((w %2) ~= 0) then w = w +1 end
	self.m_width = w
end
function pfm.RaytracingRenderJob.Settings:SetHeight(h)
	h = math.max(h,2)
	-- Resolution has to be dividable by 2
	if((h %2) ~= 0) then h = h +1 end
	self.m_height = h
end
function pfm.RaytracingRenderJob.Settings:Copy()
	local cpy = pfm.RaytracingRenderJob.Settings()
	cpy:SetRenderMode(self:GetRenderMode())
	cpy:SetSamples(self:GetSamples())
	cpy:SetSky(self:GetSky())
	cpy:SetSkyStrength(self:GetSkyStrength())
	cpy:SetEmissionStrength(self:GetEmissionStrength())
	cpy:SetSkyYaw(self:GetSkyYaw())
	cpy:SetMaxTransparencyBounces(self:GetMaxTransparencyBounces())
	cpy:SetLightIntensityFactor(self:GetLightIntensityFactor())
	cpy:SetFrameCount(self:GetFrameCount())
	cpy:SetPreStageOnly(self:IsPreStageOnly())
	cpy:SetDenoiseMode(self:GetDenoiseMode())
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
	cpy:SetProgressive(self:IsProgressive())
	cpy:SetExposure(self:GetExposure())
	cpy:SetColorTransform(self:GetColorTransform())
	cpy:SetColorTransformLook(self:GetColorTransformLook())
	return cpy
end

pfm.RaytracingRenderJob.STATE_IDLE = 0
pfm.RaytracingRenderJob.STATE_RENDERING = 1
pfm.RaytracingRenderJob.STATE_FAILED = 2
pfm.RaytracingRenderJob.STATE_COMPLETE = 3
pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE = 4
pfm.RaytracingRenderJob.STATE_SUB_FRAME_COMPLETE = 5
function pfm.RaytracingRenderJob:__init(projectManager,settings)
	util.CallbackHandler.__init(self)
	pfm.load_cycles()
	self.m_settings = (settings and settings:Copy()) or pfm.RaytracingRenderJob.Settings()
	self.m_startFrame = 0
	self.m_projectManager = projectManager
	self.m_gameScene = game.get_scene()
	self:SetAutoAdvanceSequence(false)
end
pfm.RaytracingRenderJob.generate_job_batch_script = function(jobFiles,wd,addonPath)
	if(#jobFiles == 0) then return end
	addonPath = addonPath or util.get_addon_path()
	local shellFileName
	local toolName
	if(os.SYSTEM_WINDOWS) then
		shellFileName = "render.bat"
		toolName = "bin/render_raytracing.exe"
	else
		shellFileName = "render.sh"
		toolName = "lib/render_raytracing"
	end

	local path = file.get_file_path(jobFiles[1])
	file.create_path(path)
	local f = file.open(addonPath .. path .. shellFileName,bit.bor(file.OPEN_MODE_BINARY,file.OPEN_MODE_WRITE))
	if(f ~= nil) then
		local workingPath = wd or engine.get_working_directory()
		local files = {}
		for _,f in ipairs(jobFiles) do
			table.insert(files,workingPath .. addonPath .. f)
		end
		local cmd = workingPath .. toolName .. " " .. string.join(files,' ')
		f:WriteString(cmd)
		f:Close()

		util.open_path_in_explorer(addonPath .. path,shellFileName)
	end
end
function pfm.RaytracingRenderJob:GetPreStageScene() return self.m_preStage end
function pfm.RaytracingRenderJob:SetGameScene(scene) self.m_gameScene = scene end
function pfm.RaytracingRenderJob:GetGameScene() return self.m_gameScene end
function pfm.RaytracingRenderJob:GetSettings() return self.m_settings end
function pfm.RaytracingRenderJob:SetStartFrame(startFrame) self.m_startFrame = startFrame end
function pfm.RaytracingRenderJob:SetAutoAdvanceSequence(autoAdvance) self.m_autoAdvanceSequence = autoAdvance end

function pfm.RaytracingRenderJob:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress()
	if(self.m_raytracingJob == nil) then return 1.0 end
	return self.m_raytracingJob:GetProgress()
end
function pfm.RaytracingRenderJob:GetRenderTime() return self.m_tRender end
function pfm.RaytracingRenderJob:IsProgressive() return self.m_progressiveRendering or false end
function pfm.RaytracingRenderJob:GetProgressiveTexture() return self.m_progressiveRendering and self.m_prt:GetTexture() or nil end
function pfm.RaytracingRenderJob:GetRenderResultTexture() return self.m_renderResult end
function pfm.RaytracingRenderJob:GetRenderResult() return self.m_currentImageBuffer end
function pfm.RaytracingRenderJob:GetRenderResultFrameIndex() return self.m_renderResultFrameIndex end
function pfm.RaytracingRenderJob:GetRenderResultRemainingSubStages() return self.m_renderResultRemainingSubStages end
function pfm.RaytracingRenderJob:GenerateResult()
	if(#self.m_imageBuffers == 0) then return end
	local img
	local cubemap = (#self.m_imageBuffers > 1)
	local imgCreateInfo = prosper.create_image_create_info(self.m_imageBuffers[1],cubemap)
	imgCreateInfo.usageFlags = bit.bor(imgCreateInfo.usageFlags,prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_TRANSFER_SRC_BIT,prosper.IMAGE_USAGE_TRANSFER_DST_BIT)
	if(cubemap == false) then
		self.m_currentImageBuffer = self.m_imageBuffers[1]
		img = prosper.create_image(self.m_currentImageBuffer,imgCreateInfo)
	else
		self.m_currentImageBuffer = util.ImageBuffer.CreateCubemap(self.m_imageBuffers)
		img = prosper.create_image(self.m_currentImageBuffer,imgCreateInfo)
	end
	self.m_imageBuffers = {}

	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	self.m_renderResult = prosper.create_texture(img,prosper.TextureCreateInfo(),imgViewCreateInfo,samplerCreateInfo)
end
function pfm.RaytracingRenderJob:Update()
	if(self.m_tRenderStart ~= nil) then
		if(time.cur_time() >= self.m_tRenderStart) then
			self:RenderCurrentFrame()
		end
		return
	end

	local isFrameComplete = (self.m_remainingSubStages == 0) -- No sub-stages remaining

	if(self.m_raytracingJob == nil and self.m_preStage == nil) then return pfm.RaytracingRenderJob.STATE_IDLE end
	local progress = (self.m_raytracingJob ~= nil) and self.m_raytracingJob:GetProgress() or 1.0
	self.m_lastProgress = progress
	local successful = true
	if(self.m_raytracingJob ~= nil) then
		if(self:IsComplete() == false) then return pfm.RaytracingRenderJob.STATE_RENDERING end
		successful = self.m_raytracingJob:IsSuccessful()
		if(successful) then
			local imgBuffer = self.m_raytracingJob:GetResult()
			--local result,err = cycles.apply_color_transform(imgBuffer)
			--if(result == false) then console.print_warning(err) end
			table.insert(self.m_imageBuffers,imgBuffer)

			if(isFrameComplete) then self:GenerateResult() end
		end
		self.m_prt = nil
		self.m_raytracingJob = nil
	end
	self.m_renderResultFrameIndex = self.m_currentFrame
	self.m_renderResultRemainingSubStages = self.m_remainingSubStages

	if(successful) then
		self.m_tRender = (time.time_since_epoch() -self.m_renderStartTime) /1000000000.0
		local nextFrame = self.m_currentFrame
		if(self.m_remainingSubStages == 0) then
			nextFrame = nextFrame +1
		end

		if(nextFrame == self.m_endFrame +1) then
			local msg
			local renderSettings = self.m_settings
			if(renderSettings:IsRenderPreview()) then msg = "Preview rendering complete!"
			else msg = "Rendering complete! " .. renderSettings:GetFrameCount() .. " frames have been rendered!" end
			pfm.log(msg,pfm.LOG_CATEGORY_PFM_RENDER)
			return pfm.RaytracingRenderJob.STATE_COMPLETE
		end
		if(self.m_autoAdvanceSequence) then self:RenderNextImage() end
		return isFrameComplete and pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE or pfm.RaytracingRenderJob.STATE_SUB_FRAME_COMPLETE
	end
	return pfm.RaytracingRenderJob.STATE_FAILED
end
function pfm.RaytracingRenderJob:Start()
	self.m_remainingSubStages = 0
	self.m_imageBuffers = {}
	self.m_currentFrame = self.m_startFrame -1
	self.m_endFrame = self.m_currentFrame +self:GetSettings():GetFrameCount()
	self:RenderNextImage()
end
-- TODO: Implement this in a better way
local g_staticGeometryCache
function pfm.RaytracingRenderJob:RenderCurrentFrame()
	self.m_tRenderStart = nil

	self:CallCallbacks("PrepareFrame")

	local cam = self.m_gameScene:GetActiveCamera()
	if(cam == nil) then return end

	self.m_renderStartTime = time.time_since_epoch()
	local renderSettings = self.m_settings
	local createInfo = cycles.Scene.CreateInfo()
	createInfo.denoiseMode = renderSettings:GetDenoiseMode()
	createInfo.hdrOutput = renderSettings:GetHDROutput()
	createInfo.deviceType = renderSettings:GetDeviceType()
	createInfo.progressiveRefine = renderSettings:ShouldUseProgressiveRefinement()
	createInfo.progressive = renderSettings:IsProgressive()
	createInfo.exposure = renderSettings:GetExposure()
	createInfo:SetSamplesPerPixel(renderSettings:GetSamples())

	local colorTransform = renderSettings:GetColorTransform()
	local colorTransformLook = renderSettings:GetColorTransformLook()
	if(colorTransformLook ~= nil) then createInfo:SetColorTransform(colorTransform,colorTransformLook)
	else createInfo:SetColorTransform(colorTransform) end

	local w = renderSettings:GetWidth()
	local h = renderSettings:GetHeight()
	if(renderSettings:IsCubemapPanorama()) then
		local subStageAngles = {
			EulerAngles(0,-90,0), -- Right
			EulerAngles(0,90,0), -- Left
			EulerAngles(-90,0,0), -- Up
			EulerAngles(90,0,0), -- Down
			EulerAngles(0,0,0), -- Forward
			EulerAngles(0,180,0) -- Backward
		}
		local ang = subStageAngles[6 -subStageIdx]
		cam:GetEntity():SetAngles(ang)
		cam:SetFOV(90.0)
		cam:UpdateMatrices()

		h = w
	end

	local scene = cycles.create_scene(renderSettings:GetRenderMode(),createInfo)
	local pos = cam:GetEntity():GetPos()
	local rot = cam:GetEntity():GetRotation()
	local nearZ = cam:GetNearZ()
	local farZ = cam:GetFarZ()
	local fov = cam:GetFOV()
	local vp = cam:GetProjectionMatrix() *cam:GetViewMatrix()
	local sceneFlags = cycles.Scene.SCENE_FLAG_NONE
	if(renderSettings:IsCameraFrustumCullingEnabled()) then sceneFlags = bit.bor(sceneFlags,cycles.Scene.SCENE_FLAG_BIT_CULL_OBJECTS_OUTSIDE_CAMERA_FRUSTUM) end
	if(renderSettings:IsPVSCullingEnabled()) then sceneFlags = bit.bor(sceneFlags,cycles.Scene.SCENE_FLAG_BIT_CULL_OBJECTS_OUTSIDE_PVS) end
	
	-- Note: Settings have to be initialized before setting up the game scene
	scene:SetSkyAngles(EulerAngles(0,renderSettings:GetSkyYaw(),0))
	scene:SetSkyStrength(renderSettings:GetSkyStrength())
	scene:SetEmissionStrength(renderSettings:GetEmissionStrength())
	scene:SetMaxTransparencyBounces(renderSettings:GetMaxTransparencyBounces())
	-- TODO: Add user options for these
	scene:SetMaxDiffuseBounces(4)
	scene:SetMaxGlossyBounces(4)
	scene:SetLightIntensityFactor(renderSettings:GetLightIntensityFactor())
	scene:SetResolution(w,h)

	local camType = renderSettings:GetCamType()
	local panoramaTypeToClType = {
		[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR] = cycles.Camera.PANORAMA_TYPE_EQUIRECTANGULAR,
		[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT] = cycles.Camera.PANORAMA_TYPE_FISHEYE_EQUIDISTANT,
		[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID] = cycles.Camera.PANORAMA_TYPE_FISHEYE_EQUISOLID,
		[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_MIRRORBALL] = cycles.Camera.PANORAMA_TYPE_MIRRORBALL,
		[pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP] = cycles.Camera.PANORAMA_TYPE_EQUIRECTANGULAR
	}
	local camTypeToClType = {
		[pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE] = cycles.Camera.TYPE_PERSPECTIVE,
		[pfm.RaytracingRenderJob.Settings.CAM_TYPE_ORTHOGRAPHIC] = cycles.Camera.TYPE_ORTHOGRAPHIC,
		[pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA] = cycles.Camera.TYPE_PANORAMA
	}

	local panoramaType = renderSettings:GetPanoramaType()
	if(panoramaType == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP) then camType = cycles.Camera.TYPE_PERSPECTIVE end

	local clCam = scene:GetCamera()
	clCam:SetCameraType(camTypeToClType[camType])
	clCam:SetPanoramaType(panoramaTypeToClType[panoramaType])

	local pfmCam = cam:GetEntity():GetComponent(ents.COMPONENT_PFM_CAMERA)
	if(pfmCam ~= nil) then
		local camData = pfmCam:GetCameraData()
		-- print("Using focal distance: ",camData:GetFocalDistance())
		clCam:SetFocalDistance(camData:GetFocalDistance())
		clCam:SetBokehRatio(camData:GetApertureBokehRatio())
		clCam:SetBladeCount(camData:GetApertureBladeCount())
		clCam:SetBladesRotation(camData:GetApertureBladesRotation())
		clCam:SetDepthOfFieldEnabled(false)--camData:IsDepthOfFieldEnabled())
		clCam:SetApertureSizeFromFStop(camData:GetFStop(),math.calc_focal_length_from_fov(fov,camData:GetSensorSize()))
	else clCam:SetDepthOfFieldEnabled(false) end

	clCam:SetEquirectangularHorizontalRange(renderSettings:GetPanoramaHorizontalRange())
	clCam:SetStereoscopic(renderSettings:IsStereoscopic())

	local function is_static_cache_entity(ent)
		return ent:IsMapEntity()
	end

	if(g_staticGeometryCache == nil and renderSettings:GetRenderWorld()) then
		g_staticGeometryCache = cycles.create_cache()
		g_staticGeometryCache:InitializeFromGameScene(self.m_gameScene,is_static_cache_entity)
	end

	scene:InitializeFromGameScene(self.m_gameScene,pos,rot,vp,nearZ,farZ,fov,sceneFlags,function(ent)
		if(is_static_cache_entity(ent)) then return false end
		if(ent:IsWorld()) then return renderSettings:GetRenderWorld() end
		if(ent:IsPlayer()) then return renderSettings:GetRenderPlayer() end
		if(ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM) or ent:HasComponent("util_transform_arrow") or ent:HasComponent("pfm_light") or ent:HasComponent("pfm_camera")) then return false end
		return renderSettings:GetRenderGameEntities() or ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
	end,function(ent)
		return true
	end)
	if(renderSettings:GetRenderWorld() and g_staticGeometryCache ~= nil) then scene:AddCache(g_staticGeometryCache) end
	if(#renderSettings:GetSky() > 0) then scene:SetSky(renderSettings:GetSky()) end

	-- We want particle effects with bloom to emit light, so we'll add a light source for each particle.
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PARTICLE_SYSTEM)}) do
		local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
		if(ptC:IsBloomEnabled()) then
			local mat = ptC:GetMaterial()
			if(mat ~= nil) then
				-- print("Adding light source for particles of particle system " .. tostring(ent) .. ", which uses material '" .. mat:GetName() .. "'...")
				-- print("Particle system uses " .. util.get_type_name(ptC:GetRenderers()[1]) .. " renderer!")
				-- To get the correct color for the particles, we need to know the color of the texture.
				-- If we don't know the color, we'll compute it using the luminance shader (and store it
				-- in the material for future use).
				local luminance = util.Luminance.get_material_luminance(mat)
				if(luminance == nil) then
					pfm.log("Particle system " .. tostring(ent) .. " uses material '" .. mat:GetName() .. "', but material has no luminance information, which is required to determine emission color! Computing...",pfm.LOG_CATEGORY_PFM_RENDER)
					local texInfo = (mat ~= nil) and mat:GetTextureInfo("albedo_map") or nil
					local tex = (texInfo ~= nil) and texInfo:GetTexture() or nil
					local vkTex = (tex ~= nil) and tex:GetVkTexture() or nil
					if(vkTex ~= nil) then
						-- No luminance information available; Calculate it now
						local alphaMode = ptC:GetEffectiveAlphaMode()
						local useBlackAsTransparency = (alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE_BY_COLOR)
						luminance = shader.get("pfm_calc_image_luminance"):CalcImageLuminance(vkTex,useBlackAsTransparency)
						-- TODO: What about animated textures?

						local msg = "Computed luminance: " .. tostring(luminance)
						if(useBlackAsTransparency) then msg = msg .. " (Black was interpreted as transparency)" end
						msg = msg .. "! Applying to material..."
						pfm.log(msg,pfm.LOG_CATEGORY_PFM_RENDER)

						util.Luminance.set_material_luminance(mat,luminance)
						mat:Save()
					end
				end
				if(luminance ~= nil) then
					local avgIntensity = luminance:GetAvgIntensity()
					local bloomCol = ptC:GetEffectiveBloomColorFactor()
					local numRenderParticles = ptC:GetRenderParticleCount()
					-- print("Adding light source(s) for " .. numRenderParticles .. " particles...")
					local intensityFactor = 1.0
					-- TODO: Handle this differently
					if(util.get_type_name(ptC:GetRenderers()[1]) == "RendererSpriteTrail") then intensityFactor = 0.05 end
					for i=1,numRenderParticles do
						local ptIdx = ptC:GetParticleIndexFromParticleBufferIndex(i -1)
						local pt = ptC:GetParticle(ptIdx)
						local radius = pt:GetRadius()
						-- TODO: Take length into account, as well as the particle shader?
						local alpha = pt:GetAlpha()
						local col = pt:GetColor() *bloomCol
						col = Color(col *Vector4(avgIntensity,1.0))
						col.a = 255
						
						local pos = pt:GetPosition()
						local light = scene:AddLightSource(cycles.LightSource.TYPE_POINT,pos)
						light:SetColor(col)
						local intensity = intensityFactor *math.pow(10.0 *(alpha ^2.0) *radius,1.0 /1.5) -- Decline growth for larger factors
						-- print("Light: ",intensity,alpha,radius,intensityFactor)
						light:SetIntensity(intensity) -- TODO: This may require some tweaking
					end
				end
			end
		end
	end
	
	local ang = rot:ToEulerAngles()
	pfm.log("Starting render job for frame " .. (self.m_currentFrame +1) .. " with camera position (" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ") and angles (" .. ang.p .. "," .. ang.y .. "," .. ang.r .. ").",pfm.LOG_CATEGORY_PFM_RENDER)

	if(renderSettings:IsPreStageOnly()) then
		self.m_preStage = scene
		self.m_lastProgress = 0.0
		return
	end
	self.m_preStage = nil

	local job = scene:CreateRenderJob()
	job:Start()
	self.m_rtScene = scene

	self.m_raytracingJob = job
	self.m_progressiveRendering = createInfo.progressive
	if(self.m_progressiveRendering) then
		self.m_prt = scene:CreateProgressiveImageHandler()
	end

	self.m_lastProgress = 0.0
	self:CallCallbacks("OnFrameStart")
end
function pfm.RaytracingRenderJob:RenderNextImage()
	if(self.m_remainingSubStages == 0) then
		self.m_currentFrame = self.m_currentFrame +1
		self.m_remainingSubStages = self:GetSettings():IsCubemapPanorama() and 6 or 1
	end
	self.m_remainingSubStages = self.m_remainingSubStages -1
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
	self.m_projectManager:GoToFrame(self.m_currentFrame)
	-- We want to wait for a bit before rendering, to make sure
	-- everything for this frame has been set up properly.
	-- If the scene contains particle systems, the frame must not be
	-- changed until rendering has been completed!
	self.m_tRenderStart = time.cur_time() +0.2
	return false
end
function pfm.RaytracingRenderJob:IsRendering() return (self.m_raytracingJob ~= nil and self.m_raytracingJob:IsComplete() == false) end
function pfm.RaytracingRenderJob:GetRenderScene() return self.m_rtScene end
function pfm.RaytracingRenderJob:RestartRendering()
	if(self:IsRendering() == false) then return end
	self.m_rtScene:Restart()
end
function pfm.RaytracingRenderJob:CancelRendering()
	self.m_prt = nil
	self.m_tRenderStart = nil
	if(self:IsRendering() == false) then return end
	self.m_raytracingJob:Cancel()
end
function pfm.RaytracingRenderJob:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress() return self.m_lastProgress end

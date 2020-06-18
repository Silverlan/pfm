--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/class_property.lua")

pfm = pfm or {}

util.register_class("pfm.RaytracingRenderJob")

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

util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderMode")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"samples",80.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"sky","")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"skyStrength",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"emissionStrength",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"skyYaw",0.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"maxTransparencyBounces",128)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"lightIntensityFactor",1.0)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"frameCount",1)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"denoise",true)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"hdrOutput",false,{
	getter = "GetHDROutput",
	setter = "SetHDROutput"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"deviceType","gpu")
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderWorld",true)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderGameEntities",true)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderPlayer",false)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"camType",pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"panoramaType",pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"renderPreview",false,{
	getter = "IsRenderPreview"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"width",512)
util.register_class_property(pfm.RaytracingRenderJob.Settings,"height",512)

util.register_class_property(pfm.RaytracingRenderJob.Settings,"cameraFrustumCullingEnabled",true,{
	getter = "IsCameraFrustumCullingEnabled"
})
util.register_class_property(pfm.RaytracingRenderJob.Settings,"pvsCullingEnabled",true,{
	setter = "SetPVSCullingEnabled",
	getter = "IsPVSCullingEnabled"
})

function pfm.RaytracingRenderJob.Settings:__init()
	self:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
end
function pfm.RaytracingRenderJob.Settings:IsCubemapPanorama()
	return self:GetCamType() == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA and self:GetPanoramaType() == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP
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
	cpy:SetDenoise(self:GetDenoise())
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
	return cpy
end

pfm.RaytracingRenderJob.STATE_IDLE = 0
pfm.RaytracingRenderJob.STATE_RENDERING = 1
pfm.RaytracingRenderJob.STATE_FAILED = 2
pfm.RaytracingRenderJob.STATE_COMPLETE = 3
pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE = 4
function pfm.RaytracingRenderJob:__init(settings)
	self.m_settings = (settings and settings:Copy()) or pfm.RaytracingRenderJob.Settings()
	self.m_currentFrame = -1
	self.m_gameScene = game.get_scene()
end
function pfm.RaytracingRenderJob:SetGameScene(scene) self.m_gameScene = scene end
function pfm.RaytracingRenderJob:GetGameScene() return self.m_gameScene end
function pfm.RaytracingRenderJob:GetSettings() return self.m_settings end

function pfm.RaytracingRenderJob:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress()
	if(self.m_raytracingJob == nil) then return 1.0 end
	return self.m_raytracingJob:GetProgress()
end
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
	self.m_renderResultFrameIndex = self.m_currentFrame
	self.m_renderResultRemainingSubStages = self.m_remainingSubStages

	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	self.m_renderResult = prosper.create_texture(img,prosper.TextureCreateInfo(),imgViewCreateInfo,samplerCreateInfo)
end
function pfm.RaytracingRenderJob:Update()
	if(self.m_raytracingJob == nil) then return pfm.RaytracingRenderJob.STATE_IDLE end
	local progress = self.m_raytracingJob:GetProgress()
	self.m_lastProgress = progress
	if(self:IsComplete() == false) then return pfm.RaytracingRenderJob.STATE_RENDERING end
	local successful = self.m_raytracingJob:IsSuccessful()
	local isFrameComplete = (self.m_remainingSubStages == 0) -- No sub-stages remaining
	if(successful) then
		local imgBuffer = self.m_raytracingJob:GetResult()
		table.insert(self.m_imageBuffers,imgBuffer)

		if(isFrameComplete) then self:GenerateResult() end
	end
	self.m_raytracingJob = nil

	if(successful) then
		local complete = self:RenderNextImage()
		if(complete) then return pfm.RaytracingRenderJob.STATE_COMPLETE end
		return isFrameComplete and pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE or pfm.RaytracingRenderJob.STATE_RENDERING
	end
	return pfm.RaytracingRenderJob.STATE_FAILED
end
function pfm.RaytracingRenderJob:Start()
	self.m_remainingSubStages = 0
	self.m_imageBuffers = {}
	self:RenderNextImage()
end
function pfm.RaytracingRenderJob:RenderNextImage()
	if(self.m_remainingSubStages == 0) then
		self.m_currentFrame = self.m_currentFrame +1
		self.m_remainingSubStages = self:GetSettings():IsCubemapPanorama() and 6 or 1
	end
	self.m_remainingSubStages = self.m_remainingSubStages -1
	local subStageIdx = self.m_remainingSubStages

	local renderSettings = self.m_settings
	if(self.m_currentFrame == renderSettings:GetFrameCount()) then
		local msg
		if(renderSettings:IsRenderPreview()) then msg = "Preview rendering complete!"
		else msg = "Rendering complete! " .. renderSettings:GetFrameCount() .. " frames have been rendered!" end
		pfm.log(msg,pfm.LOG_CATEGORY_PFM_INTERFACE)
		return true
	end

	local cam = self.m_gameScene:GetActiveCamera()
	if(cam == nil) then return end

	local createInfo = cycles.Scene.CreateInfo()
	createInfo.denoise = renderSettings:GetDenoise()
	createInfo.hdrOutput = renderSettings:GetHDROutput()
	createInfo.deviceType = renderSettings:GetDeviceType()
	createInfo:SetSamplesPerPixel(renderSettings:GetSamples())

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
		clCam:SetFocalDistance(camData:GetFocalDistance())
		clCam:SetBokehRatio(camData:GetApertureBokehRatio())
		clCam:SetBladeCount(camData:GetApertureBladeCount())
		clCam:SetBladesRotation(camData:GetApertureBladesRotation())
		clCam:SetDepthOfFieldEnabled(camData:IsDepthOfFieldEnabled())
		clCam:SetApertureSizeFromFStop(camData:GetFStop(),math.calc_focal_length_from_fov(fov,camData:GetSensorSize()))
	else clCam:SetDepthOfFieldEnabled(false) end

	scene:InitializeFromGameScene(self.m_gameScene,pos,rot,vp,nearZ,farZ,fov,sceneFlags,function(ent)
		if(ent:IsWorld()) then return renderSettings:GetRenderWorld() end
		if(ent:IsPlayer()) then return renderSettings:GetRenderPlayer() end
		if(ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM) == true) then return false end -- TODO
		return renderSettings:GetRenderGameEntities() or ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
	end,function(ent)
		return true
	end)
	if(#renderSettings:GetSky() > 0) then scene:SetSky(renderSettings:GetSky()) end
	
	pfm.log("Starting render job for frame " .. self.m_currentFrame .. "...",pfm.LOG_CATEGORY_PFM_INTERFACE)

	local job = scene:CreateRenderJob()
	job:Start()

	self.m_raytracingJob = job

	self.m_lastProgress = 0.0

	-- Move to next frame in case we're rendering an image sequence
	if(self.m_currentFrame < (renderSettings:GetFrameCount() -1)) then
		local filmmaker = tool.get_filmmaker()
		if(util.is_valid(filmmaker)) then filmmaker:GoToNextFrame() end
	end
	return false
end
function pfm.RaytracingRenderJob:IsRendering() return (self.m_raytracingJob ~= nil and self.m_raytracingJob:IsComplete() == false) end
function pfm.RaytracingRenderJob:CancelRendering()
	if(self:IsRendering() == false) then return end
	self.m_raytracingJob:Cancel()
end
function pfm.RaytracingRenderJob:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function pfm.RaytracingRenderJob:GetProgress() return self.m_lastProgress end

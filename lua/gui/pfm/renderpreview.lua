--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/aspectratio.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/gui/pfm/slider.lua")
include("/gui/pfm/button.lua")
include("/gui/editableentry.lua")
include("/gui/wifiledialog.lua")
include("/gui/toggleoption.lua")
include("/gui/raytracedviewport.lua")

util.register_class("gui.PFMRenderPreview",gui.Base)

function gui.PFMRenderPreview:__init()
	gui.Base.__init(self)
end
function gui.PFMRenderPreview:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128,hViewport +hBottom)

	self.m_contents = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	self.vpContents = gui.create("WIHBox",self.m_contents,0,0,self:GetWidth(),hViewport,0,0,1,1)
	self.vpContents:SetAutoFillContents(true)

	self.m_rt = gui.create("WIRaytracedViewport",self.vpContents)
	self.m_rt:AddCallback("OnProgressChanged",function(rt,progress)
		self:CallCallbacks("OnProgressChanged",progress)
	end)
	self.m_rt:AddCallback("OnFrameComplete",function(rt,state,job)
		if(util.is_valid(self.m_preview) == false) then return end
		local tex = job:GetRenderResultTexture()
		if(tex ~= nil) then self.m_preview:SetTexture(tex) end
	end)
	self.m_rt:AddCallback("OnComplete",function(rt,state)
		if(util.is_valid(self.m_btRefreshPreview)) then self.m_btRefreshPreview:SetEnabled(true) end
		if(util.is_valid(self.m_btRefresh)) then self.m_btRefresh:SetText(locale.get_text("pfm_render_image")) end
	end)
	self.m_aspectRatioWrapper = gui.create("WIAspectRatio",self.m_rt,0,0,self.m_rt:GetWidth(),self.m_rt:GetHeight(),0,0,1,1)

	gui.create("WIResizer",self.vpContents)

	self:InitializeSettings(self.vpContents)

	self.m_preview = gui.create("WITexturedRect",self.m_aspectRatioWrapper)

	self:InitializeControls()
end
function gui.PFMRenderPreview:InitializeSettings(parent)
	local p = gui.create("WIVBox",parent)
	p:SetAutoFillContentsToWidth(true)
	
	-- Render Mode
	local renderMode = gui.create("WIDropDownMenu",p)
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_combined"),"combined")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_albedo"),"albedo")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_normals"),"normals")
	renderMode:SelectOption(0)
	-- renderMode:SetTooltip(locale.get_text("pfm_cycles_bake_type_desc"))
	self.m_ctrlRenderMode = renderMode

	renderMode:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_render_mode"))

	-- Device Type
	local deviceType = gui.create("WIDropDownMenu",p)
	deviceType:AddOption(locale.get_text("pfm_cycles_device_type_gpu"),"gpu")
	deviceType:AddOption(locale.get_text("pfm_cycles_device_type_cpu"),"cpu")
	deviceType:SelectOption(1)
	-- deviceType:SetTooltip(locale.get_text("pfm_cycles_device_type_desc"))
	self.m_ctrlDeviceType = deviceType

	deviceType:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_cycles_device_type"))

	-- Camera type
	local panoramaTypeWrapper
	local camType = gui.create("WIDropDownMenu",p)
	camType:AddOption(locale.get_text("pfm_cycles_cam_type_perspective"),tostring(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE))
	camType:AddOption(locale.get_text("pfm_cycles_cam_type_orthographic"),tostring(pfm.RaytracingRenderJob.Settings.CAM_TYPE_ORTHOGRAPHIC))
	camType:AddOption(locale.get_text("pfm_cycles_cam_type_panorama"),tostring(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA))
	camType:SelectOption(0)
	camType:AddCallback("OnOptionSelected",function(camType,idx)
		panoramaTypeWrapper:SetVisible(idx == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA)
	end)
	self.m_ctrlCamType = camType

	camType:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_cycles_cam_type"))

	local panoramaType = gui.create("WIDropDownMenu",p)
	panoramaType:AddOption(locale.get_text("pfm_cycles_cam_panorama_type_equirectangular"),tostring(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR))
	panoramaType:AddOption(locale.get_text("pfm_cycles_cam_panorama_type_equidistant"),tostring(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT))
	panoramaType:AddOption(locale.get_text("pfm_cycles_cam_panorama_type_equisolid"),tostring(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID))
	panoramaType:AddOption(locale.get_text("pfm_cycles_cam_panorama_type_mirrorball"),tostring(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_MIRRORBALL))
	panoramaType:AddOption(locale.get_text("pfm_cycles_cam_panorama_type_cubemap"),tostring(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_CUBEMAP))
	panoramaType:SelectOption(0)
	-- panoramaType:SetTooltip(locale.get_text("pfm_cycles_image_type_desc"))
	self.m_ctrlPanoramaType = panoramaType

	panoramaTypeWrapper = panoramaType:Wrap("WIEditableEntry")
	panoramaTypeWrapper:SetText(locale.get_text("pfm_cycles_cam_panorama"))
	panoramaTypeWrapper:SetVisible(false)

	-- Quality preset
	local presets = {
		{
			name = "very_low",
			emission_strength = 0.0,
			samples = 20.0,
			max_transparency_bounces = 1
		},
		{
			name = "low",
			emission_strength = 0.0,
			samples = 40.0,
			max_transparency_bounces = 4
		},
		{
			name = "medium",
			emission_strength = 0.0,
			samples = 80.0,
			max_transparency_bounces = 8
		},
		{
			name = "high",
			emission_strength = 1.0,
			samples = 120.0,
			max_transparency_bounces = 64
		},
		{
			name = "very_high",
			emission_strength = 1.0,
			samples = 200.0,
			max_transparency_bounces = 128
		}
	}
	local qualityPreset = gui.create("WIDropDownMenu",p)
	for _,preset in ipairs(presets) do
		qualityPreset:AddOption(locale.get_text("pfm_cycles_quality_preset_" .. preset.name),preset.name)
	end
	-- qualityPreset:SetTooltip(locale.get_text("pfm_cycles_quality_preset_desc"))
	qualityPreset:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_cycles_quality_preset"))

	-- Sample count
	local samplesPerPixel = gui.create("WIPFMSlider",p)
	samplesPerPixel:SetText(locale.get_text("pfm_samples_per_pixel"))
	samplesPerPixel:SetInteger(true)
	samplesPerPixel:SetRange(1,500)
	samplesPerPixel:SetDefault(40)
	samplesPerPixel:SetTooltip(locale.get_text("pfm_samples_per_pixel_desc"))
	samplesPerPixel:SetStepSize(1.0)
	self.m_ctrlSamplesPerPixel = samplesPerPixel

	-- Resolution
	local resolution = engine.get_render_resolution()

	local resolution = gui.create("WIDropDownMenu",p)
	resolution:SetEditable(true)
	resolution:AddOption(locale.get_text("pfm_resolution_hd_ready"),"1280x720")
	resolution:AddOption(locale.get_text("pfm_resolution_full_hd"),"1920x1080")
	resolution:AddOption(locale.get_text("pfm_resolution_quad_hd"),"2560x1440")
	resolution:AddOption(locale.get_text("pfm_resolution_2k"),"2048×1080")
	resolution:AddOption(locale.get_text("pfm_resolution_4k"),"3840x2160")
	resolution:AddOption(locale.get_text("pfm_resolution_8k"),"7680x4320")
	resolution:SelectOption(1)
	resolution:SetTooltip(locale.get_text("pfm_resolution_desc"))
	self.m_ctrlResolution = resolution
	resolution:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_resolution"))

	-- Sky override
	local skyOverride = gui.create("WIFileEntry",p)
	skyOverride:SetBrowseHandler(function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(el:GetFilePath(true))
		end)
		pFileDialog:SetRootPath("materials")
		local path = file.get_file_path(skyOverride:GetValue())
		if(#path == 0) then path = "skies" end
		pFileDialog:SetPath(path)
		pFileDialog:SetExtensions({"hdr"})
		pFileDialog:Update()
	end)
	skyOverride:SetTooltip(locale.get_text("pfm_sky_override_desc"))

	-- Choose a default sky
	local skies = file.find("materials/skies/*.hdr")
	if(#skies > 0) then skyOverride:SetValue("skies/" .. skies[1]) end
	self.m_ctrlSkyOverride = skyOverride

	skyOverride:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_sky_override"))

	-- Sky strength
	local skyStrength = gui.create("WIPFMSlider",p)
	skyStrength:SetText(locale.get_text("pfm_sky_strength"))
	skyStrength:SetRange(0,100)
	skyStrength:SetDefault(30)
	skyStrength:SetTooltip(locale.get_text("pfm_sky_strength_desc"))
	self.m_ctrlSkyStrength = skyStrength

	-- Sky yaw
	local skyYaw = gui.create("WIPFMSlider",p)
	skyYaw:SetText(locale.get_text("pfm_sky_yaw_angle"))
	skyYaw:SetRange(0,360)
	skyYaw:SetDefault(0)
	skyYaw:SetTooltip(locale.get_text("pfm_sky_yaw_angle_desc"))
	self.m_ctrlSkyYaw = skyYaw

	-- Max transparency bounces
	local maxTransparencyBounces = gui.create("WIPFMSlider",p)
	maxTransparencyBounces:SetText(locale.get_text("pfm_max_transparency_bounces"))
	maxTransparencyBounces:SetRange(0,200)
	maxTransparencyBounces:SetDefault(128)
	maxTransparencyBounces:SetTooltip(locale.get_text("pfm_max_transparency_bounces_desc"))
	self.m_ctrlMaxTransparencyBounces = maxTransparencyBounces

	-- Light intensity factor
	local lightIntensityFactor = gui.create("WIPFMSlider",p)
	lightIntensityFactor:SetText(locale.get_text("pfm_light_intensity_factor"))
	lightIntensityFactor:SetRange(0,20)
	lightIntensityFactor:SetDefault(1.0)
	lightIntensityFactor:SetTooltip(locale.get_text("pfm_light_intensity_factor_desc"))
	self.m_ctrlLightIntensityFactor = lightIntensityFactor

	-- Emission strength
	local emissionStrength = gui.create("WIPFMSlider",p)
	emissionStrength:SetText(locale.get_text("pfm_emission_strength"))
	emissionStrength:SetRange(0,20)
	emissionStrength:SetDefault(1.0)
	emissionStrength:SetTooltip(locale.get_text("pfm_emission_strength_desc"))
	self.m_ctrlEmissionStrength = emissionStrength

	-- Number of frames
	local frameCount = gui.create("WIPFMSlider",p)
	frameCount:SetText(locale.get_text("pfm_number_of_frames_to_render"))
	frameCount:SetInteger(true)
	frameCount:SetRange(1,100)
	frameCount:SetDefault(1)
	frameCount:SetTooltip(locale.get_text("pfm_number_of_frames_to_render_desc"))
	frameCount:SetStepSize(1.0)
	self.m_ctrlFrameCount = frameCount

	-- Output directory
	local outputDir = gui.create("WIFileEntry",p)
	outputDir:SetBrowseHandler(function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(fileName)
		end)
		pFileDialog:MakeDirectoryExplorer()
		pFileDialog:SetRootPath(util.get_addon_path())
		pFileDialog:SetPath(outputDir:GetValue())
		pFileDialog:Update()
	end)
	outputDir:SetValue("render/")
	outputDir:SetTooltip(locale.get_text("pfm_output_directory_desc"))
	self.m_ctrlOutputDir = outputDir

	outputDir:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_output_directory"))

	local denoise = gui.create("WIToggleOption",p)
	denoise:SetText(locale.get_text("pfm_denoise_image"))
	denoise:SetChecked(true)
	denoise:SetTooltip(locale.get_text("pfm_denoise_image_desc"))
	self.m_ctrlDenoise = denoise

	local renderWorld = gui.create("WIToggleOption",p)
	renderWorld:SetText(locale.get_text("pfm_render_world"))
	renderWorld:SetChecked(true)
	renderWorld:SetTooltip(locale.get_text("pfm_render_world_desc"))
	self.m_ctrlRenderWorld = renderWorld

	local renderGameEntities = gui.create("WIToggleOption",p)
	renderGameEntities:SetText(locale.get_text("pfm_render_game_objects"))
	renderGameEntities:SetChecked(true)
	renderGameEntities:SetTooltip(locale.get_text("pfm_render_game_objects_desc"))
	self.m_ctrlRenderGameEntities = renderGameEntities

	local renderPlayer = gui.create("WIToggleOption",p)
	renderPlayer:SetText(locale.get_text("pfm_render_player"))
	renderPlayer:SetChecked(false)
	renderPlayer:SetTooltip(locale.get_text("pfm_render_player_desc"))
	self.m_ctrlRenderPlayer = renderPlayer

	-- Presets
	qualityPreset:AddCallback("OnOptionSelected",function(el,option)
		local preset = presets[option +1]
		if(preset == nil) then return end
		if(preset.samples ~= nil) then samplesPerPixel:SetValue(preset.samples) end
		if(preset.max_transparency_bounces ~= nil) then maxTransparencyBounces:SetValue(preset.max_transparency_bounces) end
		if(preset.emission_strength ~= nil) then emissionStrength:SetValue(preset.emission_strength) end
	end)
	qualityPreset:SelectOption(2)
end
function gui.PFMRenderPreview:InitializeControls()
	local controls = gui.create("WIHBox",self.m_contents)
	controls:SetHeight(self:GetHeight() -self.m_rt:GetBottom())

	self.m_btRefreshPreview = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		self:Refresh(true)
	end)
	self.m_btRefreshPreview:SetText(locale.get_text("pfm_render_preview"))
	self.m_btRefreshPreview:SetTooltip(locale.get_text("pfm_refresh_preview"))

	gui.create("WIBase",controls,0,0,5,1) -- Gap

	self.m_btRefresh = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		if(self.m_rt:IsRendering()) then
			self.m_rt:CancelRendering()
			return
		end
		self:Refresh()
	end)
	self.m_btRefresh:SetText(locale.get_text("pfm_render_image"))
	self.m_btRefresh:SetTooltip(locale.get_text("pfm_render_frame"))

	gui.create("WIBase",controls,0,0,5,1) -- Gap

	self.m_btOpenOutputDir = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		local path = self.m_ctrlOutputDir:GetValue()
		if(#path == 0) then return end
		util.open_path_in_explorer(util.get_addon_path() .. path)
	end)
	self.m_btOpenOutputDir:SetText(locale.get_text("pfm_open_output_dir"))

	controls:SetHeight(self.m_btRefreshPreview:GetHeight())
	controls:Update()
	controls:SetAnchor(0,1,0,1)
end
function gui.PFMRenderPreview:Refresh(preview)
	if(util.is_valid(self.m_btRefreshPreview)) then self.m_btRefreshPreview:SetEnabled(false) end
	if(util.is_valid(self.m_btRefresh)) then
		self.m_btRefresh:SetText(locale.get_text("pfm_cancel_rendering"))
	end

	local settings = self.m_rt:GetRenderSettings()
	local renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED

	local selectedRenderMode = self.m_ctrlRenderMode:GetValue()
	if(selectedRenderMode == "combined") then renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED
	elseif(selectedRenderMode == "albedo") then renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_ALBEDO
	elseif(selectedRenderMode == "normals") then renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_NORMALS end

	local deviceType = pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU
	local selectedDeviceType = self.m_ctrlDeviceType:GetValue()
	if(selectedDeviceType == "cpu") then deviceType = pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU
	elseif(selectedDeviceType == "gpu") then deviceType = pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU end

	preview = preview or false
	local samples = preview and 4 or nil

	local width = 512
	local height = 512
	if(preview == false) then
		local selectedOption = self.m_ctrlResolution:GetSelectedOption()
		local resolution
		if(selectedOption ~= -1) then resolution = self.m_ctrlResolution:GetOptionValue(selectedOption)
		else resolution = self.m_ctrlResolution:GetValue() end
		resolution = string.split(resolution,"x")
		if(resolution[1] ~= nil) then width = tonumber(resolution[1]) or 0 end
		if(resolution[2] ~= nil) then height = tonumber(resolution[2]) or 0 end
	end

	width = math.max(width,2)
	height = math.max(height,2)
	-- Resolution has to be dividable by 2
	if((width %2) ~= 0) then width = width +1 end
	if((height %2) ~= 0) then height = height +1 end

	settings:SetRenderMode(renderMode)
	settings:SetSamples(samples or self.m_ctrlSamplesPerPixel:GetValue())
	settings:SetSky(self.m_ctrlSkyOverride:GetValue())
	settings:SetSkyStrength(self.m_ctrlSkyStrength:GetValue())
	settings:SetEmissionStrength(self.m_ctrlEmissionStrength:GetValue())
	settings:SetSkyYaw(self.m_ctrlSkyYaw:GetValue())
	settings:SetMaxTransparencyBounces(self.m_ctrlMaxTransparencyBounces:GetValue())
	settings:SetLightIntensityFactor(self.m_ctrlLightIntensityFactor:GetValue())
	settings:SetFrameCount(preview and 1 or self.m_ctrlFrameCount:GetValue())
	settings:SetOutputDir(self.m_ctrlOutputDir:GetValue())
	settings:SetDenoise(self.m_ctrlDenoise:IsChecked())
	settings:SetDeviceType(deviceType)
	settings:SetRenderWorld(self.m_ctrlRenderWorld:IsChecked())
	settings:SetRenderGameEntities(self.m_ctrlRenderGameEntities:IsChecked())
	settings:SetRenderPlayer(self.m_ctrlRenderPlayer:IsChecked())
	settings:SetCamType(tonumber(self.m_ctrlCamType:GetValue()))
	settings:SetPanoramaType(tonumber(self.m_ctrlPanoramaType:GetValue()))
	settings:SetWidth(width)
	settings:SetHeight(height)

	local filmmaker = tool.get_filmmaker()
	local camC = filmmaker:GetActiveCamera()
	if(util.is_valid(camC)) then
		local pfmCamC = camC:GetEntity():GetComponent("pfm_camera")
		local camData = pfmCamC and pfmCamC:GetCameraData() or nil
		if(camData ~= nil) then
			settings:SetFocalDistance(camData:GetFocalDistance())
			settings:SetFStop(camData:GetFStop())
			settings:SetApertureBokehRatio(camData:GetApertureBokehRatio())
			settings:SetApertureBladeCount(camData:GetApertureBladeCount())
			settings:SetApertureBladesRotation(camData:GetApertureBladesRotation())
			settings:SetDepthOfFieldEnabled(camData:IsDepthOfFieldEnabled())
		end
	end

	self.m_rt:Refresh(preview)
end
gui.register("WIPFMRenderPreview",gui.PFMRenderPreview)

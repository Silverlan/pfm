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
include("/gui/pfm/raytracedanimationviewport.lua")
include("/shaders/pfm/pfm_tonemapping.lua")

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

	self.m_vpContents = gui.create("WIHBox",self.m_contents,0,0,self:GetWidth(),hViewport,0,0,1,1)
	self.m_vpContents:SetAutoFillContents(true)

	self.m_rtBox = gui.create("WIRect",self.m_vpContents,0,0,128,128)
	self.m_rtBox:SetColor(Color.Black)
	self.m_aspectRatioWrapper = gui.create("WIAspectRatio",self.m_rtBox,0,0,self.m_rtBox:GetWidth(),self.m_rtBox:GetHeight(),0,0,1,1)

	gui.create("WIResizer",self.m_vpContents)

	self.m_rt = gui.create("WIPFMRaytracedAnimationViewport",self.m_aspectRatioWrapper)
	self.m_rt:AddCallback("OnProgressChanged",function(rt,progress)
		self:CallCallbacks("OnProgressChanged",progress)
	end)
	self.m_rt:AddCallback("OnFrameComplete",function(rt,state,job)
		-- Save the image if it's not a preview render
		local renderSettings = self.m_rt:GetRenderSettings()
		if(renderSettings:IsRenderPreview() == false) then
			local outputPath = "render/" .. self:GetCurrentFrameFilePath()
			local rtJob = self.m_rt:GetRTJob()
			local remainingSubStages = rtJob:GetRenderResultRemainingSubStages()
			if(remainingSubStages > 0) then outputPath = outputPath .. "_" .. remainingSubStages end

			file.create_path(util.Path(outputPath):GetPath())
			print("Saving image as " .. outputPath .. "...")
			self.m_rt:SaveImage(outputPath)
		end

		local luminance = rt:GetLuminance()
		local Lmax = luminance:GetMaxLuminance()
		local Lav = luminance:GetAvgLuminance()
		local Llav = luminance:GetAvgLuminance()
		local Lmin = luminance:GetMinLuminance()
		local k = (math.log(Lmax) -math.log(Llav)) /(math.log(Lmax) -math.log(Lmin))
		local m = 0.3 +0.7 *math.pow(k,1.4)

		self.m_ctrlCompressionCurveParam:SetDefault(m)
		self.m_ctrlCompressionCurveParam:SetValue(m)
	end)
	self.m_rt:AddCallback("OnComplete",function(rt,state)
		if(util.is_valid(self.m_btRefreshPreview)) then self.m_btRefreshPreview:SetEnabled(true) end
		if(util.is_valid(self.m_btRefresh)) then self.m_btRefresh:SetText(locale.get_text("pfm_render_image")) end
	end)

	self.m_cbOnTimeOffsetChanged = tool.get_filmmaker():AddCallback("OnTimeOffsetChanged",function(fm,offset)
		local imgFilePath = self:GetCurrentFrameFilePath()
		if(imgFilePath == nil) then return end
		self.m_rt:LoadPreviewImage("render/" .. imgFilePath)
	end)

	self:InitializeSettings(self.m_vpContents)
	self:InitializeControls()
end
function gui.PFMRenderPreview:OnRemove()
	if(util.is_valid(self.m_cbOnTimeOffsetChanged)) then self.m_cbOnTimeOffsetChanged:Remove() end
end
function gui.PFMRenderPreview:InitializeSettings(parent)
	local p = gui.create("WIVBox",parent)
	p:SetAutoFillContentsToWidth(true)
	self.m_settingsBox = p
	
	-- Render Mode
	local renderMode = gui.create("WIDropDownMenu",p)
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_combined"),"combined")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_albedo"),"albedo")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_normals"),"normals")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_depth"),"depth")
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
	resolution:AddOption(locale.get_text("pfm_resolution_2k"),"2048x1080")
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

	-- Tonemapping
	self:InitializeToneMapControls(p)

	-- Output directory
	--[[local outputDir = gui.create("WIFileEntry",p)
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

	outputDir:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_output_directory"))]]

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

	local frustumCulling = gui.create("WIToggleOption",p)
	frustumCulling:SetText(locale.get_text("pfm_render_frustum_culling"))
	frustumCulling:SetChecked(true)
	frustumCulling:SetTooltip(locale.get_text("pfm_render_frustum_culling_desc"))
	self.m_ctrlFrustumCulling = frustumCulling

	local pvsCulling = gui.create("WIToggleOption",p)
	pvsCulling:SetText(locale.get_text("pfm_render_pvs_culling"))
	pvsCulling:SetChecked(true)
	pvsCulling:SetTooltip(locale.get_text("pfm_render_pvs_culling_desc"))
	self.m_ctrlPVSCulling = pvsCulling

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
function gui.PFMRenderPreview:AddSliderControl(name,default,min,max,onChange)
	local slider = gui.create("WIPFMSlider",self.m_settingsBox)
	slider:SetText(locale.get_text(name))
	slider:SetRange(min,max)
	slider:SetDefault(default)
	slider:SetTooltip(locale.get_text(name .. "_desc"))
	if(onChange ~= nil) then
		slider:AddCallback("OnLeftValueChanged",onChange)
	end
	return slider
end
function gui.PFMRenderPreview:InitializeToneMapControls(p)
	local toneMapping = gui.create("WIDropDownMenu",p)
	-- toneMapping:AddOption(locale.get_text("pfm_cycles_tone_mapping_none_hdr"),"-1")
	toneMapping:AddOption(locale.get_text("gamma_correction"),tostring(shader.TONE_MAPPING_GAMMA_CORRECTION))
	toneMapping:AddOption("Reinhard",tostring(shader.TONE_MAPPING_REINHARD))
	toneMapping:AddOption("Hejil-Richard",tostring(shader.TONE_MAPPING_HEJIL_RICHARD))
	toneMapping:AddOption("Uncharted",tostring(shader.TONE_MAPPING_UNCHARTED))
	toneMapping:AddOption("Aces",tostring(shader.TONE_MAPPING_ACES))
	toneMapping:AddOption("Gran Turismo",tostring(shader.TONE_MAPPING_GRAN_TURISMO))

	toneMapping:AddOption("Ward",tostring(shader.PFMTonemapping.TONE_MAPPING_WARD))
	toneMapping:AddOption("Ferwerda",tostring(shader.PFMTonemapping.TONE_MAPPING_FERWERDA))
	toneMapping:AddOption("Schlick",tostring(shader.PFMTonemapping.TONE_MAPPING_SCHLICK))
	toneMapping:AddOption("Tumblin-Rushmeier",tostring(shader.PFMTonemapping.TONE_MAPPING_TUMBLIN_RUSHMEIER))
	toneMapping:AddOption("Drago",tostring(shader.PFMTonemapping.TONE_MAPPING_DRAGO))
	toneMapping:AddOption("Reinhard-Devlin",tostring(shader.PFMTonemapping.TONE_MAPPING_REINHARD_DEVLIN))
	toneMapping:AddOption("Filmic 1",tostring(shader.PFMTonemapping.TONE_MAPPING_FILMLIC1))
	toneMapping:AddOption("Filmic 2",tostring(shader.PFMTonemapping.TONE_MAPPING_FILMLIC2))
	toneMapping:AddOption("Insomniac",tostring(shader.PFMTonemapping.TONE_MAPPING_INSOMNIAC))

	toneMapping:SetTooltip(locale.get_text("pfm_cycles_tone_mapping_desc"))
	toneMapping:AddCallback("OnOptionSelected",function(el,option)
		self.m_ctrlExposure:SetVisible(false)
		self.m_ctrlLdMax:SetVisible(false)
		self.m_ctrlCMax:SetVisible(false)
		self.m_ctrlCurveParam:SetVisible(false)
		self.m_ctrlGammaSlope:SetVisible(false)
		self.m_ctrlGammaStart:SetVisible(false)
		self.m_ctrlBias:SetVisible(false)
		self.m_ctrlCompressionCurveParam:SetVisible(false)
		self.m_ctrlIntensityAdjustmentParam:SetVisible(false)
		self.m_ctrlChromaticAdapation:SetVisible(false)
		self.m_ctrlLightAdaptation:SetVisible(false)
		self.m_ctrlCutoff:SetVisible(false)
		self.m_ctrlWhitePoint:SetVisible(false)
		self.m_ctrlBlackPoint:SetVisible(false)
		self.m_ctrlToeStrength:SetVisible(false)
		self.m_ctrlShoulderStrength:SetVisible(false)
		self.m_ctrlCrossOverPoint:SetVisible(false)

		option = tonumber(toneMapping:GetOptionValue(option))
		self:ApplyToneMappingSettings(option)
		self.m_rt:SetToneMapping(option)
		if(option == -1) then return end

		self.m_ctrlExposure:SetVisible(true)
		if(option == shader.PFMTonemapping.TONE_MAPPING_WARD) then
			self.m_ctrlLdMax:SetVisible(true)

			self.m_ctrlLdMax:SetRange(0,200)
			self.m_ctrlLdMax:SetDefault(100)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_FERWERDA) then
			self.m_ctrlLdMax:SetVisible(true)

			self.m_ctrlLdMax:SetRange(0,160)
			self.m_ctrlLdMax:SetDefault(80)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_SCHLICK) then
			self.m_ctrlCurveParam:SetVisible(true)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_TUMBLIN_RUSHMEIER) then
			self.m_ctrlLdMax:SetVisible(true)
			self.m_ctrlCMax:SetVisible(true)

			self.m_ctrlLdMax:SetRange(1,200)
			self.m_ctrlLdMax:SetDefault(86)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_DRAGO) then
			self.m_ctrlLdMax:SetVisible(true)

			self.m_ctrlLdMax:SetRange(0,200)
			self.m_ctrlLdMax:SetDefault(100)

			self.m_ctrlGammaSlope:SetVisible(true)
			self.m_ctrlGammaStart:SetVisible(true)
			self.m_ctrlBias:SetVisible(true)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_REINHARD_DEVLIN) then
			self.m_ctrlCompressionCurveParam:SetVisible(true)
			self.m_ctrlIntensityAdjustmentParam:SetVisible(true)
			self.m_ctrlChromaticAdapation:SetVisible(true)
			self.m_ctrlLightAdaptation:SetVisible(true)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_FILMLIC1) then
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_FILMLIC2) then
			self.m_ctrlCutoff:SetVisible(true)
		elseif(option == shader.PFMTonemapping.TONE_MAPPING_INSOMNIAC) then
			self.m_ctrlWhitePoint:SetVisible(true)
			self.m_ctrlBlackPoint:SetVisible(true)
			self.m_ctrlToeStrength:SetVisible(true)
			self.m_ctrlShoulderStrength:SetVisible(true)
			self.m_ctrlCrossOverPoint:SetVisible(true)
		end
	end)
	self.m_ctrlToneMapping = toneMapping
	toneMapping:Wrap("WIEditableEntry"):SetText(locale.get_text("tonemapping"))

	-- Exposure factor
	local fApplyToneMappingSettings = function() self:ApplyToneMappingSettings(self.m_rt:GetToneMapping()) end
	self.m_ctrlExposure = self:AddSliderControl("pfm_exposure",1.0,0,10,fApplyToneMappingSettings)

	-- Max luminance capability of the display
	self.m_ctrlLdMax = self:AddSliderControl("pfm_tone_mapping_ldmax",100,0,200,fApplyToneMappingSettings)

	-- Maximum contrast ratio between on-screen luminances
	self.m_ctrlCMax = self:AddSliderControl("pfm_tone_mapping_cmax",50,1,500,fApplyToneMappingSettings)

	-- Rational mapping curve parameter
	self.m_ctrlCurveParam = self:AddSliderControl("pfm_tone_mapping_curve_param",200,1,1000,fApplyToneMappingSettings)

	-- Gamma slope
	self.m_ctrlGammaSlope = self:AddSliderControl("pfm_tone_mapping_gamma_slope",4.5,0,10,fApplyToneMappingSettings)

	-- Gamma start
	self.m_ctrlGammaStart = self:AddSliderControl("pfm_tone_mapping_gamma_start",0.018,0,2,fApplyToneMappingSettings)

	-- Bias
	self.m_ctrlBias = self:AddSliderControl("pfm_tone_mapping_bias",0.85,0,1,fApplyToneMappingSettings)

	-- Compression curve adjustment parameter
	self.m_ctrlCompressionCurveParam = self:AddSliderControl("pfm_tone_mapping_compression_curve_adjustment_param",0.5,0,1,fApplyToneMappingSettings)

	-- Compression curve adjustment parameter
	self.m_ctrlIntensityAdjustmentParam = self:AddSliderControl("pfm_tone_mapping_intensity_adjustment_param_desc",1,0,1000,fApplyToneMappingSettings)

	-- Chromatic adaptation
	self.m_ctrlChromaticAdapation = self:AddSliderControl("pfm_tone_mapping_chromatic_adaptation",0,0,1,fApplyToneMappingSettings)

	-- Light adaptation
	self.m_ctrlLightAdaptation = self:AddSliderControl("pfm_tone_mapping_light_adaptation",1,0,1,fApplyToneMappingSettings)

	-- Cutoff
	self.m_ctrlCutoff = self:AddSliderControl("pfm_tone_mapping_cutoff",0.025,0,0.5,fApplyToneMappingSettings)

	-- White point
	self.m_ctrlWhitePoint = self:AddSliderControl("pfm_tone_mapping_white_point",10,0,20,fApplyToneMappingSettings)

	-- Black point
	self.m_ctrlBlackPoint = self:AddSliderControl("pfm_tone_mapping_black_point",0.1,0,2,fApplyToneMappingSettings)

	-- Toe strength
	self.m_ctrlToeStrength = self:AddSliderControl("pfm_tone_mapping_toe_strength",0.7,0,1,fApplyToneMappingSettings)

	-- Shoulder strength
	self.m_ctrlShoulderStrength = self:AddSliderControl("pfm_tone_mapping_shoulder_strength",0.8,0,1,fApplyToneMappingSettings)

	-- Cross-over point
	self.m_ctrlCrossOverPoint = self:AddSliderControl("pfm_tone_mapping_cross_over_point",2,0,10,fApplyToneMappingSettings)

	toneMapping:SelectOption(4)
end
function gui.PFMRenderPreview:ApplyToneMappingSettings(toneMapping)
	self.m_rt:SetExposure(self.m_ctrlExposure:GetValue())

	local args = {}
	if(toneMapping == shader.PFMTonemapping.TONE_MAPPING_WARD) then
		table.insert(args,self.m_ctrlLdMax:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_FERWERDA) then
		table.insert(args,self.m_ctrlLdMax:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_SCHLICK) then
		table.insert(args,self.m_ctrlCurveParam:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_TUMBLIN_RUSHMEIER) then
		table.insert(args,self.m_ctrlLdMax:GetValue())
		table.insert(args,self.m_ctrlCMax:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_DRAGO) then
		table.insert(args,self.m_ctrlLdMax:GetValue())
		table.insert(args,self.m_ctrlBias:GetValue())
		table.insert(args,self.m_ctrlGammaStart:GetValue())
		table.insert(args,self.m_ctrlGammaSlope:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_REINHARD_DEVLIN) then
		table.insert(args,self.m_ctrlChromaticAdapation:GetValue())
		table.insert(args,self.m_ctrlLightAdaptation:GetValue())
		table.insert(args,self.m_ctrlIntensityAdjustmentParam:GetValue())
		table.insert(args,self.m_ctrlCompressionCurveParam:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_FILMLIC1) then
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_FILMLIC2) then
		table.insert(args,self.m_ctrlCutoff:GetValue())
	elseif(toneMapping == shader.PFMTonemapping.TONE_MAPPING_INSOMNIAC) then
		table.insert(args,self.m_ctrlCrossOverPoint:GetValue())
		table.insert(args,self.m_ctrlBlackPoint:GetValue())
		table.insert(args,self.m_ctrlShoulderStrength:GetValue())
		table.insert(args,self.m_ctrlWhitePoint:GetValue())
		table.insert(args,self.m_ctrlToeStrength:GetValue())
	end
	self.m_rt:SetToneMappingArguments(args)
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
		local path = util.Path(util.get_addon_path() .. "render/" .. self:GetCurrentFrameFilePath())
		util.open_path_in_explorer(path:GetPath(),path:GetFileName() .. ".png")
	end)
	self.m_btOpenOutputDir:SetText(locale.get_text("pfm_open_output_dir"))

	controls:SetHeight(self.m_btRefreshPreview:GetHeight())
	controls:Update()
	controls:SetAnchor(0,1,0,1)
end
function gui.PFMRenderPreview:GetCurrentFrameFilePath()
	local filmmaker = tool.get_filmmaker()
	local project = filmmaker:GetProject()
	local filmClip = filmmaker:GetActiveFilmClip()
	if(project == nil or filmClip == nil) then return end

	local frameIndex = filmmaker:GetClampedFrameOffset(filmmaker:TimeOffsetToFrameOffset(filmClip:LocalizeTimeOffset(filmmaker:GetTimeOffset())))
	local projectName = project:GetName()
	local filmClipName = filmClip:GetName()
	if(#projectName == 0) then projectName = "unnamed" end
	if(#filmClipName == 0) then filmClipName = "unnamed" end
	return projectName .. "/" .. filmClipName .. "/frame" .. string.fill_zeroes(frameIndex +1,4)
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
	elseif(selectedRenderMode == "normals") then renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_NORMALS
	elseif(selectedRenderMode == "depth") then renderMode = pfm.RaytracingRenderJob.Settings.RENDER_MODE_DEPTH end

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
	settings:SetDenoise(self.m_ctrlDenoise:IsChecked())
	settings:SetDeviceType(deviceType)
	settings:SetRenderWorld(self.m_ctrlRenderWorld:IsChecked())
	settings:SetRenderGameEntities(self.m_ctrlRenderGameEntities:IsChecked())
	settings:SetRenderPlayer(self.m_ctrlRenderPlayer:IsChecked())
	settings:SetCameraFrustumCullingEnabled(self.m_ctrlFrustumCulling:IsChecked())
	settings:SetPVSCullingEnabled(self.m_ctrlPVSCulling:IsChecked())
	settings:SetCamType(tonumber(self.m_ctrlCamType:GetValue()))
	settings:SetPanoramaType(tonumber(self.m_ctrlPanoramaType:GetValue()))
	settings:SetWidth(width)
	settings:SetHeight(height)

	self.m_rt:Refresh(preview)
end
gui.register("WIPFMRenderPreview",gui.PFMRenderPreview)

--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/rendering/renderers.lua")

local CyclesInfo = util.register_class("pfm.CyclesRendererInfo", pfm.RendererInfo)
function CyclesInfo:__init(identifier, assetData)
	pfm.RendererInfo.__init(self, identifier, assetData)
end
function CyclesInfo:ApplyRenderSettings(elSettings, renderSettings, preview)
	local deviceType = pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU
	local selectedDeviceType = tonumber(elSettings.m_ctrlDeviceType:GetValue())
	deviceType = selectedDeviceType

	local progressiveRefinement = elSettings.m_ctrlProgressiveRefinement:IsChecked()
	renderSettings:SetSamples(elSettings.m_ctrlSamplesPerPixel:GetValue())
	renderSettings:SetEmissionStrength(elSettings.m_ctrlEmissionStrength:GetValue())
	renderSettings:SetMaxTransparencyBounces(elSettings.m_ctrlMaxTransparencyBounces:GetValue())
	renderSettings:SetLightIntensityFactor(elSettings.m_ctrlLightIntensityFactor:GetValue())
	renderSettings:SetDeviceType(deviceType)
	renderSettings:SetDenoiseMode(tonumber(elSettings.m_ctrlDenoiseMode:GetValue()))
	renderSettings:SetProgressive(elSettings.m_ctrlProgressive:IsChecked())
	renderSettings:SetUseProgressiveRefinement(progressiveRefinement)
	renderSettings:SetPreCalculateLight(elSettings.m_ctrlPreCalcLight:IsChecked())
	renderSettings:SetUseOptix(elSettings.m_ctrlOptix:IsChecked())
end
function CyclesInfo:ApplyUIRenderSettingsPreset(elSettings, renderSettings, preset)
	if preset.samples ~= nil and util.is_valid(elSettings.m_ctrlSamplesPerPixel) then
		elSettings.m_ctrlSamplesPerPixel:SetValue(preset.samples)
	end
	if preset.max_transparency_bounces ~= nil and util.is_valid(elSettings.m_ctrlMaxTransparencyBounces) then
		elSettings.m_ctrlMaxTransparencyBounces:SetValue(preset.max_transparency_bounces)
	end
	if preset.emission_strength ~= nil and util.is_valid(elSettings.m_ctrlEmissionStrength) then
		elSettings.m_ctrlEmissionStrength:SetValue(preset.emission_strength)
	end
end
function CyclesInfo:InitializeUIRenderSettingControls(elParentSettings, renderSettings)
	local elSettings, collapsible = elParentSettings:AddCollapsibleSubMenu(locale.get_text("pfm_render_engine_cycles"), "cycles")
	-- Device Type
	local ctrl, wrapper = elSettings:AddDropDownMenu(pfm.LocStr("pfm_cycles_device_type"), "device_type", {
		{
			tostring(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU),
			locale.get_text("pfm_cycles_device_type_gpu"),
		},
		{
			tostring(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU),
			locale.get_text("pfm_cycles_device_type_cpu"),
		},
	}, tostring(renderSettings:GetDeviceType()))
	elSettings.m_ctrlDeviceType = ctrl
	wrapper:SetTooltip(locale.get_text("pfm_render_setting_device_type"))
	elSettings:LinkToUDMProperty("device_type", renderSettings, "deviceType")

	-- Denoise Mode
	ctrl, wrapper = elSettings:AddDropDownMenu(pfm.LocStr("pfm_denoise_mode"), "denoise_mode", {
		{ tostring(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_NONE), locale.get_text("disabled") },
		{ tostring(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_FAST), locale.get_text("fast") },
		{ tostring(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_AUTO_DETAILED), locale.get_text("detailed") },
		{ tostring(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_OPTIX), "Optix" },
		{ tostring(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_OPEN_IMAGE), "Intel Open Image Denoise" },
	}, tostring(renderSettings:GetDenoiseMode()))
	elSettings.m_ctrlDenoiseMode = ctrl
	wrapper:SetTooltip(locale.get_text("pfm_render_setting_denoise_mode"))
	elSettings:LinkToUDMProperty("denoise_mode", renderSettings, "denoiseMode")

	-- Sample count
	ctrl, wrapper = elSettings:AddSliderControl(
		pfm.LocStr("pfm_samples_per_pixel"),
		"samples_per_pixel",
		renderSettings:GetSamples(),
		1,
		500,
		nil,
		1.0,
		true
	)
	elSettings.m_ctrlSamplesPerPixel = ctrl
	ctrl:SetTooltip(locale.get_text("pfm_render_setting_ssp"))
	elSettings:LinkToUDMProperty("samples_per_pixel", renderSettings, "samples")

	-- Max transparency bounces
	ctrl, wrapper = elSettings:AddSliderControl(
		pfm.LocStr("pfm_max_transparency_bounces"),
		"max_transparency_bounces",
		renderSettings:GetMaxTransparencyBounces(),
		0,
		200,
		nil,
		1.0,
		true
	)
	elSettings.m_ctrlMaxTransparencyBounces = ctrl
	ctrl:SetTooltip(locale.get_text("pfm_render_setting_max_transparency_bounces"))
	elSettings:LinkToUDMProperty("max_transparency_bounces", renderSettings, "maxTransparencyBounces")

	-- Light intensity factor
	ctrl, wrapper = elSettings:AddSliderControl(
		pfm.LocStr("pfm_light_intensity_factor"),
		"light_intensity_factor",
		renderSettings:GetLightIntensityFactor(),
		0,
		20
	)
	elSettings.m_ctrlLightIntensityFactor = ctrl
	ctrl:SetTooltip(locale.get_text("pfm_render_setting_light_intensity_factor"))
	elSettings:LinkToUDMProperty("light_intensity_factor", renderSettings, "lightIntensityFactor")

	-- Emission strength
	ctrl = elSettings:AddSliderControl(
		pfm.LocStr("pfm_emission_strength"),
		"emission_strength",
		renderSettings:GetEmissionStrength(),
		0,
		20,
		function()
			if pfm.load_unirender() == false then
				return
			end
			unirender.PBRShader.set_global_emission_strength(elSettings.m_ctrlEmissionStrength:GetValue())
		end
	)
	elSettings.m_ctrlEmissionStrength = ctrl
	ctrl:SetTooltip(locale.get_text("pfm_render_setting_emission_strength"))
	elSettings:LinkToUDMProperty("emission_strength", renderSettings, "emissionStrength")

	ctrl, wrapper = elSettings:AddToggleControl(
		pfm.LocStr("pfm_render_progressive"),
		"progressive",
		renderSettings:IsProgressive(),
		function()
			elSettings.m_ctrlProgressiveRefinement:SetVisible(elSettings.m_ctrlProgressive:IsChecked())
		end
	)
	ctrl:SetTooltip(locale.get_text("pfm_render_setting_progressive"))
	elSettings.m_ctrlProgressive = ctrl
	elSettings.m_ctrlPreCalcLight = elSettings:AddToggleControl(
		pfm.LocStr("pfm_render_precalc_light"),
		"precalc_light",
		renderSettings:ShouldPreCalculateLight()
	)
	elSettings.m_ctrlPreCalcLight:SetTooltip(locale.get_text("pfm_render_setting_precalc_light"))
	elSettings.m_ctrlProgressiveRefinement = elSettings:AddToggleControl(
		pfm.LocStr("pfm_render_progressive_refinement"),
		"progressive_refine",
		renderSettings:IsProgressiveRefinementEnabled()
	)
	elSettings.m_ctrlProgressiveRefinement:SetTooltip(locale.get_text("pfm_render_setting_progressive_refinement"))

	local hasOptixCap = self:HasCapability("optix")
	elSettings.m_ctrlOptix = elSettings:AddToggleControl(locale.get_text("pfm_use_optix"), "use_optix", hasOptixCap)
	elSettings.m_ctrlOptix:SetTooltip(locale.get_text("pfm_render_setting_optix"))

	if not hasOptixCap then
		elSettings:SetControlEnabled("use_optix", false)
	end

	elSettings:LinkToUDMProperty("progressive", renderSettings, "progressive")
	elSettings:LinkToUDMProperty("progressive_refine", renderSettings, "progressiveRefinementEnabled")
	return elSettings, collapsible
end

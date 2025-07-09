-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/renderers.lua")

local PragmaInfo = util.register_class("pfm.PragmaRendererInfo", pfm.RendererInfo)
function PragmaInfo:__init(identifier, assetData)
	pfm.RendererInfo.__init(self, identifier, assetData)
end
function PragmaInfo:ApplyRenderSettings(elSettings, renderSettings, preview)
	renderSettings:SetSupersamplingFactor(
		preview and 1
			or tonumber(elSettings.m_ctrlSsFactor:GetOptionValue(elSettings.m_ctrlSsFactor:GetSelectedOption()))
	)

	local tileSize = tonumber(elSettings.m_ctrlTileSize:GetText())
	if elSettings.m_ctrlEnableTiledRendering:IsChecked() == false then
		tileSize = 0
	end
	renderSettings:SetTileSize(tileSize)
end
function PragmaInfo:ApplyUIRenderSettingsPreset(elSettings, renderSettings, preset)
	if preset.supersampling ~= nil and util.is_valid(elSettings.m_ctrlSsFactor) then
		elSettings.m_ctrlSsFactor:SelectOption(tostring(preset.supersampling))
	end
end
function PragmaInfo:InitializeUIRenderSettingControls(elParentSettings, renderSettings)
	local elSettings, collapsible = elParentSettings:AddCollapsibleSubMenu(locale.get_text("pfm_renderer_pragma"), "pragma")
	local ctrl, wrapper = elSettings:AddDropDownMenu(
		pfm.LocStr("pfm_supersampling_factor"),
		"super_sampling_factor",
		{
			{ "1", locale.get_text("disabled") },
			{ "2", "x2" },
			{ "4", "x4" },
		},
		1,
		function()
			renderSettings:SetSupersamplingFactor(
				tonumber(elSettings.m_ctrlSsFactor:GetOptionValue(elSettings.m_ctrlSsFactor:GetSelectedOption()))
			)
		end
	)
	elSettings.m_ctrlSsFactor = ctrl
	wrapper:SetName("ss_factor")
	wrapper:SetTooltip(locale.get_text("pfm_render_setting_supersampling_factor"))
	elSettings:LinkToUDMProperty("super_sampling_factor", renderSettings, "supersamplingFactor")

	local elText, wrapper, container = elSettings:AddTextEntry(
		pfm.LocStr("pfm_tile_size_pragma"),
		"tile_size",
		tostring(renderSettings:GetTileSize()),
		function(el) end
	)
	wrapper:SetTooltip(locale.get_text("pfm_render_setting_tile_size"))
	wrapper:SetName("tile_size")
	elSettings:LinkToUDMProperty("tile_size", renderSettings, "tileSize")
	elSettings.m_ctrlTileSize = elText

	--elSettings.m_ctrlRenderFramerate = elSettings:AddSliderControl(locale.get_text("pfm_render_framerate"),"render_framerate",renderSettings:GetRenderFramerate(),1,200,nil,1.0,true)
	--elSettings:LinkToUDMProperty("render_framerate",renderSettings,"render_framerate")
	if not tool.get_filmmaker():IsDeveloperModeEnabled() then
		container:SetVisible(false)
	end

	ctrl, wrapper =
		elSettings:AddToggleControl(pfm.LocStr("pfm_render_settings_tiled_rendering"), "tiled_rendering", false)
	elSettings.m_ctrlEnableTiledRendering = ctrl

	return elSettings, collapsible
end

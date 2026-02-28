-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/controls_menu/controls_menu.lua")

local Element = util.register_class("gui.PFMBaseSettings", gui.Base)
function Element:OnRemove()
	util.remove(self.m_cvarCallbacks)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_cvarCallbacks = {}
	self:SetSize(128, 128)

	local p = gui.create("pfm_controls_menu", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p
end
function Element:AddToggleControl(name, identifier, conVar, defaultValue, callback)
	local p = self.m_settingsBox:AddToggleControl(name, identifier, defaultValue, function(el, checked)
		console.run(conVar, checked and "1" or "0")
	end)
	local cb = console.add_change_callback(conVar, function(old, new)
		if self.m_skipConsoleCallbacks then
			return
		end
		p:SetChecked(new)
	end)
	table.insert(self.m_cvarCallbacks, cb)
	return p
end
function Element:AddSliderControl(name, identifier, conVar, defaultValue, min, max, callback, stepSize, integer)
	local p = self.m_settingsBox:AddSliderControl(name, identifier, defaultValue, min, max, callback, stepSize, integer)
	local cb = console.add_change_callback(conVar, function(old, new)
		if self.m_skipConsoleCallbacks then
			return
		end
		p:SetValue(new)
	end)
	table.insert(self.m_cvarCallbacks, cb)
	return p
end
function Element:SetConVar(cmd, val)
	self.m_skipConsoleCallbacks = true
	console.run(cmd, val)
	self.m_skipConsoleCallbacks = nil
end

local Element = util.register_class("gui.PFMSettings", gui.PFMBaseSettings)
function Element:OnInitialize()
	gui.PFMBaseSettings.OnInitialize(self)

	local skipCallbacks = true
	local p = self.m_settingsBox
	local elWindowMode, wrapper
	elWindowMode, wrapper = p:AddDropDownMenu(
		locale.get_text("window_mode"),
		"window_mode",
		{
			{ "0", locale.get_text("windowmode_fullscreen") },
			{ "1", locale.get_text("windowmode_windowed") },
			{ "2", locale.get_text("windowmode_noborder_window") },
		},
		console.get_convar_string("cl_render_window_mode"),
		function()
			if skipCallbacks then
				return
			end
			local windowMode = toint(elWindowMode:GetOptionValue(elWindowMode:GetSelectedOption()))
			time.create_simple_timer(0.0, function()
				console.run("cl_render_window_mode", tostring(windowMode))
			end)
		end
	)
	wrapper:SetUseAltMode(true)

	local options = {}
	local resMap = {}
	for _, vm in ipairs(gui.get_supported_video_modes()) do
		local resolution = tostring(vm.width) .. "x" .. tostring(vm.height)
		if resMap[resolution] == nil then
			resMap[resolution] = true
			table.insert(options, { resolution, resolution })
		end
	end
	local elResolution, wrapper
	elResolution, wrapper = p:AddDropDownMenu(
		locale.get_text("resolution"),
		"resolution",
		options,
		console.get_convar_string("cl_window_resolution"),
		function()
			if skipCallbacks then
				return
			end
			local resolution = elResolution:GetOptionValue(elResolution:GetSelectedOption())
			time.create_simple_timer(0.0, function()
				console.run("cl_window_resolution", resolution)
			end)
		end
	)
	wrapper:SetUseAltMode(true)

	if(engine.is_managed_by_package_manager() == false) then
		self:AddToggleControl(
			locale.get_text("pfm_enable_experimental_updates"),
			"enable_experimental_updates",
			"pfm_enable_experimental_updates",
			console.get_convar_bool("pfm_enable_experimental_updates"),
			function(el, checked)
				self:SetConVar("pfm_enable_experimental_updates", checked and "1" or "0")
			end
		)

		self:AddToggleControl(
			locale.get_text("pfm_should_check_for_updates"),
			"should_check_for_updates",
			"pfm_should_check_for_updates",
			console.get_convar_bool("pfm_should_check_for_updates"),
			function(el, checked)
				self:SetConVar("pfm_should_check_for_updates", checked and "1" or "0")
			end
		)
	end

	self:AddToggleControl(
		locale.get_text("pfm_tutorial_audio_enabled"),
		"tutorial_audio_enabled",
		"pfm_tutorial_audio_enabled",
		console.get_convar_bool("pfm_tutorial_audio_enabled"),
		function(el, checked)
			self:SetConVar("pfm_tutorial_audio_enabled", checked and "1" or "0")
		end
	)

	self:AddToggleControl(
		locale.get_text("pfm_developer_mode_enabled"),
		"developer_mode_enabled",
		"pfm_developer_mode_enabled",
		console.get_convar_bool("pfm_developer_mode_enabled"),
		function(el, checked)
			self:SetConVar("pfm_developer_mode_enabled", checked and "1" or "0")
		end
	)

	self:AddToggleControl(
		locale.get_text("pfm_keep_current_layout_setting"),
		"keep_current_layout",
		"pfm_keep_current_layout",
		console.get_convar_bool("pfm_keep_current_layout"),
		function(el, checked)
			self:SetConVar("pfm_keep_current_layout", checked and "1" or "0")
		end
	)

	self:AddToggleControl(
		locale.get_text("pfm_save_layout"),
		"save_layout",
		"pfm_save_layout",
		console.get_convar_bool("pfm_save_layout"),
		function(el, checked)
			self:SetConVar("pfm_save_layout", checked and "1" or "0")
		end
	)

	self:AddToggleControl(
		locale.get_text("pfm_save_undo_stack"),
		"save_undo_stack",
		"pfm_save_undo_stack",
		console.get_convar_bool("pfm_save_undo_stack"),
		function(el, checked)
			self:SetConVar("pfm_save_undo_stack", checked and "1" or "0")
		end
	)

	self:AddToggleControl(
		locale.get_text("pfm_autosave_enabled"),
		"autosave_enabled",
		"pfm_autosave_enabled",
		console.get_convar_bool("pfm_autosave_enabled"),
		function(el, checked)
			self:SetConVar("pfm_autosave_enabled", checked and "1" or "0")
		end
	)

	self:AddSliderControl(
		locale.get_text("pfm_autosave_time_interval"),
		"autosave_time_interval",
		"pfm_autosave_time_interval",
		console.get_convar_float("pfm_autosave_time_interval") / 60,
		0.5,
		30,
		function(el, value)
			self:SetConVar("pfm_autosave_time_interval", value * 60)
		end,
		0.25
	)

	self:AddSliderControl(
		locale.get_text("pfm_autosave_max_count"),
		"autosave_max_count",
		"pfm_autosave_max_count",
		console.get_convar_int("pfm_autosave_max_count"),
		1,
		30,
		function(el, value)
			self:SetConVar("pfm_autosave_max_count", value)
		end,
		1,
		true
	)

	self:AddSliderControl(
		locale.get_text("pfm_max_undo_steps"),
		"max_undo_steps",
		"pfm_max_undo_steps",
		console.get_convar_int("pfm_max_undo_steps"),
		1,
		1000,
		function(el, value)
			self:SetConVar("pfm_max_undo_steps", value)
		end,
		1,
		true
	)

	p:Update()
	p:SizeToContents()

	p:ResetControls()
	skipCallbacks = false
end
gui.register("pfm_settings", Element)

-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

console.register_variable(
	"pfm_max_fps",
	udm.TYPE_INT32,
	-1,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Clamp the max game fps to this value while the filmmaker is running."
)
console.register_variable(
	"pfm_asset_icon_size",
	udm.TYPE_UINT32,
	128,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"The resolution to use for generated asset icons."
)
console.register_variable(
	"pfm_asset_icon_size_character",
	udm.TYPE_STRING,
	"256x512",
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"The resolution to use for generated asset icons of character models."
)
console.register_variable(
	"pfm_animation_rdp_decimation_error",
	udm.TYPE_FLOAT,
	0.03,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"The error value for decimating animation curves using Ramer–Douglas–Peucker."
)
console.register_variable(
	"pfm_animation_max_curve_sample_count",
	udm.TYPE_UINT32,
	100,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Maximum number of curve samples to create when generating curve animation data."
)
console.register_variable(
	"pfm_max_undo_steps",
	udm.TYPE_UINT32,
	100,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Maximum number of undo steps."
)
console.register_variable(
	"pfm_restore",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_HIDDEN),
	"For internal use only. If enabled, last filmmaker state will be restored after level change."
)
console.register_variable(
	"pfm_enable_experimental_updates",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, the auto-updater will download the latest nightly release instead of stable versions."
)
console.register_variable(
	"pfm_tutorial_audio_enabled",
	udm.TYPE_BOOLEAN,
	true,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, voiced audio will be played during tutorials if available."
)
local shouldCheckForUpdates = true
local automaticUpdatesEnabled = true
if(engine.is_managed_by_package_manager()) then
	-- Updates are handled by package manager
	shouldCheckForUpdates = false
	automaticUpdatesEnabled = false
end
console.register_variable(
	"pfm_should_check_for_updates",
	udm.TYPE_BOOLEAN,
	shouldCheckForUpdates,
	bit.bor(console.FLAG_BIT_HIDDEN),
	"If enabled, PFM will check for updates on startup."
)
console.register_variable(
	"pfm_automatic_updates_enabled",
	udm.TYPE_BOOLEAN,
	automaticUpdatesEnabled,
	bit.bor(console.FLAG_BIT_HIDDEN),
	"Determines whether automatic updates are enabled."
)
console.register_variable(
	"pfm_developer_mode_enabled",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, developer features will be enabled."
)
console.register_variable(
	"pfm_debug_dump_graph_editor_edit_log",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_HIDDEN),
	"If enabled, debug information will be dumped into the console when editing animation data in the graph editor."
)
console.register_variable(
	"pfm_debug_dump_render_image_stages",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_HIDDEN),
	"If enabled, the render image stages will be dumped as image files to temp/render_image_stages/*.png."
)
console.register_variable(
	"pfm_camera_speed",
	udm.TYPE_FLOAT,
	200,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"The movement speed of the camera."
)
console.register_variable(
	"pfm_camera_speed_shift_multiplier",
	udm.TYPE_FLOAT,
	4.0,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Multiplier for the camera speed if the shift-key is held."
)
console.register_variable(
	"pfm_theme",
	udm.TYPE_STRING,
	"",
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Theme to use for PFM. Leave empty to use system default dark/light theme."
)
console.register_variable(
	"pfm_sensitive_content_enabled",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Enable sensitive content?"
)
console.add_change_callback("pfm_theme", function(old, new)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		tool.get_filmmaker():UpdateSkin()
	end
end)

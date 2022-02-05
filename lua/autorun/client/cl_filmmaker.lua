--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

console.register_variable("pfm_max_fps",udm.TYPE_INT32,-1,bit.bor(console.FLAG_BIT_ARCHIVE),"Clamp the max game fps to this value while the filmmaker is running.")
console.register_variable("pfm_asset_icon_size",udm.TYPE_UINT32,128,bit.bor(console.FLAG_BIT_ARCHIVE),"The resolution to use for generated asset icons.")
console.register_variable("pfm_asset_icon_size_character",udm.TYPE_STRING,"256x512",bit.bor(console.FLAG_BIT_ARCHIVE),"The resolution to use for generated asset icons of character models.")
console.register_variable("pfm_experimental_enable_panima_for_flex_and_skeletal_animations",udm.TYPE_BOOLEAN,true,bit.bor(console.FLAG_BIT_ARCHIVE),"If enabled, the new panima animation system will be used for flex and skeletal animations.")

tool = tool or {}
tool.close_filmmaker = function()
	local entScene = ents.find_by_class("pfm_scene")[1]
	if(util.is_valid(entScene)) then entScene:Remove() end -- TODO: Do this properly once the actual filmmaker tool is ready
	if(tool.is_filmmaker_open() == false) then return end
	tool.editor:Close()
	tool.editor = nil
	tool.filmmaker = nil
end
tool.get_filmmaker = function() return tool.filmmaker end
tool.is_filmmaker_open = function() return util.is_valid(tool.editor) end
tool.is_developer_mode_enabled = function() return tool.developerMode or false end
tool.load_filmmaker_scripts = function()
	include("/sfm/project_converter.lua")
	pfm.register_log_category("sfm")
	include("/gui/editors/filmmaker/filmmaker.lua")
end
tool.open_filmmaker = function(devMode)
	tool.load_filmmaker_scripts()
	tool.close_filmmaker()

	debug.start_profiling_task("pfm_launch")

	tool.developerMode = devMode or false
	tool.editor = gui.create("WIFilmmaker")
	tool.filmmaker = tool.editor
	tool.editor:SetAutoAlignToParent(true)
	-- tool.editor:SetZPos(1000)

	tool.editor:Open()
	debug.stop_profiling_task()
	return tool.editor
end

console.register_command("pfm",function(pl,...)
	tool.load_filmmaker_scripts()
	local logCategories = 0
	local reload = false
	local dev = false
	local project
	for cmd,args in pairs(console.parse_command_arguments({...})) do
		if(cmd == "log") then
			for _,catName in ipairs(args) do
				if(catName:lower() == "all") then
					logCategories = bit.lshift(1,pfm.MAX_LOG_CATEGORIES) -1
					break
				end
				if(pfm["LOG_CATEGORY_" .. catName:upper()] ~= nil) then
					logCategories = bit.bor(logCategories,pfm["LOG_CATEGORY_" .. catName:upper()])
				else
					console.print_warning("Unknown pfm log category '" .. catName .. "'! Ignoring...")
				end
			end
		elseif(cmd == "reload") then reload = true
		elseif(cmd == "dev") then dev = true
		elseif(cmd == "project") then project = args[1] end
	end
	pfm.set_enabled_log_categories(logCategories)

	if(tool.is_filmmaker_open()) then
		if(reload) then
			-- Fast way of reloading the editor without having to reload the project as well.
			-- Mainly used for developing and testing the interface.
			local pfm = tool.get_filmmaker()
			if(util.is_valid(pfm)) then pfm:SetDeveloperModeEnabled(dev) end
			pfm:ReloadInterface()
			return
		end
		tool.close_filmmaker()
		return
	end

	-- TODO: This code should only be enabled during development/testing!
	-- Remove it for the public release!
	console.run("cl_render_shadow_resolution 1024")
	console.run("cl_render_occlusion_culling 4")
	console.run("render_clear_scene 1")

	--[[local ent = ents.find_by_name("pfm_light_demo")[1]
	if(util.is_valid(ent) == false) then
		local ent = ents.create("env_light_point")
		ent:SetPos(Vector(28.4143,605.566,-2673.99))
		ent:SetKeyValue("spawnflags",tostring(1024))
		local colComponent = ent:GetComponent(ents.COMPONENT_COLOR)
		if(colComponent ~= nil) then colComponent:SetColor(light.color_temperature_to_color(2700)) end
		local radiusComponent = ent:GetComponent(ents.COMPONENT_RADIUS)
		if(radiusComponent ~= nil) then radiusComponent:SetRadius(300) end
		local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
		if(lightC ~= nil) then lightC:SetLightIntensity(200) end
		ent:Spawn()
		ent:SetName("pfm_light_demo")

		local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
		if(toggleC ~= nil) then toggleC:TurnOn() end
	end]]
	--
	local pfm = tool.open_filmmaker(dev)
	if(project ~= nil) then pfm:LoadProject(project) end
end)

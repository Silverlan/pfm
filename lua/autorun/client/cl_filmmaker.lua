-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/panels/loading_screen.lua")
include("/pfm/core/cvars.lua")

pfm.show_loading_screen(false)

console.register_command("pfm_debug_dump_undo_stack", function(pl, key, cmd)
	local udmFile = udm.create()
	local udmData = udmFile:GetAssetData():GetData()
	pfm.undoredo.serialize(udmData)
	print("Undo/Redo Stack Data:")
	print(udmData:ToAscii())
	print("\n\n")
end)
console.register_command("pfm_bind", function(pl, key, cmd)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false or key == nil or cmd == nil then
		return
	end
	pm:GetInputBindingLayer():BindKey(key, cmd)
	pm:UpdateInputBindings()
end)
console.register_command("pfm_unbind", function(pl, key)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false or key == nil then
		return
	end
	pm:GetInputBindingLayer():UnbindKey(key)
	pm:UpdateInputBindings()
end)

tool = tool or {}
tool.close_filmmaker = function()
	local entScene = ents.find_by_class("pfm_scene")[1]
	if util.is_valid(entScene) then
		entScene:Remove()
	end -- TODO: Do this properly once the actual filmmaker tool is ready
	if tool.is_filmmaker_open() == false then
		return
	end
	tool.editor:Close()
	tool.editor = nil
	tool.filmmaker = nil
end
tool.get_filmmaker = function()
	return tool.filmmaker
end
tool.is_filmmaker_open = function()
	return util.is_valid(tool.editor)
end
tool.is_developer_mode_enabled = function()
	return tool.developerMode or false
end
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
	tool.editor = gui.create("filmmaker")
	tool.filmmaker = tool.editor
	tool.editor:SetAutoAlignToParent(true)
	-- tool.editor:SetZPos(1000)

	tool.editor:Open()
	debug.stop_profiling_task()
	return tool.editor
end

local function start_pfm(launchData, ...)
	tool.load_filmmaker_scripts()
	local logCategories = 0
	local logCategoriesDefined = false
	local reload = false
	local dev = console.get_convar_bool("pfm_developer_mode_enabled")
	local project
	local args = console.parse_command_arguments({ ... })
	for cmd, args in pairs(args) do
		if launchData.parseArgument == nil or launchData.parseArgument(cmd, args) ~= util.EVENT_REPLY_HANDLED then
			if cmd == "log" then
				logCategoriesDefined = true
				for _, catName in ipairs(args) do
					if catName:lower() == "all" then
						logCategories = bit.lshift(1, pfm.MAX_LOG_CATEGORIES) - 1
						break
					end
					if pfm["LOG_CATEGORY_" .. catName:upper()] ~= nil then
						logCategories = bit.bor(logCategories, pfm["LOG_CATEGORY_" .. catName:upper()])
					else
						console.print_warning("Unknown pfm log category '" .. catName .. "'! Ignoring...")
					end
				end
			elseif cmd == "reload" then
				reload = true
			elseif cmd == "dev" then
				dev = true
			elseif cmd == "project" then
				project = args[1]
			end
		end
	end
	if logCategoriesDefined == false then
		logCategories = bit.lshift(1, pfm.MAX_LOG_CATEGORIES) - 1
	end -- Log everything by default
	pfm.set_enabled_log_categories(logCategories)

	if tool.is_filmmaker_open() then
		if reload then
			-- Fast way of reloading the editor without having to reload the project as well.
			-- Mainly used for developing and testing the interface.
			local pm = pfm.get_project_manager()
			if util.is_valid(pm) then
				pm:SetDeveloperModeEnabled(dev)
			end
			pm:ReloadInterface()
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
	local pfm = launchData.launchTool(dev)
	if project ~= nil then
		pfm:LoadProject(project)
	end
	return pfm
end

pfm.launch = function(launchData, ...)
	launchData = launchData or {}
	launchData.launchTool = launchData.launchTool or function(dev)
		return tool.open_filmmaker(dev)
	end
	return start_pfm(launchData, ...)
end

local cbOnGameReady
console.register_command("pfm", function(pl, ...)
	if game.is_game_ready() then
		pfm.launch(nil, ...)
	else
		util.remove(cbOnGameReady)
		local args = { ... }
		cbOnGameReady = game.add_callback("OnGameReady", function()
			util.remove(cbOnGameReady)
			time.create_simple_timer(0.0, function()
				pfm.launch(nil, unpack(args))
			end)
		end)
	end
end)

if console.get_convar_bool("pfm_restore") then
	console.run("pfm_restore", "0")
	time.create_simple_timer(0.0, function()
		local pm = tool.open_filmmaker(console.get_convar_bool("pfm_developer_mode_enabled"))
		if util.is_valid(pm) then
			pm:RestoreProject()
		end
	end)
end

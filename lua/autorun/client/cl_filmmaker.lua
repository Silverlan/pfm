--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm/project_converter.lua")
include("/gui/wifiledialog.lua")

pfm.register_log_category("sfm")

local pEditor
tool = tool or {}
tool.close_filmmaker = function()
	local entScene = ents.find_by_class("pfm_scene")[1]
	if(util.is_valid(entScene)) then entScene:Remove() end -- TODO: Do this properly once the actual filmmaker tool is ready
	if(tool.is_editor_open() == false) then return end
	pEditor:Remove()
	pEditor = nil
end
tool.is_filmmaker_open = function() return util.is_valid(pEditor) end
tool.open_filmmaker = function(projectFilePath)
	include("/gui/editors/filmmaker/filmmaker.lua")
	tool.close_editor()
	pEditor = gui.create("WIFilmmaker")
	pEditor:SetAutoAlignToParent(true)

	pEditor:Open()
	return pEditor
end

local pOpenDialogue
console.register_command("pfm",function(pl,...)
	local logCategories = 0
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
		end
	end
	pfm.set_enabled_log_categories(logCategories)

	-- TODO: This code should only be enabled during development/testing!
	-- Remove it for the public release!
	console.run("cl_render_shadow_resolution 4096")
	console.run("cl_render_occlusion_culling 0")

	local ent = ents.find_by_name("pfm_light_demo")[1]
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
	end
	--

	if(tool.is_filmmaker_open()) then tool.close_filmmaker()
	else tool.open_filmmaker() end
end)

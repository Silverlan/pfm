-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.detail = pfm.detail or {}
pfm.detail.component_actions = pfm.detail.component_actions or {}
pfm.register_component_action = function(componentName, localeId, id, onInit)
	local action = {
		componentName = componentName,
		locale = localeId,
		identifier = id,
		initialize = onInit,
	}
	local actions = pfm.detail.component_actions
	actions[componentName] = actions[componentName] or {}
	for i, curAction in ipairs(actions[componentName]) do
		if curAction.identifier == id then
			actions[componentName][i] = action
			return
		end
	end
	table.insert(actions[componentName], action)
end

pfm.get_component_actions = function(componentName)
	return pfm.detail.component_actions[componentName]
end

-------------------

include("/gui/pfm/bake/reflection_probe_baker.lua")
pfm.detail.active_bakers = pfm.detail.active_bakers or {}
local function add_baker(identifier, class, actorData, entActor)
	local uuid = tostring(entActor:GetUuid())
	pfm.detail.active_bakers[identifier] = pfm.detail.active_bakers[identifier] or {}
	local activeBakers = pfm.detail.active_bakers[identifier]
	local baker = activeBakers[uuid]
	if baker ~= nil and baker:IsBaking() == false then
		baker:Clear()
		baker = nil
	end
	if baker == nil then
		baker = class()
		activeBakers[uuid] = baker
		baker:SetActor(actorData, entActor)
	end
	return baker
end
pfm.register_component_action(
	"reflection_probe",
	"pfm_bake_reflection_probe",
	"bake_reflection_probe",
	function(controls, actorData, entActor, actionData)
		util.remove(actionData.baker)

		local baker = add_baker("reflection_probe", pfm.ReflectionProbeBaker, actorData, entActor)
		local el = gui.create("WIBakeButton", controls)
		el:SetName("bake_reflection_probe")
		el:SetBakeText(locale.get_text("pfm_bake_reflection_probe"))
		el:SetBaker(baker)
		actionData.baker = el
		return el
	end
)
pfm.register_component_action(
	"reflection_probe",
	"pfm_view_reflection_probe",
	"view_reflection_probe",
	function(controls, actorData, entActor, actionData)
		if util.is_valid(actionData.windowHandle) then
			actionData.windowHandle:Close()
		end
		util.remove(actionData.windowHandle)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetName("view_reflection_probe")
		bt:SetText(locale.get_text("pfm_view_reflection_probe"))
		bt:AddCallback("OnPressed", function()
			pfm.util.open_reflection_probe_view_window(entActor, function(windowHandle, contents, controls)
				actionData.windowHandle = windowHandle
			end)
		end)
		return bt
	end
)

-------------------

include("/gui/pfm/bake/lightmap_baker.lua")

-- Bake Lightmap UV coordinates (developer mode only)
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_bake_lightmap_uvs",
	"bake_lightmap_uvs",
	function(controls, actorData, entActor, actionData)
		if tool.get_filmmaker():IsDeveloperModeEnabled() == false then
			return
		end
		util.remove(actionData.baker)

		local baker = add_baker("uv", pfm.UvBaker, actorData, entActor)
		local el = gui.create("WIBakeButton", controls)
		el:SetBakeText(locale.get_text("pfm_bake_uvs"))
		el:SetBaker(baker)
		actionData.baker = el
		return el
	end
)

-- Bake lightmaps
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_bake_lightmap",
	"bake_lightmap",
	function(controls, actorData, entActor, actionData)
		util.remove(actionData.baker)

		local baker = add_baker("lightmap", pfm.LightmapBaker, actorData, entActor)
		local el = gui.create("WIBakeButton", controls)
		el:SetName("bake_lightmaps")
		el:SetBakeText(locale.get_text("pfm_bake_lightmaps"))
		el:SetBaker(baker)
		actionData.baker = el
		return el
	end
)

-- Generate render job
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_bake_lightmap_job",
	"bake_lightmap_job",
	function(controls, actorData, entActor, actionData)
		util.remove(actionData.baker)

		local baker = add_baker("lightmap_render_job", pfm.LightmapBaker, actorData, entActor)
		baker:SetGenerateRenderJob(true)

		local el = gui.create("WIBakeButton", controls)
		el:SetName("create_lightmap_render_job")
		el:SetBakeText(locale.get_text("pfm_generate_render_job"))
		el:SetBaker(baker)
		actionData.baker = el
		return el
	end
)

local function update_directional_lightmaps(c)
	if c:IsLightmapUvRebuildRequired() then
		pfm.log("Lightmap UV data cache is out of date, rebuilding...", pfm.LOG_CATEGORY_PFM_BAKE)
		c:GenerateLightmapUvs()

		local lmMode = c:GetLightmapMode()
		if lmMode == ents.PFMBakedLighting.LIGHTMAP_MODE_DIRECTIONAL then
			pfm.log("Directional lightmap atlas is out of date, rebuilding...", pfm.LOG_CATEGORY_PFM_BAKE)
			c:GenerateDirectionalLightmaps()
		end
	end
end
-- Import direct lightmap
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_import_direct",
	"import_direct_lightmap",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_import_direct_lightmap"))
		bt:AddCallback("OnPressed", function()
			local c = entActor:GetComponent(ents.COMPONENT_PFM_BAKED_LIGHTING)
			if c ~= nil then
				local dialogue = pfm.create_file_open_dialog(function(pDialog, fileName)
					if c:IsValid() == false then
						return
					end
					c:ImportLightmapTexture("diffuse_direct_map", "lightmap_diffuse_direct", fileName)
					update_directional_lightmaps(c)
				end)
				dialogue:SetRootPath("")
				dialogue:SetExtensions(asset.get_supported_extensions(asset.TYPE_TEXTURE))
				dialogue:Update()
			end
		end)
		return bt
	end
)

-- Import indirect lightmap
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_import_indirect",
	"import_indirect_lightmap",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_import_indirect_lightmap"))
		bt:AddCallback("OnPressed", function()
			local c = entActor:GetComponent(ents.COMPONENT_PFM_BAKED_LIGHTING)
			if c ~= nil then
				local dialogue = pfm.create_file_open_dialog(function(pDialog, fileName)
					if c:IsValid() == false then
						return
					end
					c:ImportLightmapTexture("diffuse_indirect_map", "lightmap_diffuse_indirect", fileName)
					update_directional_lightmaps(c)
				end)
				dialogue:SetRootPath("")
				dialogue:SetExtensions(asset.get_supported_extensions(asset.TYPE_TEXTURE))
				dialogue:Update()
			end
		end)
		return bt
	end
)

-- Auto import lightmaps
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_import_render_tool",
	"import_render_tool_lightmaps",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetName("import_lightmaps")
		bt:SetText(locale.get_text("pfm_import_render_tool_lightmaps"))
		bt:AddCallback("OnPressed", function()
			local c = entActor:GetComponent(ents.COMPONENT_PFM_BAKED_LIGHTING)
			if c ~= nil then
				local basePath = "render/lightmaps/"
				local directPath = basePath .. "lightmap.png_direct.dds"
				local indirectPath = basePath .. "lightmap.png_indirect.dds"
				for _, path in ipairs({ directPath, indirectPath }) do
					-- Files may have been written by render tool in the background, so we
					-- need to update the file index cache
					file.update_file_index_cache(path)

					if file.exists(path) == false then
						pfm.create_popup_message(
							locale.get_text("pfm_popup_failed_to_import_lightmaps", { path }),
							nil,
							gui.InfoBox.TYPE_WARNING
						)
						return util.EVENT_REPLY_HANDLED
					end
				end
				c:ImportLightmapTexture("diffuse_direct_map", "lightmap_diffuse_direct", directPath)
				c:ImportLightmapTexture("diffuse_indirect_map", "lightmap_diffuse_indirect", indirectPath)
				update_directional_lightmaps(c)
			end
			return util.EVENT_REPLY_HANDLED
		end)
		return bt
	end
)

-- View lightmap atlas
include("/debug/lightmaps.lua")
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_view_lightmap_atlas",
	"view_lightmap_atlas",
	function(controls, actorData, entActor, actionData)
		if util.is_valid(actionData.windowHandle) then
			actionData.windowHandle:Close()
		end
		util.remove(actionData.windowHandle)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_view_lightmap_atlas"))
		bt:AddCallback("OnPressed", function()
			debug.open_lightmap_atlas_view(entActor, function(windowHandle, contents, controls)
				actionData.windowHandle = windowHandle
			end)
		end)
		return bt
	end
)

-- Bake directional lightmaps (developer mode only)
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_bake_directional_lightmap",
	"bake_directional_lightmap",
	function(controls, actorData, entActor, actionData)
		--[[if(tool.get_filmmaker():IsDeveloperModeEnabled() == false) then return end
	util.remove(actionData.baker)
	local el = gui.create("WIDirectionalLightmapBaker",controls)
	el:SetActor(actorData,entActor)
	actionData.baker = el]]
		return el
	end
)

-- Quality presets
pfm.register_component_action(
	"pfm_baked_lighting",
	"pfm_bake_quality_preset",
	"bake_quality_preset",
	function(controls, actorData, entActor, actionData)
		local presets = {
			{
				name = locale.get_text("low"),
				sampleCount = 200,
				resolution = "1024x1024",
				lightmapMode = "Directional",
			},
			{
				name = locale.get_text("medium"),
				sampleCount = 2000,
				resolution = "2048x2048",
				lightmapMode = "Directional",
			},
			{
				name = locale.get_text("pfm_preset_production_4k"),
				sampleCount = 20000,
				resolution = "4096x4096",
				lightmapMode = "Directional",
			},
			{
				name = locale.get_text("pfm_preset_production_8k"),
				sampleCount = 20000,
				resolution = "8192x8192",
				lightmapMode = "Directional",
			},
			{
				name = locale.get_text("pfm_preset_production_16k"),
				sampleCount = 20000,
				resolution = "16384x16384",
				lightmapMode = "Directional",
			},
			{
				name = locale.get_text("pfm_preset_production_32k"),
				sampleCount = 20000,
				resolution = "32768x32768",
				lightmapMode = "Directional",
			},
		}

		local el, wrapper
		local options = {}
		for i, preset in ipairs(presets) do
			table.insert(options, { tostring(i - 1), preset.name })
		end
		el, wrapper = controls:AddDropDownMenu(
			locale.get_text("pfm_cycles_quality_preset"),
			"bake_preset_quality",
			options,
			0,
			function(el, option)
				local mode = toint(el:GetOptionValue(el:GetSelectedOption()))
				local preset = presets[mode + 1]
				if preset == nil then
					return
				end
				local c = entActor:GetComponent(ents.COMPONENT_PFM_BAKED_LIGHTING)
				if c ~= nil then
					c:SetMemberValue("sampleCount", preset.sampleCount)
					c:SetMemberValue("resolution", preset.resolution)
					c:SetMemberValue("lightmapMode", preset.lightmapMode)

					local actorEditor = tool.get_filmmaker():GetActorEditor()
					if util.is_valid(actorEditor) then
						actorEditor:UpdateActorProperty(actorData, "ec/pfm_baked_lighting/sampleCount")
						actorEditor:UpdateActorProperty(actorData, "ec/pfm_baked_lighting/resolution")
						actorEditor:UpdateActorProperty(actorData, "ec/pfm_baked_lighting/lightmapMode")
					end
				end
			end
		)
		return wrapper
	end
)

pfm.register_component_action(
	"pfm_region_carver",
	"pfm_carve",
	"carve",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_carve"))
		bt:AddCallback("OnPressed", function()
			if util.is_valid(entActor) == false then
				return
			end
			pfm.open_message_prompt(
				locale.get_text("pfm_prompt_continue"),
				locale.get_text("pfm_prompt_action_cannot_be_undone"),
				bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO),
				function(bt)
					if bt == gui.PfmPrompt.BUTTON_YES and entActor:IsValid() then
						local c = entActor:GetComponent(ents.COMPONENT_PFM_REGION_CARVER)
						if c ~= nil then
							c:Carve()
						end
					end
				end
			)
		end)
		return bt
	end
)

pfm.register_component_action(
	"pfm_region_carver",
	"pfm_remove_outside_actors",
	"remove_outside",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_remove_outside"))
		bt:AddCallback("OnPressed", function()
			local tRemove = {}
			if ents.COMPONENT_PFM_REGION_CARVE_TARGET ~= nil then
				for ent, c in ents.citerator(ents.COMPONENT_PFM_REGION_CARVE_TARGET) do
					if ent:HasComponent(ents.COMPONENT_PFM_ACTOR) and c:GetCarvedModel() == "empty" then
						table.insert(tRemove, tostring(ent:GetUuid()))
					end
				end
			end
			local actorEditor = tool.get_filmmaker():GetActorEditor()
			if util.is_valid(actorEditor) then
				actorEditor:RemoveActors(tRemove)
			end
		end)
		return bt
	end
)

-------------------

pfm.register_component_action(
	"pfm_vr_tracked_device",
	"pfm_vr_identify_device",
	"vr_identify_device",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("vr_identify_device"))
		bt:AddCallback("OnPressed", function()
			if util.is_valid(entActor) == false then
				return
			end
			local c = entActor:GetComponent(ents.COMPONENT_PFM_VR_TRACKED_DEVICE)
			local tdC = (c ~= nil) and c:GetTrackedDevice()
			if tdC ~= nil then
				tdC:TriggerHapticPulse()
			end
		end)
		return bt
	end
)

pfm.register_component_action(
	"pfm_vr_manager",
	"pfm_start_recording",
	"vr_start_recording",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("vr_start_recording"))
		bt:AddCallback("OnPressed", function()
			if util.is_valid(entActor) == false then
				return
			end
			local c = entActor:GetComponent(ents.COMPONENT_PFM_VR_MANAGER)
			if c ~= nil then
				c:StartRecording()
			end
		end)
		return bt
	end
)

pfm.register_component_action(
	"pfm_vr_manager",
	"pfm_stop_recording",
	"vr_stop_recording",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("vr_stop_recording"))
		bt:AddCallback("OnPressed", function()
			if util.is_valid(entActor) == false then
				return
			end
			local c = entActor:GetComponent(ents.COMPONENT_PFM_VR_MANAGER)
			if c ~= nil then
				c:EndRecording()
			end
		end)
		return bt
	end
)

-- View bloom map
local function view_bloom_map(ent, onInit)
	pfm.util.open_simple_window(locale.get_text("pfm_bloom_map"), function(windowHandle, contents, controls)
		local el = gui.create("WIDebugHDRBloom", contents, 0, 0, contents:GetWidth(), contents:GetHeight(), 0, 0, 1, 1)
		el:ScheduleUpdate()

		if onInit ~= nil then
			onInit(windowHandle, contents, controls)
		end
	end)
end
pfm.register_component_action(
	"pfm_bloom",
	"pfm_view_bloom_map",
	"view_bloom_map",
	function(controls, actorData, entActor, actionData)
		if util.is_valid(actionData.windowHandle) then
			actionData.windowHandle:Close()
		end
		util.remove(actionData.windowHandle)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("pfm_view_bloom_map"))
		bt:AddCallback("OnPressed", function()
			view_bloom_map(entActor, function(windowHandle, contents, controls)
				actionData.windowHandle = windowHandle
			end)
		end)
		return bt
	end
)

-------------------

pfm.register_component_action(
	"lua_script",
	"pfm_lua_script_execute",
	"execute_lua_script",
	function(controls, actorData, entActor, actionData)
		local bt = gui.create("WIPFMActionButton", controls)
		bt:SetText(locale.get_text("execute"))
		bt:AddCallback("OnPressed", function()
			if util.is_valid(entActor) == false then
				return
			end
			local c = entActor:GetComponent(ents.COMPONENT_LUA_SCRIPT)
			if c ~= nil then
				c:Execute()
			end
		end)
		return bt
	end
)

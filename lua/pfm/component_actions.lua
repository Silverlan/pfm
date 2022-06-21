--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.detail = pfm.detail or {}
pfm.detail.component_actions = pfm.detail.component_actions or {}
pfm.register_component_action = function(componentName,localeId,id,onInit)
	local action = {
		componentName = componentName,
		locale = localeId,
		identifier = id,
		initialize = onInit
	}
	local actions = pfm.detail.component_actions
	actions[componentName] = actions[componentName] or {}
	actions[componentName][id] = action
end

pfm.get_component_actions = function(componentName)
	return pfm.detail.component_actions[componentName]
end

-------------------

include("/gui/pfm/bake/reflection_probe_baker.lua")
pfm.register_component_action("reflection_probe","pfm_bake_reflection_probe","bake_reflection_probe",function(controls,actorData,entActor,actionData)
	util.remove(actionData.baker)
	local el = gui.create("WIReflectionProbeBaker",controls)
	el:SetActor(actorData,entActor)
	actionData.baker = el
	return el
end)
pfm.register_component_action("reflection_probe","pfm_view_reflection_probe","view_reflection_probe",function(controls,actorData,entActor,actionData)
	if(util.is_valid(actionData.windowHandle)) then actionData.windowHandle:Close() end
	util.remove(actionData.windowHandle)
	local bt = gui.create("WIPFMButton",controls)
	bt:SetText("View Reflection Probe")
	bt:AddCallback("OnPressed",function()
		pfm.util.open_reflection_probe_view_window(entActor,function(windowHandle,contents,controls)
			actionData.windowHandle = windowHandle
		end)
	end)
	return bt
end)

-------------------

include("/gui/pfm/bake/lightmap_baker.lua")
pfm.register_component_action("pfm_baked_lighting","pfm_bake_lightmap_uvs","bake_lightmap_uvs",function(controls,actorData,entActor,actionData)
	util.remove(actionData.baker)
	local el = gui.create("WILightmapUvBaker",controls)
	el:SetActor(actorData,entActor)
	actionData.baker = el
	return el
end)
pfm.register_component_action("pfm_baked_lighting","pfm_bake_lightmap","bake_lightmap",function(controls,actorData,entActor,actionData)
	util.remove(actionData.baker)
	local el = gui.create("WILightmapBaker",controls)
	el:SetActor(actorData,entActor)
	actionData.baker = el
	return el
end)
pfm.register_component_action("pfm_baked_lighting","pfm_view_lightmap_atlas","view_lightmap_atlas",function(controls,actorData,entActor,actionData)
	if(util.is_valid(actionData.windowHandle)) then actionData.windowHandle:Close() end
	util.remove(actionData.windowHandle)
	local bt = gui.create("WIPFMButton",controls)
	bt:SetText("View Lightmap Atlas")
	bt:AddCallback("OnPressed",function()
		pfm.util.open_lightmap_atlas_view_window(entActor,function(windowHandle,contents,controls)
			actionData.windowHandle = windowHandle
		end)
	end)
	return bt
end)
pfm.register_component_action("pfm_baked_lighting","pfm_bake_directional_lightmap","bake_directional_lightmap",function(controls,actorData,entActor,actionData)
	util.remove(actionData.baker)
	local el = gui.create("WIDirectionalLightmapBaker",controls)
	el:SetActor(actorData,entActor)
	actionData.baker = el
	return el
end)
pfm.register_component_action("pfm_baked_lighting","pfm_view_directional_lightmap_atlas","view_directional_lightmap_atlas",function(controls,actorData,entActor,actionData)
	if(util.is_valid(actionData.windowHandle)) then actionData.windowHandle:Close() end
	util.remove(actionData.windowHandle)
	local bt = gui.create("WIPFMButton",controls)
	bt:SetText("View Directional Lightmap Atlas")
	bt:AddCallback("OnPressed",function()
		pfm.util.open_directional_lightmap_atlas_view_window(entActor,function(windowHandle,contents,controls)
			actionData.windowHandle = windowHandle
		end)
	end)
	return bt
end)

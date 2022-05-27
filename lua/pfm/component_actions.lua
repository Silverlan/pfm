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

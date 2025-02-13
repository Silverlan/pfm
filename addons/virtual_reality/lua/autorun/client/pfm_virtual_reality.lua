--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/util/viewer_camera.lua")

local function open_button_mapping_window()
	-- TODO: This is just a placeholder
	include("/gui/pfm/vr/mapping_diagram.lua")
	include("/gui/pfm/bake/base_baker.lua")
	pfm.util.open_simple_window("VR Controller Button Mappings", function(windowHandle, contents, controls)
		local el = gui.create("WIPFMVRMappingDiagram", contents)
		el:SetButtonMapping(gui.PfmVrMappingDiagram.BUTTON_STEAMVR_TRIGGER, "Start/Stop Recording")
		el:SetButtonMapping(gui.PfmVrMappingDiagram.BUTTON_APPLICATION_MENU, "Toggle First-Person")
		el:SetButtonMapping(gui.PfmVrMappingDiagram.BUTTON_A, "Toggle VR Tracking/Animation Playback")
		el:SetButtonMapping(gui.PfmVrMappingDiagram.BUTTON_STEAMVR_TOUCHPAD, "Change Timeline Position")
		el:SetButtonMapping(gui.PfmVrMappingDiagram.BUTTON_GRIP, "Reset Zero Pose")
		contents:SetAutoSizeToContents(true)
		time.create_simple_timer(0.1, function()
			if windowHandle:IsValid() then
				windowHandle:SetSize(contents:GetSize())
			end
		end)

		-- Keep a reference to the window somewhere
		tool.get_filmmaker().vrMappingDiagramWindow = windowHandle
	end)
end

local function align_vr_camera_to_character(entActor, entCam)
	local viewerCameraC = entCam:AddComponent(ents.COMPONENT_VIEWER_CAMERA)
	if viewerCameraC == nil then
		return
	end
	pfm.util.align_viewer_camera_to_head(entActor, viewerCameraC, 0, 0, 3)
	entCam:RemoveComponent(ents.COMPONENT_VIEWER_CAMERA)
end

local function set_vr_target(pm, targetActor)
	local actorEditor = pm:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end
	local filmClip = actorEditor:GetFilmClip()
	local hasVrManagerComponent = false
	local vrCameraActor
	if filmClip ~= nil then
		for _, actor in ipairs(filmClip:GetActorList()) do
			local c = actor:FindComponent("pfm_vr_manager")
			if c ~= nil then
				hasVrManagerComponent = true
			end

			c = actor:FindComponent("pfm_vr_camera")
			if c ~= nil then
				vrCameraActor = actor
			end
		end
	end
	if hasVrManagerComponent == false then
		local actorVrManager = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_MANAGER, {
			name = "vr_manager",
			collection = gui.PFMActorEditor.COLLECTION_VR,
		})
		open_button_mapping_window()
	end

	if vrCameraActor == nil then
		local actorVrCamera = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA, {
			name = "vr_camera",
			collection = gui.PFMActorEditor.COLLECTION_VR,
			updateActorComponents = false,
		})
		actorEditor:CreateNewActorComponent(actorVrCamera, "pfm_vr_camera", false)
		actorEditor:UpdateActorComponents(actorVrCamera)

		vrCameraActor = actorVrCamera
	end

	local entActor = targetActor:FindEntity()
	local entCam = vrCameraActor:FindEntity()
	if util.is_valid(entActor) and util.is_valid(entCam) then
		align_vr_camera_to_character(entActor, entCam)

		local camC = entCam:GetComponent(ents.COMPONENT_CAMERA)
		if camC ~= nil then
			camC:SetFOV(70)
		end
	end

	local cmd = pfm.create_command(
		"set_actor_property",
		vrCameraActor,
		"ec/pfm_vr_camera/targetActor",
		nil,
		ents.UniversalEntityReference(targetActor:GetUniqueId()),
		ents.MEMBER_TYPE_ENTITY
	)
	pfm.undoredo.push("set_vr_target", cmd)()
end

pfm.add_event_listener("OnFilmmakerLaunched", function(pm)
	pm:AddEventListener("PopulateActorContextMenu", function(pm, pContext, actor)
		local entActor = actor:FindEntity()
		if
			util.is_valid(entActor)
			and entActor:HasComponent(ents.COMPONENT_IK_SOLVER)
			and entActor:HasComponent("pfm_vr_manager") == false
		then
			local pItem, pSubMenu = pContext:FindSubMenuByName("motion_capture")
			if pItem == nil then
				pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_motion_capture"))
				pItem:SetName("motion_capture")
			end
			pSubMenu
				:AddItem(locale.get_text("virtual_reality"), function()
					set_vr_target(pm, actor)
				end)
				:SetName("add_vr_manager")
			pSubMenu:Update()
		end
	end)
end)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_vr_tracked_device")

pfm.register_log_category("pfm_vr")

local Component = util.register_class("ents.PFMVrManager", BaseEntityComponent)

Component:RegisterMember("IkTrackingEnabled", udm.TYPE_BOOLEAN, false, {
	onChange = function(self)
		self:UpdateIkTrackingState()
	end,
	flags = ents.ComponentInfo.MemberInfo.FLAG_HIDE_IN_INTERFACE_BIT,
}, bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))

include("recording.lua")

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_trackedDevices = {}
	self.m_trackedDeviceCallbacks = {}
	self:InitializeRecordingData()
end
function Component:GetTrackedDevices()
	return self.m_trackedDevices
end
function Component:UpdateIkTrackingState()
	self:BroadcastEvent(Component.EVENT_ON_IK_TRACKING_STATE_CHANGED, { self:IsIkTrackingEnabled() })
end
function Component:OnVrEventsUpdated() end
function Component:OnVrControllerTriggerStateChanged(vrC, axisId, state, axisState)
	if axisId == 0 and vrC:IsPrimaryController() then
		if state == ents.VRController.TRIGGER_STATE_TOUCH then
			self:SetPlaybackEnabled(true, vrC)
		elseif state == ents.VRController.TRIGGER_STATE_RELEASE then
			self:SetPlaybackEnabled(false)
		end
	end
end
function Component:SetPlaybackEnabled(enabled, vrC)
	self.m_playbackEnabled = enabled
	self.m_playbackController = vrC

	if enabled then
		self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	else
		self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	end

	-- We're using a timer here because this function is called during a GUI draw-call, and
	-- the playback state callbacks can cause changes to the GUI state (which is not
	-- allowed during a draw call)
	-- TODO: This is not a great solution
	time.create_simple_timer(0.0, function()
		local pm = tool.get_filmmaker()
		if util.is_valid(pm) then
			local playbackState = pm:GetPlaybackState()
			if enabled then
				playbackState:Play()
			else
				playbackState:Pause()
				playbackState:SetPlaybackSpeed(1.0)
			end
		end
	end)
end
function Component:OnTick()
	if self.m_playbackEnabled then
		if util.is_valid(self.m_playbackController) then
			local state = self.m_playbackController:GetControllerState()
			if state ~= nil then
				local pm = tool.get_filmmaker()
				if util.is_valid(pm) then
					local playbackState = pm:GetPlaybackState()
					playbackState:SetPlaybackSpeed(state.axis0.x)
				end
			end
		else
			self:SetPlaybackEnabled(false)
		end
	end
end
function Component:OnEntitySpawn()
	self.m_hmdC = self:AddEntityComponent("vr_hmd")
	if self.m_hmdC == nil then
		return
	end

	local hmdC = self.m_hmdC
	if hmdC ~= nil then
		hmdC:SetOwner(ents.get_local_player():GetEntity())
		self.m_cbOnTrackedDeviceAdded = hmdC:AddEventCallback(ents.VRHMD.EVENT_ON_TRACKED_DEVICE_ADDED, function(tdC)
			self:InitializeTrackedDevice(tdC)
		end)
		self.m_cbOnEventsUpdated = hmdC:AddEventCallback(ents.VRHMD.EVENT_ON_EVENTS_UPDATED, function(tdC)
			self:OnVrEventsUpdated()
		end)
		for _, tdC in pairs(hmdC:GetTrackedDevices()) do
			if tdC:IsValid() then
				self:InitializeTrackedDevice(tdC)
			end
		end
	end

	--[[local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		self.m_cbPopulateActorContextMenu = pm:AddCallback("PopulateActorContextMenu", function(pm, pContext, actor)
			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("virtual_reality"))

			pSubMenu:AddItem(locale.get_text("set_animation_target"), function()
				local entActor = actor:FindEntity()
				if entActor ~= nil then
					local entCam, c = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
					if c ~= nil then
						c:SetAnimationTarget(entActor)
					end
				end
			end)
			pSubMenu:AddItem(locale.get_text("clear_animation_target"), function()
				local entCam, c = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
				if c ~= nil then
					c:ClearAnimationTarget()
				end
			end)

			pSubMenu:Update()
		end)
	end]]

	console.run("vr_hide_primary_game_scene", "0")
end
function Component:GetHmd()
	return self.m_hmdC
end
function Component:InitializeVrController(pfmTdc)
	pfmTdc:SetManager(self)

	local tdC = pfmTdc:GetTrackedDevice()
	local vrC = util.is_valid(tdC) and tdC:GetEntity():GetComponent(ents.COMPONENT_VR_CONTROLLER) or nil
	if vrC == nil then
		return
	end
	local cb = vrC:AddEventCallback(ents.VRController.EVENT_ON_BUTTON_INPUT, function(buttonId, state)
		return self:OnVrControllerButtonInput(vrC, buttonId, state)
	end)
	table.insert(self.m_trackedDeviceCallbacks, cb)

	cb = vrC:AddEventCallback(ents.VRController.EVENT_ON_TRIGGER_STATE_CHANGED, function(axisId, state, axisState)
		return self:OnVrControllerTriggerStateChanged(vrC, axisId, state, axisState)
	end)
	table.insert(self.m_trackedDeviceCallbacks, cb)
end
function Component:GetPfmManager()
	local ent, c = ents.citerator(ents.COMPONENT_PFM_MANAGER)()
	return c
end
function Component:OnVrControllerButtonInput(vrC, buttonId, state)
	if buttonId == openvr.BUTTON_ID_AXIS1 then
		if state == input.STATE_PRESS then
			if self:IsRecording() then
				self:EndRecording()
			else
				self:StartRecording()
			end
		end
		return util.EVENT_REPLY_HANDLED
	elseif buttonId == openvr.BUTTON_ID_GRIP then
		if state == input.STATE_PRESS then
			self:LogInfo("Resetting zero pose...")
			openvr.reset_zero_pose(openvr.TRACKING_UNIVERSE_ORIGIN_SEATED)

			local hmdTdc = util.is_valid(self.m_hmdC)
					and self.m_hmdC:GetEntity():GetComponent(ents.COMPONENT_VR_TRACKED_DEVICE)
				or nil
			if hmdTdc ~= nil then
				local hmdDeviceId = hmdTdc:GetTrackedDeviceIndex()
				local curPose = openvr.get_raw_pose(hmdDeviceId)
				if curPose ~= nil then
					-- Resetting origin is already covered by reset_zero_pose,
					-- we only want to reset the rotation here
					curPose:SetOrigin(Vector())
					openvr.set_device_zero_pose(hmdDeviceId, curPose)
				end
			end
		end
		return util.EVENT_REPLY_HANDLED
	elseif buttonId == openvr.BUTTON_ID_A then
		if state == input.STATE_PRESS then
			self:SetVrCameraActive(not self:IsVrCameraActive())
		end
		return util.EVENT_REPLY_HANDLED
	elseif buttonId == openvr.BUTTON_ID_APPLICATION_MENU then
		if state == input.STATE_PRESS then
			self:SetPov(not self:IsPov())
		end
		return util.EVENT_REPLY_HANDLED
	end
end
function Component:IsPov()
	local ent, c = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
	if c == nil then
		return false
	end
	return c:IsPov()
end
function Component:SetPov(pov)
	local ent, c = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
	if c == nil then
		return
	end

	local actor = pfm.dereference(tostring(ent:GetUuid()))
	if actor == nil then
		return
	end
	local cmd = pfm.create_command("set_actor_property", actor, "ec/pfm_vr_camera/pov", nil, pov, udm.TYPE_BOOLEAN)
	cmd:Execute()
end
function Component:IsVrCameraActive()
	local ent, pfmVrCameraC = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
	if pfmVrCameraC == nil then
		return
	end
	local camC = pfmVrCameraC:GetEntityComponent(ents.COMPONENT_CAMERA)
	if camC == nil then
		return
	end
	local pm = tool.get_filmmaker()
	local vp = pm:GetViewport()
	local curSceneCam = vp:GetActiveCamera()
	if
		vp:IsSceneCamera()
		and util.is_valid(curSceneCam)
		and util.is_same_object(curSceneCam:GetEntity(), camC:GetEntity())
	then
		return true
	end
	return false
end
function Component:SetVrCameraActive(active)
	local ent, pfmVrCameraC = ents.citerator(ents.COMPONENT_PFM_VR_CAMERA)()
	if pfmVrCameraC == nil then
		return
	end
	local camC = pfmVrCameraC:GetEntityComponent(ents.COMPONENT_CAMERA)
	if camC == nil then
		return
	end
	local pm = tool.get_filmmaker()
	local vp = pm:GetViewport()
	if active then
		vp:SwitchToSceneCamera(camC)
	else
		vp:SwitchToWorkCamera()
	end
end
function Component:InitializeTrackedDevice(tdC)
	local serialNumber = tdC:GetSerialNumber()
	self:LogInfo("Initializing tracked device " .. tostring(serialNumber) .. "...")
	if serialNumber == nil then
		return
	end

	for ent, c in
		ents.citerator(
			ents.COMPONENT_PFM_VR_TRACKED_DEVICE,
			bit.bor(ents.ITERATOR_FILTER_DEFAULT, ents.ITERATOR_FILTER_BIT_PENDING)
		)
	do
		if c:GetSerialNumber() == serialNumber then
			self:LogInfo("Found tracked device as existing actor.")
			table.insert(self.m_trackedDevices, c)
			c:SetTrackedDevice(tdC)
			self:InitializeVrController(c)
			return
		end
	end

	local pm = tool.get_filmmaker()

	local filmClip = util.is_valid(pm) and pm:GetActiveFilmClip() or nil
	if filmClip == nil then
		return
	end
	for _, actor in ipairs(filmClip:GetActorList()) do
		local c = actor:FindComponent("pfm_vr_tracked_device")
		if c ~= nil and c:GetMemberValue("serialNumber") == serialNumber then
			self:LogInfo(
				"Actor exists for VR tracked device with serial number '"
					.. serialNumber
					.. "', but has no entity? Ignoring..."
			)
			return
		end
	end

	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) == false then
		return
	end

	self:LogInfo("No existing actor found for tracked device, creating new one...")
	local name
	local role = tdC:GetRole()
	if role == openvr.TRACKED_CONTROLLER_ROLE_LEFT_HAND then
		name = "vrc_left_hand"
	elseif role == openvr.TRACKED_CONTROLLER_ROLE_RIGHT_HAND then
		name = "vrc_right_hand"
	elseif role == openvr.TRACKED_CONTROLLER_ROLE_TREADMILL then
		name = "vrc_treadmill"
	elseif role == openvr.TRACKED_CONTROLLER_ROLE_STYLUS then
		name = "vrc_stylus"
	else
		name = tdC:GetDeviceType()
		if name ~= nil then
			name = "vrc_" .. name
		end
	end
	local actor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_TRACKED_DEVICE, {
		["updateActorComponents"] = false,
		["name"] = name,
	})
	local pfmTdc = (actor ~= nil) and actor:FindComponent("pfm_vr_tracked_device") or nil
	if pfmTdc == nil then
		return
	end
	pfmTdc:SetMemberValue("serialNumber", udm.TYPE_STRING, serialNumber)
	actorEditor:UpdateActorComponents(actor)

	local ent = actor:FindEntity()
	local pfmTdc = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PFM_VR_TRACKED_DEVICE) or nil
	if pfmTdc ~= nil then
		table.insert(self.m_trackedDevices, pfmTdc)
		pfmTdc:SetTrackedDevice(tdC)
		self:InitializeVrController(pfmTdc)
	end
end
function Component:OnRemove()
	util.remove(self.m_cbPopulateActorContextMenu)
	util.remove(self.m_cbOnTrackedDeviceAdded)
	util.remove(self.m_cbOnEventsUpdated)
	util.remove(self.m_trackedDevices)
	util.remove(self.m_trackedDeviceCallbacks)

	-- Restore defaults
	console.run("vr_hide_primary_game_scene", "1")
end
ents.register_component("pfm_vr_manager", Component, "vr", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
Component.EVENT_ON_IK_TRACKING_STATE_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_VR_MANAGER, "on_ik_tracking_state_changed")

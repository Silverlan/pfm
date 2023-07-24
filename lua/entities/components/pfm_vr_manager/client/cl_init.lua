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
		for _, tdC in pairs(hmdC:GetTrackedDevices()) do
			if tdC:IsValid() then
				self:InitializeTrackedDevice(tdC)
			end
		end
	end

	local pm = tool.get_filmmaker()
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
	end

	console.run("vr_hide_primary_game_scene", "0")
end
function Component:GetHmd()
	return self.m_hmdC
end
function Component:InitializeVrController(pfmTdc)
	local tdC = pfmTdc:GetTrackedDevice()
	local vrC = util.is_valid(tdC) and tdC:GetEntity():GetComponent(ents.COMPONENT_VR_CONTROLLER) or nil
	if vrC == nil then
		return
	end
	local cb = vrC:AddEventCallback(ents.VRController.EVENT_ON_BUTTON_INPUT, function(buttonId, state)
		return self:OnVrControllerButtonInput(vrC, buttonId, state)
	end)
	pfmTdc:SetManager(self)
	table.insert(self.m_trackedDeviceCallbacks, cb)
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
	end
end
function Component:InitializeTrackedDevice(tdC)
	local serialNumber = tdC:GetSerialNumber()
	pfm.log("Initializing tracked device " .. tostring(serialNumber) .. "...", pfm.LOG_CATEGORY_PFM_VR)
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
			pfm.log("Found tracked device as existing actor.", pfm.LOG_CATEGORY_PFM_VR)
			table.insert(self.m_trackedDevices, c)
			c:SetTrackedDevice(tdC)
			self:InitializeVrController(c)
			return
		end
	end

	local pm = tool.get_filmmaker()
	local actorEditor = util.is_valid(pm) and pm:GetActorEditor() or nil
	if util.is_valid(actorEditor) == false then
		return
	end
	pfm.log("No existing actor found for tracked device, creating new one...", pfm.LOG_CATEGORY_PFM_VR)
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
	util.remove(self.m_trackedDevices)
	util.remove(self.m_trackedDeviceCallbacks)

	-- Restore defaults
	console.run("vr_hide_primary_game_scene", "1")
end

--[[function vrp.BaseSceneManager:UpdatePovCamera()
	local entCam = self:GetActiveCamera()
	if(util.is_valid(entCam) == false) then return end
	local vrBody = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_VR_BODY)})()
	if(vrBody == nil) then return end
	local cc = entCam:GetComponent(ents.COMPONENT_POV_CAMERA)
	local vrBodyC = vrBody:GetComponent(ents.COMPONENT_VR_BODY)
	if(cc ~= nil) then
		local headBoneId = vrBodyC:GetHeadBoneId()
		local offset = math.Transform()
		if(headBoneId ~= nil) then
			offset = calc_pov_camera_offset(vrBody:GetModel(),vrBodyC:GetHeadBoneId())
			offset:SetOrigin(offset:GetOrigin() *vrBody:GetScale())
			offset:SetRotation(Quaternion())
		end

		local udmPov = self:GetConfigData():Get("cameras"):Get(self.m_activeCameraIdentifier):Get("pov")
		if(udmPov:IsValid()) then
			local relPose = udmPov:GetValue("relativePose",udm.TYPE_TRANSFORM) or math.Transform()
			offset = offset *relPose
		end

		pfm.log("Applying pov camera offset " .. tostring(offset),pfm.LOG_CATEGORY_VRP)
		cc:SetRelativePose(offset)
	end

	vrBodyC:SetPovCamera(cc)
end]]

function Component:TestX(ent)
	local hmdC = self:GetHmd()
	if util.is_valid(hmdC) == false then
		return
	end

	local ikC = ent:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikC == nil then
		return
	end
	for _, pfmTdC in ipairs(self.m_trackedDevices) do
		if pfmTdC:IsValid() and pfmTdC:GetSerialNumber() == "LHR-FFC9F940" then
			local idx = ikC:GetMemberIndex("control/ValveBiped.Bip01_L_Hand/position")
			if idx ~= nil then
				--print(pfmTdC:GetEntity():GetPos())

				local hmdPose = hmdC:GetReferencePose()
				local devPose = pfmTdC:GetTrackedDevice():GetDevicePose()
				local pose = hmdPose * devPose

				local drawInfo = debug.DrawInfo()
				drawInfo:SetDuration(0.05)

				--print(pose:GetOrigin())
				drawInfo:SetColor(util.Color.Red)
				debug.draw_line(pose:GetOrigin(), pose:GetOrigin() + pose:GetForward() * 10, drawInfo)
				drawInfo:SetColor(util.Color.Lime)
				debug.draw_line(pose:GetOrigin(), pose:GetOrigin() + pose:GetRight() * 10, drawInfo)
				drawInfo:SetColor(util.Color.Aqua)
				debug.draw_line(pose:GetOrigin(), pose:GetOrigin() + pose:GetUp() * 10, drawInfo)

				--pose = ikC:GetEntity():GetPose():GetInverse() * pose
				ikC:SetTransformMemberPos(idx, math.COORDINATE_SPACE_WORLD, pose:GetOrigin())
				--ikC:SetTransformMemberRot(idx, math.COORDINATE_SPACE_WORLD, pose:GetRotation())

				--[[local hmdPose = hmdC:GetReferencePose()
				hmdPose = hmdPose:Copy()
			
				local ent = ents.get_local_player():GetEntity():GetComponent(ents.COMPONENT_CHARACTER)
			
				local ang = rot:ToEulerAngles()
			
				pos.z = pos.z
				pos.y = pos.y
				rot = EulerAngles(0, 180, 0):ToQuaternion() * EulerAngles(-ang.p, ang.y, -ang.r):ToQuaternion() --ctrlPose:GetRotation()
				local ctrlPose = math.Transform(pos, rot)
				ctrlPose = hmdPose * ctrlPose]]

				--ikC:SetTransformMemberPos(idx, math.COORDINATE_SPACE_WORLD, Vector(18.8134, 44.2499, 70.8808))
			end
		end
	end
	--[[
	if(ikC ~= nil) then

	end
	]]
	--[[
	if idx ~= nil then
		
	end]]

	--[[local pose = self:CalcBaseCameraPose()
	if(pose == nil) then return end
	pose = pose *self.m_relPose
	if(self.m_staticRotation ~= nil) then pose:SetRotation(self.m_staticRotation) end
	self:GetEntity():SetPose(pose)

	local animC = self.m_target.entity:GetAnimatedComponent()
	if(self.m_target.neckBoneId ~= nil) then animC:SetBoneScale(self.m_target.neckBoneId,BONE_ZERO_SCALE) end -- Hide the neck
	if(self.m_target.headBoneId ~= nil) then animC:SetBoneScale(self.m_target.headBoneId,BONE_ZERO_SCALE) end -- Hide the head
	]]
end
ents.COMPONENT_PFM_VR_MANAGER = ents.register_component("pfm_vr_manager", Component)
Component.EVENT_ON_IK_TRACKING_STATE_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_VR_MANAGER, "on_ik_tracking_state_changed")

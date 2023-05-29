--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_vr_tracked_device")

pfm.register_log_category("pfm_vr")

local Component = util.register_class("ents.PFMVrManager", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_trackedDevices = {}
end
function Component:OnEntitySpawn()
	local entHmd = ents.create("vr_hmd")
	if entHmd == nil then
		return
	end
	entHmd:Spawn()
	self.m_entHmd = entHmd

	local hmdC = entHmd:GetComponent(ents.COMPONENT_VR_HMD)
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
					self:SetAnimationTarget(entActor)
				end
			end)

			pSubMenu:Update()
		end)
	end

	console.run("vr_hide_primary_game_scene", "0")
end
function Component:GetHmd()
	if util.is_valid(self.m_entHmd) == false then
		return
	end
	return self.m_entHmd:GetComponent(ents.COMPONENT_VR_HMD)
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
	end
end
function Component:OnRemove()
	util.remove(self.m_entHmd)
	util.remove(self.m_cbPopulateActorContextMenu)
	util.remove(self.m_cbUpdateCameraPose)
	util.remove(self.m_cbOnTrackedDeviceAdded)
	util.remove(self.m_trackedDevices)

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

function Component:SetAnimationTarget(ent)
	local pm = tool.get_filmmaker()
	local vm = pm:GetViewport()
	vm:SwitchToWorkCamera()
	local cam = vm:GetWorkCamera()
	local entCam = cam:GetEntity()
	local povC = entCam:AddComponent("pov_camera")

	local headData = util.rig.determine_head_bones(ent:GetModel())
	if headData == nil or headData.headBoneId == nil then
		return
	end
	--if(headData == nil or headData.headBoneId == nil or headData.headBoneId == -1 or headData.headParentBoneId == nil or headData.headParentBoneId == -1) then return false end

	console.print_table(headData)
	povC:SetHeadEntity(ent, headData.headBoneId, nil, headData.headBoneId)

	game.clear_gameplay_control_camera()

	util.remove(self.m_cbUpdateCameraPose)
	self.m_cbUpdateCameraPose = game.add_callback("Think", function()
		povC:UpdateCameraPose()
	end)

	local vrBodyC = ent:AddComponent("vr_body")

	if headData.headBoneId ~= -1 then
		vrBodyC:SetHeadBone(headData.headBoneId)
	end

	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local armChain = {
		skeleton:LookupBone("Bind_LeftShoulder"),
		skeleton:LookupBone("Bind_LeftArm"),
		skeleton:LookupBone("Bind_LeftForeArm"),
		skeleton:LookupBone("Bind_LeftHand"),
	}
	vrBodyC:SetLeftArm(armChain)

	ent:PlayAnimation("reference")
	--[[16 = Bone[Name:Bind_LeftShoulder][Id:][Children:1][Parent:Bind_Spine2]
	17 = Bone[Name:Bind_LeftArm][Id:][Children:1][Parent:Bind_LeftShoulder]
	18 = Bone[Name:Bind_LeftForeArm][Id:][Children:1][Parent:Bind_LeftArm]
	19 = Bone[Name:Bind_LeftHand][Id:][Children:5][Parent:Bind_LeftForeArm]]

	vrBodyC:SetHmd(self.m_entHmd:GetComponent(ents.COMPONENT_VR_HMD))
	--[[if(#upperBodyBoneChain > 2) then vrBody:SetUpperBody(upperBodyBoneChain) end
	if(#leftArmBoneChain > 2) then vrBody:SetLeftArm(leftArmBoneChain) end
	if(#rightArmBoneChain > 2) then vrBody:SetRightArm(rightArmBoneChain) end
	if(headBone ~= -1) then vrBody:SetHeadBone(headBone) end

	vrBody:SetHmd(entHmd:GetComponent(ents.COMPONENT_VR_HMD))]]

	--function Component:SetHeadEntity(actor,headBoneId,neckBoneId,targetBoneId)

	--function Component:SetHeadBone(boneId)
	--[[local entCam = self:GetActiveCamera()
	if(util.is_valid(entCam) == false) then return end
	local vrBody = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_VR_BODY)})()
	if(vrBody == nil) then return end
	local cc = entCam:GetComponent(ents.COMPONENT_POV_CAMERA)]]
	--[[if(util.is_valid(self.m_entVrBody) == false) then
		self.m_entVrBody = 
	end

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

	vrBodyC:SetPovCamera(cc)]]
end
ents.COMPONENT_PFM_VR_MANAGER = ents.register_component("pfm_vr_manager", Component)

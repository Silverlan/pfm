--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVRCamera", BaseEntityComponent)

Component:RegisterMember("TargetActor", ents.MEMBER_TYPE_ENTITY, "", {
	onChange = function(c)
		c:UpdateTargetActor()
	end,
})

local g_vrModuleLoaded = false
local g_vrModuleReady = false
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_camera")
	if g_vrModuleLoaded == false then -- Lazy initialization
		g_vrModuleLoaded = true
		if pfm.util.init_openvr() == false then
			return
		end

		debug.start_profiling_task("vr_initialize_openvr")
		local result = openvr.initialize()
		debug.stop_profiling_task()
		if result ~= openvr.INIT_ERROR_NONE then
			console.print_warning("Unable to initialize openvr library: " .. openvr.init_error_to_string(result))
			return
		end
		g_vrModuleReady = true
	end
	if g_vrModuleReady ~= true then
		return
	end
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "OnTurnOff")
	self:BindEvent(ents.PFMCamera.EVENT_ON_ACTIVE_STATE_CHANGED, "OnActiveStateChanged")

	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC == nil or toggleC:IsTurnedOn() then
		self:OnTurnOn()
	end
end
function Component:OnActiveStateChanged(active)
	if ents.COMPONENT_PFM_VR_MANAGER ~= nil then
		local entManager, managerC = ents.citerator(ents.COMPONENT_PFM_VR_MANAGER)()
		if managerC ~= nil then
			managerC:SetIkTrackingEnabled(active)
		end
	end
	local povC = self:GetEntity():AddComponent("pov_camera")
	if povC ~= nil then
		povC:SetEnabled(active)
	end
	if util.is_valid(self.m_vrBodyC) then
		self.m_vrBodyC:SetEnabled(active)
	end
end
function Component:UpdateTargetActor()
	local targetActor = self:GetTargetActor()
	if util.is_valid(targetActor) then
		self:SetAnimationTarget(targetActor)
	else
		self:ClearAnimationTarget()
	end
end
function Component:ClearAnimationTarget()
	util.remove(self.m_cbUpdateCameraPose)

	local povC = self:GetEntity():AddComponent("pov_camera")
	if povC ~= nil then
		povC:SetEnabled(false)
	end
	if util.is_valid(self.m_vrBodyC) then
		self.m_vrBodyC:SetEnabled(false)
	end
	if util.is_valid(self.m_animationTarget) then
		self.m_animationTarget:RemoveComponent("vr_body")
	end
end

function Component:SetAnimationTarget(ent)
	self:ClearAnimationTarget()

	local cam = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if cam == nil then
		return
	end
	local povC = self:GetEntity():AddComponent("pov_camera")
	povC:SetEnabled(true)

	self.m_animationTarget = ent

	local headData = util.rig.determine_head_bones(ent:GetModel())
	if headData == nil or headData.headBoneId == nil then
		pfm.log(
			"Failed to determine head bone for VR animation target '" .. tostring(ent) .. "'!",
			pfm.LOG_CATEGORY_PFM_VR,
			pfm.LOG_CATEGORY_ERROR
		)
		return
	end
	--if(headData == nil or headData.headBoneId == nil or headData.headBoneId == -1 or headData.headParentBoneId == nil or headData.headParentBoneId == -1) then return false end

	console.print_table(headData)
	povC:SetHeadEntity(ent, headData.headBoneId, nil, headData.headBoneId)

	-- game.clear_gameplay_control_camera()

	self.m_cbUpdateCameraPose = game.add_callback("Think", function()
		povC:UpdateCameraPose()
		-- self:TestX(ent)
	end)

	local vrBodyC = ent:AddComponent("vr_body")
	vrBodyC:SetEnabled(true)
	self.m_vrBodyC = vrBodyC

	-- TEST
	if headData.headBoneId ~= -1 then
		vrBodyC:SetHeadBone(headData.headBoneId)
	end

	--[[local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local armChain = {
		skeleton:LookupBone("Bind_LeftShoulder"),
		skeleton:LookupBone("Bind_LeftArm"),
		skeleton:LookupBone("Bind_LeftForeArm"),
		skeleton:LookupBone("Bind_LeftHand"),
	}
	vrBodyC:SetLeftArm(armChain)]]
	-- TEST

	ent:PlayAnimation("reference")

	local entHmd, hmdC = ents.citerator(ents.COMPONENT_VR_HMD)()
	if hmdC ~= nil then
		vrBodyC:SetHmd(hmdC)
	end
	--[[16 = Bone[Name:Bind_LeftShoulder][Id:][Children:1][Parent:Bind_Spine2]
	17 = Bone[Name:Bind_LeftArm][Id:][Children:1][Parent:Bind_LeftShoulder]
	18 = Bone[Name:Bind_LeftForeArm][Id:][Children:1][Parent:Bind_LeftArm]
	19 = Bone[Name:Bind_LeftHand][Id:][Children:5][Parent:Bind_LeftForeArm]]

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
function Component:OnRemove()
	self:ClearAnimationTarget()
	self:OnTurnOff()
end
function Component:OnTurnOn()
	if util.is_valid(self.m_cbRenderScene) then
		return
	end
	self.m_cbRenderScene = game.add_callback("PreRenderScenes", function()
		self:RenderVRView()
	end)
end
function Component:OnTurnOff()
	if util.is_valid(self.m_cbRenderScene) then
		self.m_cbRenderScene:Remove()
	end
end
function Component:RenderVRView()
	local cam = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if cam == nil then
		return
	end
	cam:UpdateViewMatrix()

	local poseMatrix = openvr.get_pose_matrix()

	local eyeIds = { openvr.EYE_LEFT, openvr.EYE_RIGHT }
	for _, eyeId in ipairs(eyeIds) do
		local eye = openvr.get_eye(eyeId)
		local rt = eye:GetRenderTarget()
		local camEye = eye:GetCamera()
		camEye:SetViewMatrix(cam:GetViewMatrix())

		local scene = eye:GetScene()
		local mViewCam = camEye:GetViewMatrix()
		local mView = poseMatrix * eye:GetViewMatrix(camEye)
		-- mView:Translate(Vector(-400,0,-50))
		local mProjection = eye:GetProjectionMatrix(camEye:GetNearZ(), camEye:GetFarZ())
		camEye:SetViewMatrix(mView)

		-- TODO: Clean this up!
		local _vr_pos = camEye:GetEntity():GetPos()
		local _vr_rot = camEye:GetEntity():GetRotation()

		camEye:SetProjectionMatrix(mProjection)

		local drawCmd, fence = openvr.start_recording()
		if drawCmd ~= nil then
			local drawSceneInfo = game.DrawSceneInfo()
			drawSceneInfo.scene = scene
			drawSceneInfo.commandBuffer = drawCmd
			drawSceneInfo.renderFlags = bit.band(game.RENDER_FLAG_ALL, bit.bnot(game.RENDER_FLAG_BIT_VIEW))
			drawSceneInfo.clearColor = Color.Black

			local img = rt:GetTexture():GetImage()
			drawCmd:RecordImageBarrier(
				img,
				prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
			)
			game.draw_scene(drawSceneInfo, img)
			drawCmd:RecordImageBarrier(
				img,
				prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
				prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
			)

			openvr.stop_recording()
		end

		-- Reset old view matrix
		camEye:SetViewMatrix(mViewCam)
	end

	for _, eyeId in ipairs(eyeIds) do
		local result = openvr.submit_eye(eyeId)
		if result ~= openvr.COMPOSITOR_ERROR_NONE then
			console.print_warning("Unable to submit eye " .. eyeId .. ": " .. openvr.compositor_error_to_string(result))
		end
	end

	openvr.update_poses()
end
function Component:Setup(animSet, cameraData)
	--[[self.m_cameraData = cameraData
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if camC ~= nil then
		camC:SetNearZ(cameraData:GetZNear())
		camC:SetFarZ(cameraData:GetZFar())
		camC:SetFOV(cameraData:GetFov())
		camC:UpdateProjectionMatrix()
	end]]
end
ents.COMPONENT_PFM_VR_CAMERA = ents.register_component("pfm_vr_camera", Component)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMVRCamera",BaseEntityComponent)

local g_vrModuleLoaded = false
local g_vrModuleReady = false
function ents.PFMVRCamera:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_camera")

	if(g_vrModuleLoaded == false) then -- Lazy initialization
		g_vrModuleLoaded = true
		local r = engine.load_library("openvr/pr_openvr")
		if(r ~= true) then
			console.print_warning("Unable to load openvr module: " .. r)
			return
		end

		local result = openvr.initialize()
		if(result ~= openvr.INIT_ERROR_NONE) then
			console.print_warning("Unable to initialize openvr library: " .. openvr.init_error_to_string(result))
			return
		end
		g_vrModuleReady = true
	end
	if(g_vrModuleReady ~= true) then return end
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON,"OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF,"OnTurnOff")

	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC == nil or toggleC:IsTurnedOn()) then self:OnTurnOn() end
end
function ents.PFMVRCamera:OnRemove()
	self:OnTurnOff()
end
function ents.PFMVRCamera:OnTurnOn()
	if(util.is_valid(self.m_cbRenderScene)) then return end
	self.m_cbRenderScene = game.add_callback("PreRenderScenes",function()
		self:RenderVRView()
	end)
end
function ents.PFMVRCamera:OnTurnOff()
	if(util.is_valid(self.m_cbRenderScene)) then self.m_cbRenderScene:Remove() end
end
function ents.PFMVRCamera:RenderVRView()
	local cam = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(cam == nil) then return end
	cam:UpdateViewMatrix()

	local poseMatrix = openvr.get_pose_matrix()

	local eyeIds = {openvr.EYE_LEFT,openvr.EYE_RIGHT}
	for _,eyeId in ipairs(eyeIds) do
		local eye = openvr.get_eye(eyeId)
		local rt = eye:GetRenderTarget()
		local camEye = eye:GetCamera()
		camEye:SetViewMatrix(cam:GetViewMatrix())

		local scene = eye:GetScene()
		local mViewCam = camEye:GetViewMatrix()
		local mView = poseMatrix *eye:GetViewMatrix(camEye)
		-- mView:Translate(Vector(-400,0,-50))
		local mProjection = eye:GetProjectionMatrix(camEye:GetNearZ(),camEye:GetFarZ())
		camEye:SetViewMatrix(mView)

		-- TODO: Clean this up!
		_vr_pos = camEye:GetEntity():GetPos()
		_vr_rot = camEye:GetEntity():GetRotation()

		camEye:SetProjectionMatrix(mProjection)

		local drawCmd,fence = openvr.start_recording()
		if(drawCmd ~= nil) then
			local drawSceneInfo = game.DrawSceneInfo()
			drawSceneInfo.scene = scene
			drawSceneInfo.commandBuffer = drawCmd
			drawSceneInfo.renderFlags = bit.band(game.RENDER_FLAG_ALL,bit.bnot(game.RENDER_FLAG_BIT_VIEW))
			drawSceneInfo.clearColor = Color.Black

			local img = rt:GetTexture():GetImage()
			drawCmd:RecordImageBarrier(img,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
			game.draw_scene(drawSceneInfo,img)
			drawCmd:RecordImageBarrier(img,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)

			openvr.stop_recording()
		end

		-- Reset old view matrix
		camEye:SetViewMatrix(mViewCam)
	end

	for _,eyeId in ipairs(eyeIds) do
		local result = openvr.submit_eye(eyeId)
		if(result ~= openvr.COMPOSITOR_ERROR_NONE) then
			console.print_warning("Unable to submit eye " .. eyeId .. ": " .. openvr.compositor_error_to_string(result))
		end
	end

	openvr.update_poses()
end
function ents.PFMVRCamera:Setup(animSet,cameraData)
	self.m_cameraData = cameraData
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(camC ~= nil) then
		camC:SetNearZ(cameraData:GetZNear())
		camC:SetFarZ(cameraData:GetZFar())
		camC:SetFOV(cameraData:GetFov())
		camC:UpdateProjectionMatrix()
	end
end
ents.COMPONENT_PFM_VR_CAMERA = ents.register_component("pfm_vr_camera",ents.PFMVRCamera)

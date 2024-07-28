--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK = 0
gui.PFMCoreViewportBase.CAMERA_MODE_FLY = 1
gui.PFMCoreViewportBase.CAMERA_MODE_WALK = 2
gui.PFMCoreViewportBase.CAMERA_MODE_COUNT = 3

gui.PFMCoreViewportBase.CAMERA_VIEW_GAME = 0
gui.PFMCoreViewportBase.CAMERA_VIEW_SCENE = 1

function gui.PFMCoreViewportBase:GetCamera()
	return self.m_viewport:GetCamera()
end
function gui.PFMCoreViewportBase:GetAspectRatio()
	return util.is_valid(self.m_aspectRatioWrapper) and self.m_aspectRatioWrapper:GetAspectRatio() or 1.0
end
function gui.PFMCoreViewportBase:GetAspectRatioProperty()
	return util.is_valid(self.m_aspectRatioWrapper) and self.m_aspectRatioWrapper:GetAspectRatioProperty() or nil
end
function gui.PFMCoreViewportBase:SetCameraMode(camMode)
	pfm.log(
		"Changing camera mode to "
			.. (
				(camMode == gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK and "playback")
				or (camMode == gui.PFMCoreViewportBase.CAMERA_MODE_FLY and "fly")
				or "walk"
			)
	)
	self.m_cameraMode = camMode

	-- ents.PFMCamera.set_camera_enabled(camMode == gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK)
	local rtUpdateEnabled = (camMode ~= gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK)
	if rtUpdateEnabled then
		self.m_camStartPose = math.Transform()
		local cam = game.get_render_scene_camera()
		if util.is_valid(cam) then
			local entCam = cam:GetEntity()
			self.m_camStartPose:SetOrigin(entCam:GetPos())
			self.m_camStartPose:SetRotation(entCam:GetRotation())
		end
	else
		self.m_camStartPose = nil
	end
	self:UpdateThinkState()

	-- We need to notify the server to change the player's movement mode (i.e. noclip/walk)
	local packet = net.Packet()
	packet:WriteUInt8(camMode)
	local cam = game.get_render_scene_camera()
	if cam ~= nil then
		packet:WriteBool(true)
		packet:WriteVector(cam:GetEntity():GetPos())
		packet:WriteQuaternion(cam:GetEntity():GetRotation())
	else
		packet:WriteBool(false)
	end
	net.send(net.PROTOCOL_SLOW_RELIABLE, "sv_pfm_camera_mode", packet)
end
function gui.PFMCoreViewportBase:GetActiveCamera()
	local scene = util.is_valid(self.m_viewport) and self.m_viewport:GetScene()
	return (scene ~= nil) and scene:GetActiveCamera() or nil
end
function gui.PFMCoreViewportBase:InitializeCameraControls()
	local controls = gui.create("WIHBox", self.m_controls)
	controls:SetName("cc_controls")

	self.m_btAutoAim = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_viewport_autoaim",
		"gui/pfm/icon_viewport_autoaim_activated",
		function()
			print("TODO")
		end
	)
	self.m_btCamera = gui.PFMButton.create(
		controls,
		"gui/pfm/icon_cp_camera",
		"gui/pfm/icon_cp_camera_activated",
		function()
			self:ToggleCamera()
		end
	)
	self.m_btCamera:SetName("cc_camera")
	self.m_btCamera:SetupContextMenu(function(pContext)
		local sceneCamera = self:IsSceneCamera()
		local camName = sceneCamera and locale.get_text("pfm_scene_camera") or locale.get_text("pfm_work_camera")
		pContext:AddItem(locale.get_text("pfm_switch_to_camera", { camName }), function()
			self:ToggleCamera()
		end)
		pContext:AddItem(locale.get_text("pfm_switch_to_gameplay"), function()
			self:SwitchToGameplay()
		end)
		pContext:AddItem(locale.get_text("pfm_copy_to_camera", { camName }), function() end) -- TODO

		pContext:AddLine()

		local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_change_scene_camera"))
		local pm = pfm.get_project_manager()
		local session = (pm ~= nil) and pm:GetSession() or nil
		local filmClip = (session ~= nil) and session:FindClipAtTimeOffset(pm:GetTimeOffset()) or nil
		if filmClip ~= nil then
			local actorList = filmClip:GetActorList()
			for _, actor in ipairs(actorList) do
				local camC = actor:FindComponent("camera")
				if camC ~= nil then
					pSubMenu:AddItem(actor:GetName(), function()
						filmClip:SetCamera(actor)
					end)
				end
			end
		end

		-- pSubMenu:AddItem(locale.get_text("pfm_new_camera"),function() end) -- TODO
		pSubMenu:AddLine()
		-- TODO: Add all available cameras
		pSubMenu:Update()

		pContext:AddLine()

		if sceneCamera then
			pContext:AddItem(locale.get_text("pfm_select_actor"), function()
				local camC = ents.PFMCamera.get_active_camera()
				local actorC = (camC ~= nil) and camC:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
				if actorC == nil then
					return
				end
				local actor = actorC:GetActorData()
				pfm.get_project_manager():SelectActor(actor)
			end)

			pContext:AddLine()

			pContext:AddItem(locale.get_text("pfm_show_camera_in_element_viewer"), function()
				local camC = ents.PFMCamera.get_active_camera()
				if util.is_valid(camC) == false then
					return
				end
				pfm.get_project_manager():ShowInElementViewer(camC:GetCameraData())
			end)
		end
		pContext:AddItem(locale.get_text("pfm_auto_aim_work_camera"), function() end) -- TODO
	end)
	self:SwitchToSceneCamera()
	self.m_btGear = gui.PFMButton.create(controls, "gui/pfm/icon_gear", "gui/pfm/icon_gear_activated", function()
		print("TODO")
	end)
	self.m_btGear:SetName("cc_options")
	controls:SetHeight(self.m_btAutoAim:GetHeight())
	controls:Update()
	controls:SetX(self.m_controls:GetWidth() - controls:GetWidth() - 3)
	controls:SetAnchor(1, 1, 1, 1)
	self.manipulatorControls = controls
end
function gui.PFMCoreViewportBase:IsGameplayEnabled()
	return self.m_gameplayEnabled
end
function gui.PFMCoreViewportBase:IsInCameraControlMode()
	return self.m_inCameraControlMode
end
function gui.PFMCoreViewportBase:SetGameplayMode(enabled)
	input.set_binding_layer_enabled("pfm_viewport", enabled)
	input.update_effective_input_bindings()

	if enabled then
		self.m_oldCursorPos = input.get_cursor_pos()
		if self:IsGameplayEnabled() == false then
			self:SetCameraMode(gui.PFMCoreViewportBase.CAMERA_MODE_FLY)
		end
		input.center_cursor()

		local window = self:GetRootWindow()
		gui.set_focus_enabled(window, false)

		-- filmmaker:TrapFocus(false)
		-- filmmaker:KillFocus()
		pfm.tag_render_scene_as_dirty(true)

		self.m_oldInputLayerStates = {}
		local inputLayers = pfm.get_project_manager():GetInputBindingLayers()
		for id, layer in pairs(inputLayers) do
			if id ~= "pfm_viewport" then
				self.m_oldInputLayerStates[id] = input.is_binding_layer_enabled(id)
				input.set_binding_layer_enabled(id, false)
			end
		end
		input.update_effective_input_bindings()

		self.m_inCameraControlMode = true
		self:UpdateWorkCamera()
	else
		if self.m_inCameraLinkMode then
			self.m_inCameraLinkMode = nil
			local workPose = self.m_cameraLinkModeWorkPose
			self.m_cameraLinkModeWorkPose = nil

			local filmmaker = pfm.get_project_manager()
			local actorEditor = filmmaker:GetActorEditor()
			local actor = self:GetSceneCameraActorData()
			local newActorPose = self:GetWorkCamera():GetEntity():GetPose()
			if actor ~= nil and util.is_valid(actorEditor) then
				actorEditor:ToggleCameraLink(actor)
				self:SwitchToSceneCamera()
			end

			if workPose ~= nil then
				if actor ~= nil then
					-- TODO: This doesn't work properly
					--[[local oldPos = self.m_cameraLinkOriginalActorPose:GetOrigin()
					local newPos = newActorPose:GetOrigin()
					local oldRot = self.m_cameraLinkOriginalActorPose:GetRotation()
					local newRot = newActorPose:GetRotation()
					local pm = pfm.get_project_manager()
					if newPos:Equals(oldPos) == false then
						debug.print(oldPos, newPos)
						pm:ChangeActorPropertyValue(
							actor,
							"ec/pfm_actor/position",
							udm.TYPE_VECTOR3,
							oldPos,
							newPos,
							nil,
							true
						)
					end
					if newRot:Equals(oldRot) == false then
						pm:ChangeActorPropertyValue(
							actor,
							"ec/pfm_actor/rotation",
							udm.TYPE_QUATERNION,
							oldRot,
							newRot,
							nil,
							true
						)
					end]]
					-- TODO: Update fov
				end
				self:SetWorkCameraPose(workPose)
			end
		end
		if self:IsGameplayEnabled() == false then
			self:SetCameraMode(gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK)
		end

		local window = self:GetRootWindow()
		gui.set_focus_enabled(window, true)

		local filmmaker = pfm.get_project_manager()
		-- filmmaker:TrapFocus(true)
		-- filmmaker:RequestFocus()
		pfm.tag_render_scene_as_dirty(false)
		input.set_cursor_pos(self.m_oldCursorPos)

		local pl = ents.get_local_player()
		local actionInputC = util.is_valid(pl) and pl:GetEntity():GetComponent(ents.COMPONENT_ACTION_INPUT_CONTROLLER)
			or nil
		if actionInputC ~= nil then
			-- Cancel all action inputs
			local i = 1
			while i <= input.ACTION_LAST do
				actionInputC:SetActionInput(i, false)
				i = bit.lshift(i, 1)
			end
		end
		if self.m_oldInputLayerStates ~= nil then
			for id, state in pairs(self.m_oldInputLayerStates) do
				input.set_binding_layer_enabled(id, state)
			end
			self.m_oldInputLayerStates = nil
			input.update_effective_input_bindings()
		end

		self.m_inCameraControlMode = false
	end
	self:CallCallbacks("OnGameplayModeChanged", enabled)
end
function gui.PFMCoreViewportBase:SwitchToGameplay(enabled)
	if enabled == nil then
		enabled = true
	end
	if enabled == self.m_gameplayEnabled then
		return
	end
	self.m_gameplayEnabled = enabled

	local pl = ents.get_local_player()
	if enabled then
		self:SwitchToWorkCamera(true)
		self:SetCameraMode(gui.PFMCoreViewportBase.CAMERA_MODE_WALK)
	else
		self:SetCameraMode(gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK)
	end
end
function gui.PFMCoreViewportBase:GetWorkCamera()
	if self.m_viewport:IsPrimaryGameSceneViewport() then
		return game.get_primary_camera()
	end
	return self.m_viewport:GetSceneCamera()
end
function gui.PFMCoreViewportBase:GetSceneCamera()
	local filmClip = pfm.get_project_manager():GetActiveGameViewFilmClip()
	local actor = (filmClip ~= nil) and filmClip:GetCamera() or nil
	local ent = (actor ~= nil) and actor:FindEntity() or nil
	if util.is_valid(ent) == false then
		return
	end
	return ent:GetComponent(ents.COMPONENT_CAMERA)
end
function gui.PFMCoreViewportBase:GetSceneCameraActorData()
	local cam = self:GetSceneCamera()
	local actorC = util.is_valid(cam) and cam:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
	return (actorC ~= nil) and actorC:GetActorData() or nil
end
function gui.PFMCoreViewportBase:SwitchToCamera(cam)
	local scene = self.m_viewport:GetScene()
	if util.is_valid(scene) then
		local curCam = scene:GetActiveCamera()
		local pfmCamC = util.is_valid(curCam) and curCam:GetEntity():GetComponent(ents.COMPONENT_PFM_CAMERA) or nil
		if pfmCamC ~= nil then
			pfmCamC:BroadcastEvent(ents.PFMCamera.EVENT_ON_ACTIVE_STATE_CHANGED, { false })
		end
		scene:SetActiveCamera(cam)

		cam:SetAspectRatio(self.m_aspectRatioWrapper:GetAspectRatio())
		cam:UpdateMatrices()

		local pfmCamC = cam:GetEntity():GetComponent(ents.COMPONENT_PFM_CAMERA)
		if pfmCamC ~= nil then
			pfmCamC:BroadcastEvent(ents.PFMCamera.EVENT_ON_ACTIVE_STATE_CHANGED, { true })
		end
	end
	pfm.tag_render_scene_as_dirty()
end
function gui.PFMCoreViewportBase:RefreshCamera()
	if self:IsSceneCamera() then
		self:SwitchToSceneCamera()
	else
		self:SwitchToWorkCamera()
	end
end
function gui.PFMCoreViewportBase:SetCameraView(cameraView)
	if self:IsWorkCamera() then
		local pm = pfm.get_project_manager()
		if pm:IsEditor() then
			pm:UpdateWorkCamera(cameraView)
		end
	end
	self.m_cameraView = cameraView
end
function gui.PFMCoreViewportBase:GetCameraView()
	return self.m_cameraView
end
function gui.PFMCoreViewportBase:SwitchToSceneCamera()
	self:SwitchToGameplay(false)
	local cam = self:GetSceneCamera()
	if util.is_valid(cam) then
		self:SwitchToCamera(cam)
		local name = cam:GetEntity():GetName()
		if #name == 0 then
			name = locale.get_text("pfm_scene_camera")
		end
		if util.is_valid(self.m_btCamera) then
			self.m_btCamera:SetText(name)
		end

		self:SetCameraView(gui.PFMCoreViewportBase.CAMERA_VIEW_SCENE)
		game.clear_gameplay_control_camera()
	end
	--[[self:SwitchToGameplay(false)
	local camScene = ents.PFMCamera.get_active_camera()
	local camName = ""
	if(util.is_valid(camScene)) then
		local camData = camScene:GetCameraData()
		if(util.is_valid(self.m_btCamera)) then camName = camData:GetActor():GetName() end
	end
	if(#camName == 0) then camName = locale.get_text("pfm_scene_camera") end
	self.m_btCamera:SetText(camName)
	ents.PFMCamera.set_camera_enabled(true)

	local scene = self.m_viewport:GetScene()
	if(util.is_valid(scene)) then
		local c = ents.get_by_local_index(31):GetComponent(ents.COMPONENT_CAMERA)
		scene:SetActiveCamera(c)
	end]]
end
function gui.PFMCoreViewportBase:UpdateWorkCamera()
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) == false then
		return
	end
	local pose = cam:GetEntity():GetPose()
	self:SetWorkCameraPose(pose)
	game.set_gameplay_control_camera(cam)
end
function gui.PFMCoreViewportBase:SetWorkCameraPose(pose)
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) == false then
		return
	end
	local pos = pose:GetOrigin()
	local ang = pose:GetRotation():ToEulerAngles()
	local pl = ents.get_local_player()
	cam:GetEntity():SetPose(math.Transform(pos, ang))
	if util.is_valid(pl) then
		local observableC = pl:GetEntity():GetComponent(ents.COMPONENT_OBSERVABLE) or nil
		if observableC ~= nil then
			pos = pos - observableC:GetViewOffset()
		end
	end
	console.run("setpos", tostring(pos.x), tostring(pos.y), tostring(pos.z))
	console.run("setang", tostring(ang.p), tostring(ang.y), 0.0)
end
function gui.PFMCoreViewportBase:GetWorkCameraPose()
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) == false then
		return
	end
	return cam:GetEntity():GetPose()
end
function gui.PFMCoreViewportBase:SwitchToWorkCamera(ignoreGameplay)
	if ignoreGameplay ~= true then
		self:SwitchToGameplay(false)
	end
	local cam = self:GetWorkCamera()
	if util.is_valid(cam) then
		self:SwitchToCamera(cam)
	end
	if util.is_valid(self.m_btCamera) then
		self.m_btCamera:SetText(locale.get_text("pfm_work_camera"))
	end

	for ent, c in ents.citerator(ents.COMPONENT_PFM_CAMERA) do
		ent:TurnOff()
	end

	self:SetCameraView(gui.PFMCoreViewportBase.CAMERA_VIEW_GAME)
	self:UpdateWorkCamera()

	--[[if(ignoreGameplay ~= true) then self:SwitchToGameplay(false) end
	if(util.is_valid(self.m_btCamera)) then self.m_btCamera:SetText(locale.get_text("pfm_work_camera")) end
	-- ents.PFMCamera.set_camera_enabled(false)

	local scene = self.m_viewport:GetScene()
	if(util.is_valid(scene)) then
		local cam = game.get_primary_camera()
		if(util.is_valid(cam)) then
			scene:SetActiveCamera(cam)
		end
	end]]
end
function gui.PFMCoreViewportBase:CopyToCamera(camSrc, camDst) end
function gui.PFMCoreViewportBase:IsSceneCamera()
	return self.m_cameraView == gui.PFMCoreViewportBase.CAMERA_VIEW_SCENE
end
function gui.PFMCoreViewportBase:IsWorkCamera()
	return not self:IsSceneCamera()
end
function gui.PFMCoreViewportBase:ToggleCamera()
	if self:IsSceneCamera() then
		self:SwitchToWorkCamera()
	else
		self:SwitchToSceneCamera()
	end
end

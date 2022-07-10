--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiviewport.lua")
include("/gui/hbox.lua")
include("/gui/aspectratio.lua")
include("/gui/pfm/button.lua")
include("/gui/pfm/playbutton.lua")
include("/gui/pfm/base_viewport.lua")
include("/gui/pfm/cursor_tracker.lua")
include("/gui/draganddrop.lua")
include("/gui/playbackcontrols.lua")
include("/gui/raytracedviewport.lua")
include("/pfm/fonts.lua")

include_component("click")

util.register_class("gui.PFMViewport",gui.PFMBaseViewport)

gui.PFMViewport.MANIPULATOR_MODE_SELECT = 0
gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL = 1
gui.PFMViewport.MANIPULATOR_MODE_MOVE_LOCAL = 2
gui.PFMViewport.MANIPULATOR_MODE_MOVE_VIEW = 3
gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL = 4
gui.PFMViewport.MANIPULATOR_MODE_ROTATE_LOCAL = 5
gui.PFMViewport.MANIPULATOR_MODE_ROTATE_VIEW = 6
gui.PFMViewport.MANIPULATOR_MODE_SCALE = 7

gui.PFMViewport.CAMERA_MODE_PLAYBACK = 0
gui.PFMViewport.CAMERA_MODE_FLY = 1
gui.PFMViewport.CAMERA_MODE_WALK = 2
gui.PFMViewport.CAMERA_MODE_COUNT = 3

gui.PFMViewport.CAMERA_VIEW_GAME = 0
gui.PFMViewport.CAMERA_VIEW_SCENE = 1
function gui.PFMViewport:__init()
	gui.PFMBaseViewport.__init(self)
end
function gui.PFMViewport:OnInitialize()
	self.m_vrControllers = {}
	self.m_manipulatorMode = gui.PFMViewport.MANIPULATOR_MODE_SELECT

	gui.PFMBaseViewport.OnInitialize(self)

	self.m_titleBar:SetHeight(37)

	self.m_gameplayEnabled = true
	self.m_cameraView = gui.PFMViewport.CAMERA_VIEW_SCENE
	self.m_aspectRatioWrapper:AddCallback("OnAspectRatioChanged",function(el,aspectRatio)
		if(util.is_valid(self.m_viewport)) then
			local scene = self.m_viewport:GetScene()
			if(scene ~= nil) then
				local cam = scene:GetActiveCamera()
				if(cam ~= nil) then
					cam:SetAspectRatio(aspectRatio)
					cam:UpdateMatrices()
				end
			end
		end
		--[[local maxResolution = engine.get_window_resolution()
		local w,h = util.clamp_resolution_to_aspect_ratio(maxResolution.x,maxResolution.y,aspectRatio)
		self.m_viewport:SetupScene(maxResolution.x,maxResolution.y)]]
		--self:Update()
	end)

	local function create_text_element(font,pos,color)
		local textColor = Color(182,182,182)
		local el = gui.create("WIText",self.m_titleBar)
		el:SetFont(font)
		el:SetColor(textColor)
		el:SetPos(pos)
		return el
	end
	local textColor = Color(182,182,182)
	self.m_timeGlobal = create_text_element("pfm_large",Vector2(20,15),textColor)
	self.m_timeGlobal:SetText(util.get_pretty_time(0.0))
	self.m_timeGlobal:SizeToContents()

	self.m_timeLocal = create_text_element("pfm_large",Vector2(0,15),textColor)
	self.m_timeLocal:SetText(util.get_pretty_time(0.0))
	self.m_timeLocal:SizeToContents()
	self.m_timeLocal:SetAnchor(1,0,1,0)

	textColor = Color(152,152,152)
	self.m_filmClipParent = create_text_element("pfm_medium",Vector2(0,3),textColor)
	self.m_filmClipParent:CenterToParentX()
	self.m_filmClipParent:SetAnchor(0.5,0,0.5,0)

	self.m_filmClip = create_text_element("pfm_medium",Vector2(0,16),textColor)
	self.m_filmClip:CenterToParentX()
	self.m_filmClip:SetAnchor(0.5,0,0.5,0)

	self:SwitchToGameplay(false)
	time.create_simple_timer(0.0,function()
		if(self:IsValid()) then self:SwitchToWorkCamera() end
	end)
end
function gui.PFMViewport:InitializeCustomScene()
	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local scene = ents.create_scene(sceneCreateInfo,gameScene)
	self.m_scene = scene

	local entRenderer = ents.create("rasterization_renderer")
	local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
	self.m_renderer = renderer
	local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
	rasterizer:SetSSAOEnabled(true)
	renderer:InitializeRenderTarget(scene,gameRenderer:GetWidth(),gameRenderer:GetHeight())
	scene:SetRenderer(renderer)

	local gameCam = gameScene:GetActiveCamera()
	local cam = ents.create_camera(gameCam:GetAspectRatio(),gameCam:GetFOV(),gameCam:GetNearZ(),gameCam:GetFarZ())
	self.m_camera = cam
	scene:SetActiveCamera(cam)

	self.m_viewport:SetScene(scene,nil,function() return game.is_default_game_render_enabled() end)
end
function gui.PFMViewport:InitializeViewport(parent)
	gui.PFMBaseViewport.InitializeViewport(self,parent)
	local vpContainer = gui.create("WIBase",parent)
	self.m_vpContainer = vpContainer

	self.m_viewport = gui.create("WIViewport",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_viewport:SetMovementControlsEnabled(false)

	self.m_viewport:SetType(gui.WIViewport.VIEWPORT_TYPE_3D)

	-- This controls the behavior that allows controlling the camera while holding the right mouse button down
	self.m_viewport:SetMouseInputEnabled(true)
	self.m_cbClickMouseInput = self.m_viewport:AddCallback("OnMouseEvent",function(el,mouseButton,state,mods)
		return self:OnViewportMouseEvent(el,mouseButton,state,mods)
	end)
	self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_PLAYBACK)

	gui.mark_as_drag_and_drop_target(self.m_viewport,"ModelCatalog")
end
function gui.PFMViewport:InitializeSettings(parent)
	gui.PFMBaseViewport.InitializeSettings(self,parent)
	local p = self.m_settingsBox

	--[[local ctrlRt,wrapper = p:AddDropDownMenu(locale.get_text("pfm_viewport_rt_enabled"),"rt_enabled",{
		{"disabled",locale.get_text("disabled")},
		{"cycles",locale.get_text("pfm_render_engine_cycles")},
		{"luxcorerender",locale.get_text("pfm_render_engine_luxcorerender")}
	},0)]]
	-- Live raytracing
	local ctrlRt = p:AddDropDownMenu(locale.get_text("pfm_viewport_rt_enabled"),"rt_enabled",{
		{"0",locale.get_text("disabled")},
		{"1",locale.get_text("enabled")}
	},0)
	self.m_ctrlRt = ctrlRt
	-- wrapper:SetUseAltMode(true)
	self.m_ctrlRt:AddCallback("OnOptionSelected",function(el,idx)
		local val = el:GetOptionValue(idx)
		if(val == "0") then val = nil
		else
			val = "cycles"
			local pfm = tool.get_filmmaker()
			local renderTab = pfm:GetRenderTab()
			if(util.is_valid(renderTab)) then val = renderTab:GetRenderSettings():GetRenderEngine() end
		end
		self:SetRtViewportRenderer(val)
	end)

	self.m_ctrlVr = p:AddDropDownMenu(locale.get_text("pfm_viewport_vr_enabled"),"vr_enabled",{
		{"0",locale.get_text("disabled")},
		{"1",locale.get_text("enabled")}
	},0)
	self.m_ctrlVr:AddCallback("OnOptionSelected",function(el,idx)
		local enabled = (idx == 1)
		ents.PFMCamera.set_vr_view_enabled(enabled)
		if(ents.PFMCamera.is_vr_view_enabled()) then
			for i=0,openvr.MAX_TRACKED_DEVICE_COUNT -1 do
				if(openvr.get_tracked_device_class(i) == openvr.TRACKED_DEVICE_CLASS_CONTROLLER) then
					local ent = ents.create("pfm_vr_controller")
					ent:Spawn()

					table.insert(self.m_vrControllers,ent)

					local vrC = ent:GetComponent(ents.COMPONENT_VR_CONTROLLER)
					if(vrC ~= nil) then vrC:SetControllerId(i) end

					local pfmVrC = ent:GetComponent(ents.COMPONENT_PFM_VR_CONTROLLER)
					if(pfmVrC ~= nil) then
						-- TODO: This is just a prototype implementation, do this properly!
						local el = pfmVrC:GetGUIElement():GetPlayButton()
						if(util.is_valid(el)) then
							el:AddCallback("OnStateChanged",function(el,oldState,state)
								local btPlay = self:GetPlayButton()
								if(util.is_valid(btPlay) == false) then return end
								if(state == gui.PFMPlayButton.STATE_PLAYING) then
									btPlay:Pause()
								elseif(state == gui.PFMPlayButton.STATE_PAUSED) then
									btPlay:Play()
								end
							end)
						end
					end
				end
			end
		else
			for _,ent in ipairs(self.m_vrControllers) do
				if(ent:IsValid()) then ent:Remove() end
			end
			self.m_vrControllers = {}
		end
	end)

	self.m_ctrlToneMapping = p:AddDropDownMenu(locale.get_text("pfm_viewport_tonemapping"),"tonemapping",{
		{"gamma_correction",locale.get_text("gamma_correction")},
		{"reinhard","Reinhard"},
		{"hejil_richard","Hejil-Richard"},
		{"uncharted","Uncharted"},
		{"aces","Aces"},
		{"gran_turismo","Gran Turismo"}
	},"aces")
	self.m_ctrlToneMapping:AddCallback("OnOptionSelected",function(el,idx)
		console.run("cl_render_tone_mapping " .. tostring(idx))
		tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	p:ResetControls()
end
function gui.PFMViewport:SetRtViewportRenderer(renderer)
	local enabled = (renderer ~= nil)
	console.run("cl_max_fps",enabled and "24" or tostring(console.get_convar_int("pfm_max_fps"))) -- Clamp max fps to make more resources available for the renderer
	util.remove(self.m_rtViewport)
	tool.get_filmmaker():SetOverlaySceneEnabled(false)
	if(enabled ~= true) then return end
	local rtViewport = gui.create("WIRealtimeRaytracedViewport",self.m_vpContainer,0,0,self.m_vpContainer:GetWidth(),self.m_vpContainer:GetHeight(),0,0,1,1)
	rtViewport:SetRenderer(renderer)
	local scene = self.m_viewport:GetScene()
	if(util.is_valid(scene)) then rtViewport:SetGameScene(scene) end
	self.m_rtViewport = rtViewport
	tool.get_filmmaker():SetOverlaySceneEnabled(true)

	self:UpdateRenderSettings()
end
function gui.PFMViewport:GetRealtimeRaytracedViewport() return self.m_rtViewport end
function gui.PFMViewport:StopLiveRaytracing()
	self.m_ctrlRt:SelectOption(0)
end
function gui.PFMViewport:InitializeControls()
	gui.PFMBaseViewport.InitializeControls(self)

	local controls = gui.create("WIBase",self.m_vpContents)
	controls:SetSize(64,64)
	self.m_controls = controls

	self.m_playControls = gui.create("PlaybackControls",controls)
	self.m_playControls:CenterToParentX()
	self.m_playControls:SetAnchor(0.5,0,0.5,0)
	self.m_playControls:LinkToPFMProject(tool.get_filmmaker())
	self.m_btPlay = self.m_playControls:GetPlayButton()
	controls:SizeToContents()
	self:InitializeManipulatorControls()
	self:InitializeCameraControls()
end
function gui.PFMViewport:UpdateRenderSettings()
	local pfm = tool.get_filmmaker()
	local renderTab = pfm:GetRenderTab()
	if(util.is_valid(self.m_rtViewport) == false or util.is_valid(renderTab) == false) then return end
	self.m_rtViewport:SetRenderSettings(renderTab:GetRenderSettings())
	self.m_rtViewport:Refresh(true)
end
function gui.PFMViewport:OnViewportMouseEvent(el,mouseButton,state,mods)
	if(mouseButton ~= input.MOUSE_BUTTON_LEFT and mouseButton ~= input.MOUSE_BUTTON_RIGHT) then return util.EVENT_REPLY_UNHANDLED end
	if(state ~= input.STATE_PRESS and state ~= input.STATE_RELEASE) then return util.EVENT_REPLY_UNHANDLED end

	local function findActor(pressed)
		if(pressed == nil) then pressed = state == input.STATE_PRESS end
		local filter
		--[[if(self.m_manipulatorMode ~= gui.PFMViewport.MANIPULATOR_MODE_SELECT) then
			filter = function(ent,mdlC)
				return not ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
			end
		end]]
		return ents.ClickComponent.inject_click_input(input.ACTION_ATTACK,pressed,filter)
	end

	--[[if(mouseButton == input.MOUSE_BUTTON_RIGHT) then
		self.m_viewport:RequestFocus()
		if(state == input.STATE_PRESS) then
			self.m_cursorTracker = gui.CursorTracker()
			self:EnableThinking()
		elseif(state == input.STATE_RELEASE) then

		end
		return util.EVENT_REPLY_HANDLED
	end]]

	local filmmaker = tool.get_filmmaker()
	if(self.m_inCameraControlMode and mouseButton == input.MOUSE_BUTTON_RIGHT and state == input.STATE_RELEASE and filmmaker:IsValid()) then
		self:SetGameplayMode(false)
		return util.EVENT_REPLY_HANDLED
	end

	local window = self:GetRootWindow()
	local el = gui.get_element_under_cursor(window)
	if(util.is_valid(el) and (el == self or el:IsDescendantOf(self))) then
		if(mouseButton == input.MOUSE_BUTTON_RIGHT) then
			if(state == input.STATE_PRESS) then
				self.m_cursorTracker = gui.CursorTracker()
				self:EnableThinking()
				return util.EVENT_REPLY_HANDLED
			else
				if(self.m_cursorTracker ~= nil) then
					self.m_cursorTracker = nil
					self:DisableThinking()

					local handled,entActor = findActor(true)
					if(handled == util.EVENT_REPLY_UNHANDLED and util.is_valid(entActor)) then
						local renderC = entActor:GetComponent(ents.COMPONENT_RENDER)
						local mdl = entActor:GetModel()
						if(renderC ~= nil and mdl ~= nil) then
							local materials = {}
							for _,mesh in ipairs(renderC:GetRenderMeshes()) do
								local mat = mdl:GetMaterial(mesh:GetSkinTextureIndex())
								if(util.is_valid(mat)) then
									materials[mat:GetName()] = true
								end
							end
							if(not table.is_empty(materials)) then
								local pContext = gui.open_context_menu()
								if(util.is_valid(pContext) == false) then return end
								pContext:SetPos(input.get_cursor_pos())

								local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_edit_material"))
								for mat,_ in pairs(materials) do
									pSubMenu:AddItem(mat,function()
										tool.get_filmmaker():OpenMaterialEditor(mat,mdl:GetName())
									end)
								end
								pSubMenu:Update()

								pContext:Update()
							end
						end
					end
				end
			end
		elseif(mouseButton == input.MOUSE_BUTTON_LEFT) then
			if(util.is_valid(self.m_rtMoverActor)) then
				self.m_rtMoverActor:RemoveComponent("pfm_rt_mover")
				tool.get_filmmaker():TagRenderSceneAsDirty()
				if(state == input.STATE_RELEASE) then return util.EVENT_REPLY_HANDLED end
			end
			local handled,entActor = findActor()
			if(handled == util.EVENT_REPLY_UNHANDLED and util.is_valid(entActor)) then
				local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
				local actor = (actorC ~= nil) and actorC:GetActorData() or nil
				if(actor) then
					if(self:IsMoveManipulatorMode(self:GetManipulatorMode())) then
						if(state == input.STATE_PRESS) then
							self.m_rtMoverActor = entActor
							entActor:AddComponent("pfm_rt_mover")
							tool.get_filmmaker():TagRenderSceneAsDirty(true)
						end
					else
						if(input.is_alt_key_down()) then
							filmmaker:DeselectActor(actor)
						else
							local deselectCurrent = not input.is_ctrl_key_down()
							filmmaker:SelectActor(actor,deselectCurrent)
						end
					end
				end
			end
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMViewport:OnRemove()
	util.remove(self.m_entTransform)
	if(util.is_valid(self.m_scene)) then self.m_scene:GetEntity():Remove() end
	if(util.is_valid(self.m_renderer)) then self.m_renderer:GetEntity():Remove() end
	if(util.is_valid(self.m_camera)) then self.m_camera:GetEntity():Remove() end
	for _,ent in ipairs(self.m_vrControllers) do
		if(ent:IsValid()) then ent:Remove() end
	end
end
function gui.PFMViewport:GetCamera() return self.m_viewport:GetCamera() end
function gui.PFMViewport:GetAspectRatio()
	return util.is_valid(self.m_aspectRatioWrapper) and self.m_aspectRatioWrapper:GetAspectRatio() or 1.0
end
function gui.PFMViewport:GetAspectRatioProperty()
	return util.is_valid(self.m_aspectRatioWrapper) and self.m_aspectRatioWrapper:GetAspectRatioProperty() or nil
end
function gui.PFMViewport:SetCameraMode(camMode)
	pfm.log("Changing camera mode to " .. ((camMode == gui.PFMViewport.CAMERA_MODE_PLAYBACK and "playback") or (camMode == gui.PFMViewport.CAMERA_MODE_FLY and "fly") or "walk"))
	self.m_cameraMode = camMode

	-- ents.PFMCamera.set_camera_enabled(camMode == gui.PFMViewport.CAMERA_MODE_PLAYBACK)
	local rtUpdateEnabled = (camMode ~= gui.PFMViewport.CAMERA_MODE_PLAYBACK)
	self:SetThinkingEnabled(rtUpdateEnabled)
	if(rtUpdateEnabled) then
		self.m_camStartPose = math.Transform()
		local cam = game.get_render_scene_camera()
		if(util.is_valid(cam)) then
			local entCam = cam:GetEntity()
			self.m_camStartPose:SetOrigin(entCam:GetPos())
			self.m_camStartPose:SetRotation(entCam:GetRotation())
		end
	else self.m_camStartPose = nil end

	-- We need to notify the server to change the player's movement mode (i.e. noclip/walk)
	local packet = net.Packet()
	packet:WriteUInt8(camMode)
	local cam = game.get_render_scene_camera()
	if(cam ~= nil) then
		packet:WriteBool(true)
		packet:WriteVector(cam:GetEntity():GetPos())
		packet:WriteQuaternion(cam:GetEntity():GetRotation())
	else packet:WriteBool(false) end
	net.send(net.PROTOCOL_SLOW_RELIABLE,"sv_pfm_camera_mode",packet)
end
function gui.PFMViewport:SetGlobalTime(time)
	if(util.is_valid(self.m_timeGlobal)) then
		self.m_timeGlobal:SetText(util.get_pretty_time(time))
		self.m_timeGlobal:SizeToContents()
	end
end
function gui.PFMViewport:SetLocalTime(time)
	if(util.is_valid(self.m_timeLocal)) then
		self.m_timeLocal:SetText(util.get_pretty_time(time))
		self.m_timeLocal:SizeToContents()
	end
end
function gui.PFMViewport:SetFilmClipName(name)
	if(util.is_valid(self.m_filmClip)) then
		if(name == self.m_filmClip:GetText()) then return end
		self.m_filmClip:SetText(name)
		self.m_filmClip:SizeToContents()

		self:UpdateFilmLabelPositions()
	end
end
function gui.PFMViewport:SetFilmClipParentName(name)
	if(util.is_valid(self.m_filmClipParent)) then
		if(name == self.m_filmClipParent:GetText()) then return end
		self.m_filmClipParent:SetText(name)
		self.m_filmClipParent:SizeToContents()

		self:UpdateFilmLabelPositions()
	end
end
function gui.PFMViewport:UpdateFilmLabelPositions()
	if(util.is_valid(self.m_filmClipParent)) then
		self.m_filmClipParent:SetX(self.m_titleBar:GetWidth() *0.5 -self.m_filmClipParent:GetWidth() *0.5)
	end
	if(util.is_valid(self.m_filmClip)) then
		self.m_filmClip:SetX(self.m_titleBar:GetWidth() *0.5 -self.m_filmClip:GetWidth() *0.5)
	end
end
function gui.PFMViewport:IsMoveManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL or
		mode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_LOCAL or
		mode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_VIEW
end
function gui.PFMViewport:IsRotationManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL or
		mode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_LOCAL or
		mode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_VIEW
end
function gui.PFMViewport:IsScaleManipulatorMode(mode)
	return mode == gui.PFMViewport.MANIPULATOR_MODE_SCALE
end
function gui.PFMViewport:GetManipulatorMode() return self.m_manipulatorMode end
function gui.PFMViewport:SetManipulatorMode(manipulatorMode)
	util.remove(self.m_entTransform)
	self.m_manipulatorMode = manipulatorMode
	self.m_btSelect:SetActivated(manipulatorMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT)
	self.m_btMove:SetActivated(self:IsMoveManipulatorMode(manipulatorMode))
	self.m_btRotate:SetActivated(self:IsRotationManipulatorMode(manipulatorMode))
	self.m_btScreen:SetActivated(self:IsScaleManipulatorMode(manipulatorMode))

	local pfm = tool.get_filmmaker()
	local selectionManager = pfm:GetSelectionManager()
	local selectedActors = selectionManager:GetSelectedActors()
	local selectedActorList = {}
	for ent,b in pairs(selectedActors) do table.insert(selectedActorList,ent) end

	for _,ent in ipairs(selectedActorList) do
		if(ent:IsValid()) then
			ent:RemoveComponent("util_bone_transform")
			self:UpdateActorManipulation(ent,true)
		end
	end
	self:UpdateManipulationMode()
end
function gui.PFMViewport:InitializeTransformWidget(tc,ent)
	local manipMode = self:GetManipulatorMode()
	if(selected == false or manipMode == gui.PFMViewport.MANIPULATOR_MODE_SELECT) then
		-- ent:RemoveComponent("util_transform")
	elseif(tc ~= nil) then
		if(self:IsMoveManipulatorMode(manipMode)) then
			tc:SetTranslationEnabled(true)
			tc:SetRotationEnabled(false)
			tc:SetScaleEnabled(false)
		elseif(self:IsRotationManipulatorMode(manipMode)) then
			tc:SetTranslationEnabled(false)
			tc:SetRotationEnabled(true)
			tc:SetScaleEnabled(false)
		elseif(self:IsScaleManipulatorMode(manipMode)) then
			tc:SetTranslationEnabled(false)
			tc:SetRotationEnabled(false)
			tc:SetScaleEnabled(true)
		end
		tc:UpdateAxes()
	end

	if(util.is_valid(tc)) then
		if(manipMode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL or manipMode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL or manipMode == gui.PFMViewport.MANIPULATOR_MODE_SCALE) then
			tc:SetSpace(ents.UtilTransformComponent.SPACE_WORLD)
			tc:SetReferenceEntity()
		elseif(manipMode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_LOCAL or manipMode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_LOCAL) then
			tc:SetSpace(ents.UtilTransformComponent.SPACE_LOCAL)
			tc:SetReferenceEntity(ent)
		elseif(manipMode == gui.PFMViewport.MANIPULATOR_MODE_MOVE_VIEW or manipMode == gui.PFMViewport.MANIPULATOR_MODE_ROTATE_VIEW) then
			tc:SetSpace(ents.UtilTransformComponent.SPACE_VIEW)
			local camC = self:GetActiveCamera()
			if(util.is_valid(camC)) then tc:SetReferenceEntity(camC:GetEntity()) end
		end
	end
end
function gui.PFMViewport:UpdateManipulationMode()
	local manipMode = self:GetManipulatorMode()
	if(self:IsMoveManipulatorMode(manipMode) == false and self:IsRotationManipulatorMode(manipMode) == false and self:IsScaleManipulatorMode(manipMode) == false) then return end
	local pfm = tool.get_filmmaker()
	local selectionManager = pfm:GetSelectionManager()
	local selectedActors = selectionManager:GetSelectedActors()
	local selectedActorList = {}
	for ent,b in pairs(selectedActors) do table.insert(selectedActorList,ent) end
	if(#selectedActorList ~= 1 or util.is_valid(selectedActorList[1]) == false) then return end

	local boneName
	-- Check if a bone is selected
	local actorEditor = pfm:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end
	local actor = selectedActorList[1]
	local actorC = util.is_valid(actor) and actor:GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
	local actorData = util.is_valid(actorC) and actorC:GetActorData() or nil
	if(actorData ~= nil) then
		local itemSkeleton = actorEditor:GetActorComponentItem(actorData,"animated")
		if(itemSkeleton ~= nil) then
			for _,item in ipairs(itemSkeleton:GetItems()) do
				if(item:IsValid() and item:GetIdentifier() == "bone") then
					for _,boneItem in ipairs(item:GetItems()) do
						if(boneItem:IsValid()) then
							for _,boneSubItem in ipairs(boneItem:GetItems()) do
								if(boneSubItem:IsValid() and boneSubItem:IsSelected()) then
									local itemIdent = boneSubItem:GetIdentifier()
									if(itemIdent ~= nil) then
										local identifier = panima.Channel.Path(itemIdent)
										local cname,path = ents.PanimaComponent.parse_component_channel_path(identifier)
										if(cname ~= nil) then
											local c0,offset = path:GetComponent(0)
											if(c0 == "bone") then
												local name = path:GetComponent(offset)
												if(#name > 0) then boneName = name end
												break
											end
										end
									end
								end
							end
							if(boneName ~= nil) then break end
						end
					end
					break
				end
			end
		end
	end

	if(boneName == nil) then return end
	local ent = selectedActorList[1]
	local boneId = boneName
	if(type(boneId) == "string") then
		local mdl = ent:GetModel()
		if(mdl == nil) then return end
		boneId = mdl:LookupBone(boneId)
		if(boneId == -1) then return end
	end
	ent:RemoveComponent("util_transform")
	util.remove(self.m_entTransform)
	local trBone = ent:AddComponent("util_bone_transform")
	if(trBone == nil) then return end
	local trC = trBone:SetTransformEnabled(boneId)
	if(trC == nil) then return end
	self:InitializeTransformWidget(trC,ent)

	local function update_channel_value(boneId,value,channelName)
		local channel = actorC:GetBoneChannel(boneId,channelName)
		local log = (channel ~= nil) and channel:GetLog() or nil
		local layer = (log ~= nil) and log:GetLayers():GetTable()[1] or nil
		if(layer ~= nil) then
			local channelClip = channel:FindParentElement(function(el) return el:GetType() == fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP end)
			if(channelClip ~= nil) then
				local projectManager = pfm
				-- TODO: Do we have to take the film clip offset into account?
				local timeFrame = channelClip:GetTimeFrame()
				local t = timeFrame:LocalizeOffset(projectManager:GetTimeOffset())
				local i = layer:InsertValue(t,value)

				-- Mark frames as dirty
				local times = layer:GetTimes():GetTable()
				local tPrev = timeFrame:GlobalizeOffset((i > 0) and times:At(i -1) or t)
				local tNext = timeFrame:GlobalizeOffset((i < (#times -1)) and times:At(i +1) or t)
				local minFrame = math.floor(projectManager:TimeOffsetToFrameOffset(tPrev))
				local maxFrame = math.ceil(projectManager:TimeOffsetToFrameOffset(tNext))
				local animCache = projectManager:GetAnimationCache()
				local fc = projectManager:GetActiveGameViewFilmClip()
				for frameIdx=minFrame,maxFrame do
					animCache:MarkFrameAsDirty(frameIdx)
				end
			end
		end
	end
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_POSITION_CHANGED,function(boneId,pos,localPos)
		self:SetBoneTransformProperty(ent,boneId,"position",localPos)
		--update_channel_value(boneId,localPos,"position")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED,function(boneId,rot,localRot)
		self:SetBoneTransformProperty(ent,boneId,"rotation",localRot)
		--update_channel_value(boneId,localRot,"rotation")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED,function(boneId,scale,localScale)
		self:SetBoneTransformProperty(ent,boneId,"scale",localScale)
		--update_channel_value(boneId,localScale,"scale")
		--tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
end
function gui.PFMViewport:SetBoneTransformProperty(ent,boneId,propName,value)
	if(util.is_valid(ent) == false) then return end
	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local bone = skeleton:GetBone(boneId)
	if(bone == nil) then return end
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if(actorC ~= nil) then
		tool.get_filmmaker():SetActorBoneTransformProperty(actorC,bone:GetName() .. "/" .. propName,value)
	end
end
function gui.PFMViewport:GetTransformWidgetComponent() return self.m_transformComponent end
function gui.PFMViewport:CreateActorTransformWidget(ent,manipMode,enabled)
	if(enabled == nil) then enabled = true end
	ent:RemoveComponent("util_bone_transform")
	ent:RemoveComponent("util_transform")
	util.remove(self.m_entTransform)

	local function add_transform_component()
		local trC = ent:GetComponent("util_transform")
		if(trC ~= nil) then return trC end
		trC = ent:AddComponent("util_transform")
		if(trC == nil) then return trC end
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,function(pos)
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				tool.get_filmmaker():SetActorTransformProperty(actorC,"position",pos)
			end
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function(rot)
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				tool.get_filmmaker():SetActorTransformProperty(actorC,"rotation",rot)
			end
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED,function(scale)
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				tool.get_filmmaker():SetActorTransformProperty(actorC,"scale",scale)
			end
		end)
		return trC
	end
	local manipMode = manipMode or self.m_manipulatorMode
	if(enabled and (self:IsMoveManipulatorMode(manipMode) or self:IsRotationManipulatorMode(manipMode))) then
		local pm = tool.get_filmmaker()
		local actorEditor = pm:GetActorEditor()
		local activeControls = actorEditor:GetActiveControls()
		local uuid = tostring(ent:GetUuid())
		if(activeControls[uuid] ~= nil) then
			local targetPath
			local i = 0
			for path,data in pairs(activeControls[uuid]) do
				i = i +1
				if(i == 2) then
					targetPath = nil
					break
				end
				targetPath = path
			end
			if(targetPath ~= nil) then
				local memberInfo = ent:FindMemberInfo(targetPath)
				if(memberInfo ~= nil) then
					if(
						(memberInfo.type == udm.TYPE_VECTOR3 and self:IsMoveManipulatorMode(manipMode)) or
						(memberInfo.type == udm.TYPE_QUATERNION and self:IsRotationManipulatorMode(manipMode))
					) then
						local val = ent:GetMemberValue(targetPath)
						if(val ~= nil) then
							local entTransform = ents.create("util_transform")
							entTransform:Spawn()

							local pose = ent:GetPose()
							local propPath = util.Path.CreateFilePath(targetPath)
							local basePropName = propPath:GetBack()
							if(memberInfo.type == udm.TYPE_VECTOR3) then
								pose:SetOrigin(val)
								if(basePropName == "position") then
									propPath:PopBack()
									local rot = ent:GetMemberValue(propPath:GetString() .. "rotation")
									pose:SetRotation(rot)
								end
							elseif(memberInfo.type == udm.TYPE_QUATERNION) then
								pose:SetRotation(val)
								if(basePropName == "rotation") then
									propPath:PopBack()
									local pos = ent:GetMemberValue(propPath:GetString() .. "position")
									pose:SetOrigin(pos)
								end
							end
							entTransform:SetPose(pose)
							self.m_entTransform = entTransform

							local trC = entTransform:GetComponent("util_transform")
							trC:SetScaleEnabled(false)
							if(memberInfo.type == udm.TYPE_VECTOR3) then
								trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,function(pos)
									local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
									if(actorC ~= nil) then
										local cname,path = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
										if(cname == "pfm_ik") then
											-- If this is an ik property, we'll want to update the animation data for the position and rotation of
											-- all of the involved bones
											path:PopFront() -- Pop "effector/" prefix
											local boneName = path:GetFront()
											local ikC = ent:GetComponent("pfm_ik")
											if(ikC ~= nil) then
												local chain = ikC:GetIkControllerBoneChain(boneName)
												local mdl = ent:GetModel()
												if(chain ~= nil and mdl ~= nil) then
													local skeleton = mdl:GetSkeleton()
													local function applyBonePoseValue(targetPath)
														local val = ent:GetMemberValue(targetPath)
														if(val ~= nil) then tool.get_filmmaker():SetActorGenericProperty(actorC,targetPath,val) end
													end
													local function applyBonePose(basePropPath)
														applyBonePoseValue(basePropPath .. "position")
														applyBonePoseValue(basePropPath .. "rotation")
													end
													for _,boneId in ipairs(chain) do
														local bone = skeleton:GetBone(boneId)
														if(bone ~= nil) then
															applyBonePose("ec/animated/bone/" .. bone:GetName() .. "/")
														end
													end
												end
											end
										end

										tool.get_filmmaker():SetActorGenericProperty(actorC,targetPath,pos)
									end
								end)
							elseif(memberInfo.type == udm.TYPE_QUATERNION) then
								trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function(rot)
									local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
									if(actorC ~= nil) then
										tool.get_filmmaker():SetActorGenericProperty(actorC,targetPath,rot)
									end
								end)
							end
							self:InitializeTransformWidget(trC,ent)
						end
					end
				end
			end
		end

		if(util.is_valid(self.m_entTransform) == false) then
			local tc = add_transform_component()
			self.m_transformComponent = tc
			self:InitializeTransformWidget(tc,ent)
		end
	end
	tool.get_filmmaker():TagRenderSceneAsDirty()
end
function gui.PFMViewport:UpdateActorManipulation(ent,selected)
	self:CreateActorTransformWidget(ent,self.m_manipulatorMode,selected)
end
function gui.PFMViewport:GetActiveCamera()
	local scene = util.is_valid(self.m_viewport) and self.m_viewport:GetScene()
	return (scene ~= nil) and scene:GetActiveCamera() or nil
end
function gui.PFMViewport:OnActorSelectionChanged(ent,selected)
	self:UpdateActorManipulation(ent,selected)
	self:UpdateManipulationMode()
end
function gui.PFMViewport:InitializeManipulatorControls()
	local controls = gui.create("WIHBox",self.m_controls)
	self.m_btSelect = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_select","gui/pfm/icon_manipulator_select_activated",function()
		self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SELECT)
		return true
	end)
	self.m_btMove = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_move","gui/pfm/icon_manipulator_move_activated",function()
		local mode = self:GetManipulatorMode()
		local nextMode = {
			[gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL] = gui.PFMViewport.MANIPULATOR_MODE_MOVE_LOCAL,
			[gui.PFMViewport.MANIPULATOR_MODE_MOVE_LOCAL] = gui.PFMViewport.MANIPULATOR_MODE_MOVE_VIEW,
			[gui.PFMViewport.MANIPULATOR_MODE_MOVE_VIEW] = gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL
		}
		mode = nextMode[mode] or gui.PFMViewport.MANIPULATOR_MODE_MOVE_GLOBAL
		self:SetManipulatorMode(mode)
		return true
	end)
	self.m_btRotate = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_rotate","gui/pfm/icon_manipulator_rotate_activated",function()
		local mode = self:GetManipulatorMode()
		local nextMode = {
			[gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL] = gui.PFMViewport.MANIPULATOR_MODE_ROTATE_LOCAL,
			[gui.PFMViewport.MANIPULATOR_MODE_ROTATE_LOCAL] = gui.PFMViewport.MANIPULATOR_MODE_ROTATE_VIEW,
			[gui.PFMViewport.MANIPULATOR_MODE_ROTATE_VIEW] = gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL
		}
		mode = nextMode[mode] or gui.PFMViewport.MANIPULATOR_MODE_ROTATE_GLOBAL
		self:SetManipulatorMode(mode)
		return true
	end)
	self.m_btScreen = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_screen","gui/pfm/icon_manipulator_screen_activated",function()
		self:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SCALE)
		return true
	end)
	controls:SetHeight(self.m_btSelect:GetHeight())
	controls:Update()
	controls:SetX(3)
	controls:SetAnchor(0,1,0,1)
	self.manipulatorControls = controls
end
function gui.PFMViewport:InitializeCameraControls()
	local controls = gui.create("WIHBox",self.m_controls)

	self.m_btAutoAim = gui.PFMButton.create(controls,"gui/pfm/icon_viewport_autoaim","gui/pfm/icon_viewport_autoaim_activated",function()
		print("TODO")
	end)
	self.m_btCamera = gui.PFMButton.create(controls,"gui/pfm/icon_cp_camera","gui/pfm/icon_cp_camera_activated",function()
		self:ToggleCamera()
	end)
	self.m_btCamera:SetupContextMenu(function(pContext)
		local sceneCamera = self:IsSceneCamera()
		local camName = sceneCamera and locale.get_text("pfm_scene_camera") or locale.get_text("pfm_work_camera")
		pContext:AddItem(locale.get_text("pfm_switch_to_camera",{camName}),function() self:ToggleCamera() end)
		pContext:AddItem(locale.get_text("pfm_switch_to_gameplay"),function() self:SwitchToGameplay() end)
		pContext:AddItem(locale.get_text("pfm_copy_to_camera",{camName}),function() end) -- TODO

		pContext:AddLine()

		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_change_scene_camera"))
		local pm = pfm.get_project_manager()
		local session = (pm ~= nil) and pm:GetSession() or nil
		local filmClip = (session ~= nil) and session:FindClipAtTimeOffset(pm:GetTimeOffset()) or nil
		if(filmClip ~= nil) then
			local actorList = filmClip:GetActorList()
			for _,actor in ipairs(actorList) do
				local camC = actor:FindComponent("camera")
				if(camC ~= nil) then
					pSubMenu:AddItem(actor:GetName(),function()
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

		if(sceneCamera) then
			pContext:AddItem(locale.get_text("pfm_select_actor"),function()
				local camC = ents.PFMCamera.get_active_camera()
				local actorC = (camC ~= nil) and camC:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
				if(actorC == nil) then return end
				local actor = actorC:GetActorData()
				tool.get_filmmaker():SelectActor(actor)
			end)

			pContext:AddLine()

			pContext:AddItem(locale.get_text("pfm_show_camera_in_element_viewer"),function()
				local camC = ents.PFMCamera.get_active_camera()
				if(util.is_valid(camC) == false) then return end
				tool.get_filmmaker():ShowInElementViewer(camC:GetCameraData())
			end)
		end
		pContext:AddItem(locale.get_text("pfm_auto_aim_work_camera"),function() end) -- TODO
	end)
	self:SwitchToSceneCamera()
	self.m_btGear = gui.PFMButton.create(controls,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("TODO")
	end)
	controls:SetHeight(self.m_btAutoAim:GetHeight())
	controls:Update()
	controls:SetX(self.m_controls:GetWidth() -controls:GetWidth() -3)
	controls:SetAnchor(1,1,1,1)
	self.manipulatorControls = controls
end
function gui.PFMViewport:IsGameplayEnabled() return self.m_gameplayEnabled end
function gui.PFMViewport:IsInCameraControlMode() return self.m_inCameraControlMode end
function gui.PFMViewport:SetGameplayMode(enabled)
	input.set_binding_layer_enabled("pfm_viewport",enabled)
	input.update_effective_input_bindings()

	if(enabled) then
		self.m_oldCursorPos = input.get_cursor_pos()
		if(self:IsGameplayEnabled() == false) then self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_FLY) end
		input.center_cursor()

		local window = self:GetRootWindow()
		gui.set_focus_enabled(window,false)

		local filmmaker = tool.get_filmmaker()
		-- filmmaker:TrapFocus(false)
		-- filmmaker:KillFocus()
		filmmaker:TagRenderSceneAsDirty(true)

		self.m_oldInputLayerStates = {}
		local inputLayers = filmmaker:GetInputBindingLayers()
		for id,layer in pairs(inputLayers) do
			if(id ~= "pfm_viewport") then
				self.m_oldInputLayerStates[id] = input.is_binding_layer_enabled(id)
				input.set_binding_layer_enabled(id,false)
			end
		end
		input.update_effective_input_bindings()

		self.m_inCameraControlMode = true
		self:UpdateWorkCamera()
	else
		if(self:IsGameplayEnabled() == false) then self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_PLAYBACK) end

		local window = self:GetRootWindow()
		gui.set_focus_enabled(window,true)

		local filmmaker = tool.get_filmmaker()
		-- filmmaker:TrapFocus(true)
		-- filmmaker:RequestFocus()
		filmmaker:TagRenderSceneAsDirty(false)
		input.set_cursor_pos(self.m_oldCursorPos)

		if(self.m_oldInputLayerStates ~= nil) then
			for id,state in pairs(self.m_oldInputLayerStates) do
				input.set_binding_layer_enabled(id,state)
			end
			self.m_oldInputLayerStates = nil
			input.update_effective_input_bindings()
		end

		self.m_inCameraControlMode = false
	end
end
function gui.PFMViewport:OnThink()
	if(self.m_cursorTracker ~= nil) then
		self.m_cursorTracker:Update()
		if(not self.m_cursorTracker:HasExceededMoveThreshold(2)) then return end
		self.m_cursorTracker = nil
		self:DisableThinking()

		self:SetGameplayMode(true)
		return
	end
	local scene = self.m_viewport:GetScene()
	local cam = util.is_valid(scene) and scene:GetActiveCamera() or nil
	if(util.is_valid(cam) == false or self.m_camStartPose == nil) then return end
	local pose = cam:GetEntity():GetPose()
	if(pose:GetOrigin():DistanceSqr(self.m_camStartPose:GetOrigin()) < 0.01 and pose:GetRotation():Distance(self.m_camStartPose:GetRotation()) < 0.01) then return end
	if(util.is_valid(self.m_rtViewport)) then self.m_rtViewport:MarkActorAsDirty(cam:GetEntity()) end
	self.m_camStartPose = pose:Copy()
end
function gui.PFMViewport:SwitchToGameplay(enabled)
	if(enabled == nil) then enabled = true end
	if(enabled == self.m_gameplayEnabled) then return end
	self.m_gameplayEnabled = enabled

	local pl = ents.get_local_player()
	if(enabled) then
		self:SwitchToWorkCamera(true)
		self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_WALK)
		if(pl ~= nil) then pl:SetObserverMode(ents.PlayerComponent.OBSERVERMODE_THIRDPERSON) end
	else
		self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_PLAYBACK)
		if(pl ~= nil) then pl:SetObserverMode(ents.PlayerComponent.OBSERVERMODE_FIRSTPERSON) end
	end
end
function gui.PFMViewport:GetWorkCamera()
	if(self.m_viewport:IsPrimaryGameSceneViewport()) then return game.get_primary_camera() end
	return self.m_viewport:GetSceneCamera()
end
function gui.PFMViewport:GetSceneCamera()
	local filmClip = pfm.get_project_manager():GetActiveGameViewFilmClip()
	local actor = (filmClip ~= nil) and filmClip:GetCamera() or nil
	local ent = (actor ~= nil) and actor:FindEntity() or nil
	if(util.is_valid(ent) == false) then return end
	return ent:GetComponent(ents.COMPONENT_CAMERA)
end
function gui.PFMViewport:SwitchToCamera(cam)
	local scene = self.m_viewport:GetScene()
	if(util.is_valid(scene)) then
		scene:SetActiveCamera(cam)
	end
	pfm.tag_render_scene_as_dirty()
end
function gui.PFMViewport:RefreshCamera()
	if(self:IsSceneCamera()) then self:SwitchToSceneCamera()
	else self:SwitchToWorkCamera() end
end
function gui.PFMViewport:SwitchToSceneCamera()
	self:SwitchToGameplay(false)
	local cam = self:GetSceneCamera()
	if(util.is_valid(cam)) then
		self:SwitchToCamera(cam)
		local name = cam:GetEntity():GetName()
		if(#name == 0) then name = locale.get_text("pfm_scene_camera") end
		self.m_btCamera:SetText(name)

		self.m_cameraView = gui.PFMViewport.CAMERA_VIEW_SCENE
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
function gui.PFMViewport:UpdateWorkCamera()
	local cam = self:GetWorkCamera()
	if(util.is_valid(cam) == false) then return end
	local pose = cam:GetEntity():GetPose()
	self:SetWorkCameraPose(pose)
	game.set_gameplay_control_camera(cam)
end
function gui.PFMViewport:SetWorkCameraPose(pose)
	local cam = self:GetWorkCamera()
	if(util.is_valid(cam) == false) then return end
	local pos = pose:GetOrigin()
	local ang = pose:GetRotation():ToEulerAngles()
	local pl = ents.get_local_player()
	if(util.is_valid(pl)) then pos = pos -pl:GetViewOffset() end
	console.run("setpos",tostring(pos.x),tostring(pos.y),tostring(pos.z))
	console.run("setang",tostring(ang.p),tostring(ang.y),0.0)
end
function gui.PFMViewport:SwitchToWorkCamera(ignoreGameplay)
	if(ignoreGameplay ~= true) then self:SwitchToGameplay(false) end
	local cam = self:GetWorkCamera()
	if(util.is_valid(cam)) then self:SwitchToCamera(cam) end
	if(util.is_valid(self.m_btCamera)) then self.m_btCamera:SetText(locale.get_text("pfm_work_camera")) end

	self.m_cameraView = gui.PFMViewport.CAMERA_VIEW_GAME
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
function gui.PFMViewport:CopyToCamera(camSrc,camDst)

end
function gui.PFMViewport:IsSceneCamera() return self.m_cameraView == gui.PFMViewport.CAMERA_VIEW_SCENE end
function gui.PFMViewport:IsWorkCamera() return not self:IsSceneCamera() end
function gui.PFMViewport:ToggleCamera()
	if(self:IsSceneCamera()) then self:SwitchToWorkCamera()
	else self:SwitchToSceneCamera() end
end
function gui.PFMViewport:GetPlayButton() return self.m_btPlay end
function gui.PFMViewport:GetViewport() return self.m_viewport end
function gui.PFMViewport:OnSizeChanged(w,h)
	self:Update()
end
function gui.PFMViewport:OnUpdate()
	if(util.is_valid(self.m_timeLocal)) then
		self.m_timeLocal:SetX(self.m_titleBar:GetWidth() -self.m_timeLocal:GetWidth() -20)
	end
	self:UpdateFilmLabelPositions()
end
gui.register("WIPFMViewport",gui.PFMViewport)

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
include("/gui/draganddrop.lua")
include("/gui/playbackcontrols.lua")
include("/gui/raytracedviewport.lua")
include("/pfm/fonts.lua")

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
function gui.PFMViewport:__init()
	gui.PFMBaseViewport.__init(self)
end
function gui.PFMViewport:OnInitialize()
	self.m_vrControllers = {}
	self.m_manipulatorMode = gui.PFMViewport.MANIPULATOR_MODE_SELECT

	gui.PFMBaseViewport.OnInitialize(self)

	self.m_titleBar:SetHeight(37)

	self.m_gameplayEnabled = false
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

	self.m_ctrlRt = p:AddDropDownMenu(locale.get_text("pfm_viewport_rt_enabled"),"rt_enabled",{
		{"0",locale.get_text("disabled")},
		{"1",locale.get_text("enabled")}
	},0)
	self.m_ctrlRt:AddCallback("OnOptionSelected",function(el,idx)
		self:SetRtViewportEnabled(idx == 1)
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
function gui.PFMViewport:SetRtViewportEnabled(enabled)
	console.run("cl_max_fps",enabled and "24" or "-1") -- Clamp max fps to make more resources available for the renderer
	util.remove(self.m_rtViewport)
	if(enabled ~= true) then return end
	local rtViewport = gui.create("WIRealtimeRaytracedViewport",self.m_vpContainer,0,0,self.m_vpContainer:GetWidth(),self.m_vpContainer:GetHeight(),0,0,1,1)
	self.m_rtViewport = rtViewport

	self:UpdateRenderSettings()
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

	local filmmaker = tool.get_filmmaker()
	if(self.m_inCameraControlMode and mouseButton == input.MOUSE_BUTTON_RIGHT and state == input.STATE_RELEASE and filmmaker:IsValid() and filmmaker:HasFocus() == false) then
		if(self:IsGameplayEnabled() == false) then self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_PLAYBACK) end
		filmmaker:TrapFocus(true)
		filmmaker:RequestFocus()
		filmmaker:TagRenderSceneAsDirty(false)
		input.set_cursor_pos(self.m_oldCursorPos)
		self.m_inCameraControlMode = false
		return util.EVENT_REPLY_HANDLED
	end

	local el = gui.get_element_under_cursor()
	if(util.is_valid(el) and (el == self or el:IsDescendantOf(self))) then
		if(mouseButton == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			self.m_oldCursorPos = input.get_cursor_pos()
			if(self:IsGameplayEnabled() == false) then self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_FLY) end
			input.center_cursor()

			filmmaker:TrapFocus(false)
			filmmaker:KillFocus()
			filmmaker:TagRenderSceneAsDirty(true)
			self.m_inCameraControlMode = true
		elseif(mouseButton == input.MOUSE_BUTTON_LEFT) then
			self.m_viewport:RequestFocus()
			local filter
			if(self.m_manipulatorMode ~= gui.PFMViewport.MANIPULATOR_MODE_SELECT) then
				filter = function(ent,mdlC)
					return not ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
				end
			end
			local handled,entActor = ents.ClickComponent.inject_click_input(input.ACTION_ATTACK,state == input.STATE_PRESS,filter)
			if(handled == util.EVENT_REPLY_UNHANDLED and util.is_valid(entActor)) then
				local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
				local actor = (actorC ~= nil) and actorC:GetActorData() or nil
				if(actor) then filmmaker:SelectActor(actor) end
			end
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMViewport:OnRemove()
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
		local item = actorEditor:GetActorComponentItem(actorData,"pfm_model")
		local itemSkeleton = util.is_valid(item) and item:GetItemByIdentifier("skeleton") or nil
		if(util.is_valid(itemSkeleton) == false) then return end
		for _,item in ipairs(itemSkeleton:GetItems()) do
			if(item:IsValid() and item:IsSelected()) then
				if(boneName ~= nil) then
					boneName = nil -- Only enable if exactly one bone is selected
					break
				end
				boneName = item:GetIdentifier()
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
		update_channel_value(boneId,localPos,"position")
		tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_ROTATION_CHANGED,function(boneId,rot,localRot)
		update_channel_value(boneId,localRot,"rotation")
		tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
	trBone:AddEventCallback(ents.UtilBoneTransformComponent.EVENT_ON_SCALE_CHANGED,function(boneId,scale,localScale)
		update_channel_value(boneId,localScale,"scale")
		tool.get_filmmaker():TagRenderSceneAsDirty()
	end)
end
function gui.PFMViewport:UpdateActorManipulation(ent,selected)
	ent:RemoveComponent("util_bone_transform")
	ent:RemoveComponent("util_transform")

	local function add_transform_component()
		local trC = ent:GetComponent("util_transform")
		if(trC ~= nil) then return trC end
		trC = ent:AddComponent("util_transform")
		if(trC == nil) then return trC end
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED,function()
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				local actorData = actorC:GetActorData()
				if(actorData ~= nil) then
					local transform = actorData:GetTransform()
					transform:SetPosition(ent:GetPos())
				end
			end
			tool.get_filmmaker():TagRenderSceneAsDirty()
		end)
		trC:AddEventCallback(ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED,function()
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				local actorData = actorC:GetActorData()
				if(actorData ~= nil) then
					local transform = actorData:GetTransform()
					transform:SetRotation(ent:GetRotation())
				end
			end
			tool.get_filmmaker():TagRenderSceneAsDirty()
		end)
		return trC
	end
	ent:RemoveComponent("util_transform")
	local manipMode = self.m_manipulatorMode
	if(selected and (self:IsMoveManipulatorMode(manipMode) or self:IsRotationManipulatorMode(manipMode))) then
		local tc = add_transform_component()
		self:InitializeTransformWidget(tc,ent)
	end
	tool.get_filmmaker():TagRenderSceneAsDirty()
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
		pSubMenu:AddItem(locale.get_text("pfm_new_camera"),function() end) -- TODO
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
function gui.PFMViewport:SwitchToSceneCamera()
	self:SwitchToGameplay(false)
	local camScene = ents.PFMCamera.get_active_camera()
	local camName = ""
	if(util.is_valid(camScene)) then
		local camData = camScene:GetCameraData()
		if(util.is_valid(self.m_btCamera)) then camName = camData:GetName() end
	end
	if(#camName == 0) then camName = locale.get_text("pfm_scene_camera") end
	self.m_btCamera:SetText(camName)
	ents.PFMCamera.set_camera_enabled(true)
end
function gui.PFMViewport:SwitchToWorkCamera(ignoreGameplay)
	if(ignoreGameplay ~= true) then self:SwitchToGameplay(false) end
	if(util.is_valid(self.m_btCamera)) then self.m_btCamera:SetText(locale.get_text("pfm_work_camera")) end
	ents.PFMCamera.set_camera_enabled(false)
end
function gui.PFMViewport:CopyToCamera(camSrc,camDst)

end
function gui.PFMViewport:IsSceneCamera() return ents.PFMCamera.is_camera_enabled() end
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

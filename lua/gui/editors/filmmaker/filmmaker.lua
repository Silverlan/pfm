--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_filmmaker.lua")

util.register_class("gui.WIFilmmaker", gui.WIBaseFilmmaker)

include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/gui/filmstrip.lua")
include("/gui/genericclip.lua")
include("/gui/witabbedpanel.lua")
include("/gui/editors/wieditorwindow.lua")
include("/gui/patreon_ticker.lua")
include("/gui/bone_retargeting.lua")
include("/gui/ik_rig_editor.lua")
include("/gui/pfm/viewport/viewport.lua")
include("/gui/pfm/message_prompt.lua")
include("/gui/pfm/postprocessing.lua")
include("/gui/pfm/videoplayer.lua")
include("/gui/pfm/timeline.lua")
include("/gui/pfm/elementviewer.lua")
include("/gui/pfm/actor_editor/actor_editor.lua")
include("/gui/pfm/modelcatalog.lua")
include("/gui/pfm/materialcatalog.lua")
include("/gui/pfm/particlecatalog.lua")
include("/gui/pfm/tutorialcatalog.lua")
include("/gui/pfm/actorcatalog.lua")
include("/gui/pfm/renderpreview.lua")
include("/gui/pfm/material_editor/materialeditor.lua")
include("/gui/pfm/particleeditor.lua")
include("/gui/pfm/webbrowser.lua")
include("/gui/pfm/code_editor.lua")
include("/gui/pfm/loading_screen.lua")
include("/gui/pfm/settings.lua")
include("/gui/pfm/kernels_build_message.lua")
include("/gui/pfm/progress_status_info.lua")
include("/pfm/util_particle_system.lua")
include("/pfm/auto_save.lua")
include("/pfm/util.lua")
include("/util/table_bininsert.lua")
include("filmmaker")

gui.load_skin("pfm")
locale.load("pfm_user_interface.txt")
locale.load("pfm_popup_messages.txt")
locale.load("pfm_loading.txt")
locale.load("pfm_components.txt")
locale.load("physics_materials.txt")
locale.load("pfm_render_panel.txt")
locale.load("pfm_context_menues.txt")

include("windows")
include("video_recorder.lua")
include("selection_manager.lua")
include("animation_export.lua")
include("layout.lua")
include("update.lua")
include("windows.lua")
include("tutorials.lua")
include("global_state_data.lua")

include_component("pfm_camera")
include_component("pfm_sound_source")
include_component("pfm_grid")

local function updateAutosave()
	local fm = tool.get_filmmaker()
	if util.is_valid(fm) then
		fm:UpdateAutosave()
	end
end
console.add_change_callback("pfm_autosave_enabled", updateAutosave)
console.add_change_callback("pfm_autosave_time_interval", updateAutosave)
console.register_variable(
	"pfm_keep_current_layout",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Keep the current layout when opening a project."
)

local loadedSubAddons = false
local function load_sub_addons()
	if loadedSubAddons then
		return
	end
	loadedSubAddons = true

	for _, subAddon in ipairs({ "debug_ik" }) do
		local res = engine.mount_sub_addon(subAddon)
		if res == false then
			pfm.log("Failed to mount addon '" .. subAddon .. "'!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		end
	end
end

function gui.WIFilmmaker:__init()
	gui.WIBaseFilmmaker.__init(self)
	load_sub_addons()
end
include("/pfm/bake/ibl.lua")
function gui.WIFilmmaker:OnInitialize()
	self:SetDeveloperModeEnabled(tool.is_developer_mode_enabled())

	gui.WIBaseFilmmaker.OnInitialize(self)
	tool.editor = self -- TODO: This doesn't really belong here (check lua/autorun/client/cl_filmmaker.lua)
	tool.filmmaker = self

	self:SetName("pfm")
	gui.set_context_menu_skin("pfm")
	gui.get_primary_window():SetResizable(true)

	-- Sleep mode is enabled by default, but will be disabled tempoarily if there is a continuous process going on (e.g. rendering).
	os.set_prevent_os_sleep_mode(false)

	local elConsole = gui.get_console()
	if util.is_valid(elConsole) then
		elConsole:SetExternallyOwned(true)
	end

	local windowTitle = ""
	local window = gui.get_primary_window()
	if util.is_valid(window) then
		windowTitle = window:GetWindowTitle()
	end
	self.m_originalWindowTitle = windowTitle

	self.m_editorOverlayRenderMask = game.register_render_mask("pfm_editor_overlay", false)
	self.m_worldAxesGizmo = ents.create("pfm_world_axes_gizmo")
	self.m_worldAxesGizmo:Spawn()

	self.m_pfmManager = ents.create("entity")
	self.m_pfmManager:AddComponent("pfm_manager")
	self.m_pfmManager:Spawn()

	local udmData, err = udm.load("cfg/pfm/settings.udm")
	if udmData ~= false then
		udmData = udmData:GetAssetData():GetData()
		self.m_settings = udmData:ClaimOwnership()
	else
		self.m_settings = udm.create_element()
	end

	self:LoadGlobalStateData()
	self:InitializeBindingLayers()

	local infoBar = self:GetInfoBar()

	local infoBarContents = infoBar:GetContents()
	local patronTickerContainer = gui.create(
		"PatreonTicker",
		infoBarContents,
		0,
		0,
		infoBarContents:GetWidth(),
		infoBarContents:GetHeight(),
		0,
		0,
		1,
		1
	)
	patronTickerContainer:SetQueryUrl("http://pragma-engine.com/patreon/request_patrons.php")
	local engineInfo = engine.get_info()
	infoBar:AddIcon("third_party/patreon_logo_small", pfm.PATREON_JOIN_URL, "Patreon", function(url)
		self:ShowMatureContentPrompt(function()
			util.open_url_in_browser(url)
		end)
	end)

	-- infoBar:AddIcon("third_party/twitter_logo",engineInfo.twitterURL,"Twitter")
	-- infoBar:AddIcon("third_party/reddit_logo",engineInfo.redditURL,"Reddit")
	infoBar:AddIcon("third_party/github_logo_small", engineInfo.gitHubURL, "GitHub")
	infoBar:AddIcon("third_party/discord_logo_small", engineInfo.discordURL, "Discord")

	local gap = gui.create("WIBase")
	gap:SetSize(10, 1)
	infoBar:AddRightElement(gap)

	local gap = gui.create("WIBase")
	gap:SetSize(10, 1)
	infoBar:AddRightElement(gap, 0)

	infoBar:Update()

	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	gameRenderer:GetEntity():AddComponent(ents.COMPONENT_RENDERER_PP_VOLUMETRIC)
	local scene = ents.create_scene(sceneCreateInfo) -- ,gameScene)
	scene:SetRenderer(gameRenderer)
	local cam = gameScene:GetActiveCamera()
	if cam ~= nil then
		scene:SetActiveCamera(cam)
	end
	self.m_overlayScene = scene

	local sceneDepth = ents.create_scene(sceneCreateInfo, gameScene)
	sceneDepth:SetRenderer(gameRenderer)
	if cam ~= nil then
		sceneDepth:SetActiveCamera(cam)
	end
	self.m_sceneDepth = sceneDepth

	gameScene:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(), self.m_editorOverlayRenderMask))
	scene:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(), self.m_editorOverlayRenderMask))
	sceneDepth:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(), self.m_editorOverlayRenderMask))

	-- Disable default scene drawing for the lifetime of the Filmmaker; We'll only render the viewport(s) if something has actually changed, which
	-- saves up a huge amount of rendering resources.
	self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes", function(drawSceneInfo)
		self:PreRenderScenes(drawSceneInfo)
	end)
	self.m_cbOnRenderTargetResized = game.add_callback("OnRenderTargetResized", function()
		local vp = self:GetViewport()
		if util.is_valid(vp) then
			vp:UpdateAspectRatio()
		end
	end)
	self.m_cbDisableDefaultSceneDraw = game.add_callback("RenderScenes", function(drawSceneInfo)
		if self.m_renderSceneDirty == nil then
			game.set_default_game_render_enabled(false)
			return
		end
		drawSceneInfo.renderFlags = bit.band(drawSceneInfo.renderFlags, bit.bnot(game.RENDER_FLAG_BIT_VIEW))
		self.m_renderSceneDirty = self.m_renderSceneDirty - 1
		if self.m_renderSceneDirty == 0 then
			self.m_renderSceneDirty = nil
		end
		return false
	end)
	self.m_cbOnWindowShouldClose = game.add_callback("OnWindowShouldClose", function(window)
		if window == gui.get_primary_window() then
			self:ShowCloseConfirmation(function(res)
				tool.close_filmmaker()
				engine.shutdown()
			end)
			return false
		end
		return true
	end)
	self.m_cbOnLuaError = game.add_callback("OnLuaError", function(err)
		self:OnLuaError(err)
	end)
	game.set_default_game_render_enabled(false)

	self:EnableThinking()
	self:SetSize(1280, 1024)
	self:SetSkin("pfm")
	self.m_selectionManager = pfm.ActorSelectionManager()
	self.m_selectionManager:AddChangeListener(function(ent, selected)
		self:OnActorSelectionChanged(ent, selected)
	end)
	local pMenuBar = self:GetMenuBar()
	self.m_menuBar = pMenuBar

	self:InitializeMenuBar()

	-- Version Info
	local engineInfo = engine.get_info()
	local versionString = "v" .. pfm.VERSION:ToString()
	local sha = pfm.get_git_sha("addons/filmmaker/git_info.txt")
	if sha ~= nil then
		versionString = versionString .. ", " .. sha
	end
	versionString = versionString .. " [P " .. engineInfo.prettyVersion
	local gitInfo = engine.get_git_info()
	if gitInfo ~= nil then
		-- Pragma SHA
		versionString = versionString .. ", " .. gitInfo.commitSha:sub(0, 7)
	end
	versionString = versionString .. "]"
	local elVersion = gui.create("WIText", pMenuBar)
	elVersion:SetColor(Color.White)
	elVersion:SetText(versionString)
	elVersion:SetFont("pfm_medium")
	elVersion:SetColor(Color(200, 200, 200))
	elVersion:SetY(5)
	elVersion:SizeToContents()
	elVersion:SetCursor(gui.CURSOR_SHAPE_HAND)
	elVersion:SetMouseInputEnabled(true)
	elVersion:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			util.set_clipboard_string(elVersion:GetText())
			pfm.create_popup_message(locale.get_text("pfm_version_copied_to_clipboard"), 3)
			return util.EVENT_REPLY_HANDLED
		end
	end)
	elVersion:AddCallback("OnCursorEntered", function()
		elVersion:SetColor(Color.White)
	end)
	elVersion:AddCallback("OnCursorExited", function()
		elVersion:SetColor(Color(200, 200, 200))
	end)

	elVersion:SetX(pMenuBar:GetWidth() - elVersion:GetWidth() - 4)
	elVersion:SetY(3)
	elVersion:SetAnchor(1, 0, 1, 0)
	log.info("PFM Version: " .. versionString)

	local elBeta = gui.create("WIText", pMenuBar)
	elBeta:SetColor(Color.Red)
	elBeta:SetText("BETA | ")
	elBeta:SetFont("pfm_medium")
	elBeta:SetY(3)
	elBeta:SizeToContents()
	elBeta:SetX(elVersion:GetLeft() - elBeta:GetWidth())
	elBeta:SetAnchor(1, 0, 1, 0)

	if console.get_convar_bool("pfm_should_check_for_updates") then
		console.run("pfm_should_check_for_updates", "0") -- Only auto-check once per session
		time.create_simple_timer(5.0, function()
			if self:IsValid() == false then
				return
			end
			self:CheckForUpdates()
		end)
	end
	--

	console.run("cl_max_fps", tostring(console.get_convar_int("pfm_max_fps")))
	-- Smooth camera acceleration
	console.run("sv_acceleration_ramp_up_time", tostring(0.5))

	--[[local framePlaybackControls = gui.create("WIFrame",self)
	framePlaybackControls:SetCloseButtonEnabled(false)
	local playbackControls = gui.create("PlaybackControls",framePlaybackControls)
	playbackControls:SetX(10)
	playbackControls:SetY(24)
	playbackControls:SetWidth(512)
	playbackControls:AddCallback("OnProgressChanged",function(playbackControls,progress,timeOffset)
		if(util.is_valid(self.m_gameView)) then
			local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
			if(projectC ~= nil) then projectC:SetOffset(timeOffset) end

			local project = self:GetProject()
			project:SetPlaybackOffset(timeOffset)
		end
	end)
	playbackControls:AddCallback("OnStateChanged",function(playbackControls,oldState,newState)
		ents.PFMSoundSource.set_audio_enabled(newState == gui.PlaybackControls.STATE_PLAYING)
	end)
	self.m_playbackControls = playbackControls

	local buttonScreenshot = gui.create("WITexturedRect",framePlaybackControls)
	buttonScreenshot:SetMaterial("gui/pfm/photo_camera")
	buttonScreenshot:SetSize(20,20)
	buttonScreenshot:SetTop(playbackControls:GetTop() +1)
	buttonScreenshot:SetLeft(playbackControls:GetRight() +10)
	buttonScreenshot:SetMouseInputEnabled(true)
	buttonScreenshot:AddCallback("OnMousePressed",function()
		self:CaptureRaytracedImage()
	end)

	local buttonRecord = gui.create("WITexturedRect",framePlaybackControls)
	buttonRecord:SetMaterial("gui/pfm/video_camera")
	buttonRecord:SetSize(20,20)
	buttonRecord:SetTop(playbackControls:GetTop() +1)
	buttonRecord:SetLeft(buttonScreenshot:GetRight() +10)
	buttonRecord:SetMouseInputEnabled(true)
	buttonRecord:AddCallback("OnMousePressed",function()
		if(self:IsRecording() == false) then
			self:StartRecording("pfmtest.avi")
		else
			self:StopRecording()
		end
	end)

	local wFrame = buttonRecord:GetRight() +10
	local hFrame = playbackControls:GetBottom() +20
	framePlaybackControls:SetMaxHeight(hFrame)
	framePlaybackControls:SetMinHeight(hFrame)
	framePlaybackControls:SetMinWidth(128)
	framePlaybackControls:SetMaxWidth(1024)
	framePlaybackControls:SetWidth(wFrame)
	framePlaybackControls:SetHeight(hFrame)
	framePlaybackControls:SetPos(128,900)

	buttonScreenshot:SetAnchor(1,0.5,1,0.5)
	buttonRecord:SetAnchor(1,0.5,1,0.5)
	playbackControls:SetAnchor(0,0,1,1)

	local progressBar = playbackControls:GetProgressBar()
	local raytracingProgressBar = gui.create("WIProgressBar",framePlaybackControls)
	raytracingProgressBar:SetSize(progressBar:GetWidth(),10)
	raytracingProgressBar:SetLeft(playbackControls:GetLeft() +progressBar:GetLeft())
	raytracingProgressBar:SetTop(playbackControls:GetBottom())
	raytracingProgressBar:SetColor(Color.Lime)
	raytracingProgressBar:SetVisible(false)
	raytracingProgressBar:SetAnchor(0,0,1,1)
	self.m_raytracingProgressBar = raytracingProgressBar

	self.m_previewWindow = gui.PFMRenderPreviewWindow(self)
	self.m_renderResultWindow = gui.PFMRenderResultWindow(self)
	self.m_previewWindow:GetFrame():SetY(24)
	self.m_renderResultWindow:GetFrame():SetY(self.m_previewWindow:GetFrame():GetBottom() +10)
	self.m_videoRecorder = pfm.VideoRecorder()

	local btCam = gui.create_button("Toggle Camera",self,100,20)
	btCam:AddCallback("OnPressed",function()
		self:SetCameraMode((self.m_cameraMode +1) %gui.WIFilmmaker.CAMERA_MODE_COUNT)
	end)]]

	self.m_tLastCursorMove = 0.0
	if unirender ~= nil then
		unirender.set_log_enabled(pfm.is_log_category_enabled(pfm.LOG_CATEGORY_PFM_UNIRENDER))
	end
	self:SetKeyboardInputEnabled(true)
	self:ClearProjectUI()

	--[[local entProbe = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE)})()
	if(entProbe == nil) then
		pfm.log("No reflection probe found, creating default probe...",pfm.LOG_CATEGORY_PFM)
		local entReflectionProbe = ents.create("env_reflection_probe")
		entReflectionProbe:SetKeyValue("ibl_material","pbr/ibl/venice_sunset")
		entReflectionProbe:SetKeyValue("ibl_strength","1.4")
		entReflectionProbe:Spawn()
		self.m_reflectionProbe = entReflectionProbe
	end]]
	pfm.call_event_listeners("OnFilmmakerLaunched", self)
	pfm.ProjectManager.OnInitialize(self)
	self:SetCachedMode(false)

	self:GetAnimationManager():AddCallback("OnAnimationChannelAdded", function()
		local actorEditor = self:GetActorEditor()
		if util.is_valid(actorEditor) then
			actorEditor:SetPropertyAnimationOverlaysDirty()
		end
	end)
	self:GetAnimationManager():AddCallback("OnActorPropertyChanged", function(actor, path)
		pfm.tag_render_scene_as_dirty()

		local actorEditor = self:GetActorEditor()
		if util.is_valid(actorEditor) then
			actorEditor:UpdateActorProperty(actor, path)
		end
	end)

	if self:ShouldDisplayNotification("initial_tutorial_message") then
		time.create_simple_timer(5.0, function()
			if self:IsValid() == false then
				return
			end
			local msg = pfm.open_message_prompt(
				locale.get_text("pfm_initial_tutorial_title"),
				locale.get_text("pfm_initial_tutorial_message"),
				gui.PfmPrompt.BUTTON_NONE,
				function(bt)
					self:SetNotificationAsDisplayed("initial_tutorial_message")
					if bt == "start_tutorial" then
						time.create_simple_timer(0.0, function()
							if self:IsValid() then
								self:ShowCloseConfirmation(function(res)
									self:LoadTutorial("intro")
								end)
							end
						end)
					end
				end
			)
			msg:AddButton("start_tutorial", locale.get_text("pfm_initial_tutorial_start_tutorial"))
			msg:AddButton("skip_tutorial", locale.get_text("pfm_initial_tutorial_skip_tutorial"))
		end)
	end

	self:SetSkinCallbacksEnabled(true)
	pfm.call_event_listeners("OnFilmmakerInitialized", self)
end
function gui.WIFilmmaker:GetRenderOutputPath()
	return util.Path(util.get_addon_path() .. "render/"):GetString()
end
function gui.WIFilmmaker:ShouldDisplayNotification(id, markAsDisplayed)
	markAsDisplayed = markAsDisplayed or false
	local udmNotifications = self.m_settings:Get("notifications")
	local res = (udmNotifications:GetValue(id, udm.TYPE_BOOLEAN) or false) == false
	if res and markAsDisplayed then
		self:SetNotificationAsDisplayed(id)
	end
	return res
end
function gui.WIFilmmaker:SetNotificationAsDisplayed(id)
	local udmNotifications = self.m_settings:Get("notifications")
	udmNotifications:SetValue(id, udm.TYPE_BOOLEAN, true)
end
function gui.WIFilmmaker:ShowMatureContentPrompt(onYes, onNo)
	if console.get_convar_bool("pfm_web_browser_enable_mature_content") then
		onYes()
		return
	end
	local ctrl, wrapper
	local msg = pfm.open_message_prompt(
		locale.get_text("pfm_content_warning"),
		locale.get_text("pfm_content_warning_website"),
		bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO),
		function(bt)
			if bt == gui.PfmPrompt.BUTTON_YES then
				if ctrl:IsChecked() then
					console.run("pfm_web_browser_enable_mature_content", "1")
				end
				onYes()
			elseif bt == gui.PfmPrompt.BUTTON_NO then
				if onNo ~= nil then
					onNo()
				end
			end
		end
	)
	local userContents = msg:GetUserContents()

	local p = gui.create("WIPFMControlsMenu", userContents)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)

	ctrl, wrapper = p:AddToggleControl(pfm.LocStr("pfm_remember_my_choice"), "remember_my_choice", false)
	p:SetWidth(200)
	p:Update()
	p:SizeToContents()
	p:ResetControls()

	gui.create("WIBase", userContents, 0, 0, 1, 12) -- Gap
end
function gui.WIFilmmaker:OnLuaError(err)
	local t = time.real_time()
	if self.m_lastLuaError ~= nil then
		if t - self.m_lastLuaError < 5.0 then
			return
		end
	end
	self.m_lastLuaError = t

	pfm.create_popup_message(locale.get_text("pfm_script_error_occurred"), 4, gui.InfoBox.TYPE_ERROR)
end
function gui.WIFilmmaker:SaveProject(...)
	self:SaveUndoRedoStack()
	self:SaveUiState()
	return gui.WIBaseFilmmaker.SaveProject(self, ...)
end
function gui.WIFilmmaker:SaveUiState()
	local session = self:GetSession()
	if session == nil then
		return
	end

	local udmData = session:GetUdmData()
	udmData:RemoveValue("uiState")

	local udmUiState = udmData:Add("uiState")
	local udmWindows = udmUiState:Add("windows")

	for id, elWindow in pairs(self:GetWindows()) do
		if elWindow.SaveUiState ~= nil then
			local udmWindow = udmWindows:Add(id)
			elWindow:SaveUiState(udmWindow)
		end
	end
end
function gui.WIFilmmaker:RestoreUiState()
	local session = self:GetSession()
	if session == nil then
		return
	end

	local udmData = session:GetUdmData()
	local udmUiState = udmData:Get("uiState")
	if udmUiState:IsValid() == false then
		return
	end
	local udmWindows = udmUiState:Get("windows")
	if udmWindows:IsValid() == false then
		return
	end

	for id, elWindow in pairs(self:GetWindows()) do
		if elWindow.RestoreUiState ~= nil then
			local udmWindow = udmWindows:Get(id)
			if udmWindow:IsValid() then
				elWindow:RestoreUiState(udmWindow)
			end
		end
	end
end
function gui.WIFilmmaker:SaveUndoRedoStack()
	local session = self:GetSession()
	if session == nil then
		return
	end

	local udmSession = session:GetUdmData()
	udmSession:RemoveValue("undoredo")

	if not console.get_convar_bool("pfm_save_undo_stack") then
		return
	end
	local udmUndoRedo = udmSession:Add("undoredo")
	pfm.undoredo.serialize(udmUndoRedo)
end
function gui.WIFilmmaker:LoadUndoRedoStack()
	pfm.undoredo.clear()

	local session = self:GetSession()
	if session == nil then
		return
	end

	local udmSession = session:GetUdmData()
	local udmUndoRedo = udmSession:Get("undoredo")
	if udmUndoRedo:IsValid() == false then
		return
	end
	pfm.undoredo.deserialize(udmUndoRedo)
end
function gui.WIFilmmaker:ShowCloseConfirmation(action, callActionOnCancel)
	callActionOnCancel = callActionOnCancel or false
	if self:IsProjectEdited() == false then
		-- Nothing has been changed in the project, no reason to show the save prompt
		action(true)
		return
	end
	local fileName = self:GetProjectFileName() or locale.get_text("untitled")
	pfm.open_message_prompt(
		locale.get_text("pfm_prompt_save_changes"),
		locale.get_text("pfm_prompt_save_changes_message", { fileName }),
		bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO, gui.PfmPrompt.BUTTON_CANCEL),
		function(bt)
			if bt == gui.PfmPrompt.BUTTON_YES then
				self:Save(nil, nil, nil, nil, function(res)
					action(true)
				end)
			elseif bt == gui.PfmPrompt.BUTTON_NO then
				action(true)
			elseif bt == gui.PfmPrompt.BUTTON_NO and callActionOnCancel then
				action(false)
			end
		end
	)
end
function gui.WIFilmmaker:AddUndoMessage(msg)
	util.remove({ self.m_undoMessageElement, self.m_undoMessageTimer })
	local infoBar = self:GetInfoBar()

	local msgEl = gui.create("WIRect")
	msgEl:SetHeight(infoBar:GetHeight())
	msgEl:SetColor(Color(54, 54, 54))
	self.m_undoMessageElement = msgEl
	msgEl:AddCallback("OnRemove", function()
		if infoBar:IsValid() then
			infoBar:ScheduleUpdate()
		end
	end)

	local elText = gui.create("WIText", msgEl)
	elText:SetText(msg)
	elText:SetColor(Color(200, 200, 200))
	elText:SizeToContents()
	elText:CenterToParentY()
	elText:SetX(10)
	msgEl:SetWidth(elText:GetWidth() + 20)
	infoBar:AddRightElement(msgEl, 0)
	infoBar:Update()

	self.m_undoMessageTimer = time.create_timer(5, 0, function()
		if self:IsValid() == false then
			return
		end
		util.remove(self.m_undoMessageElement)
	end)
	self.m_undoMessageTimer:Start()

	return msgEl
end
function gui.WIFilmmaker:AddProgressStatusBar(identifier, text)
	local infoBar = self:GetInfoBar()

	local statusBar = gui.create("WIProgressStatusInfo")
	statusBar:SetName("status_info_" .. identifier)
	statusBar:SetText(text)
	statusBar:SetProgress(0.0)
	statusBar:SetHeight(infoBar:GetHeight())
	statusBar:AddCallback("OnRemove", function()
		if infoBar:IsValid() then
			infoBar:ScheduleUpdate()
		end
	end)
	infoBar:AddRightElement(statusBar, 0)

	infoBar:Update()
	return statusBar
end
function gui.WIFilmmaker:GetManagerEntity()
	return self.m_pfmManager
end
function gui.WIFilmmaker:GetWorldAxesGizmo()
	return self.m_worldAxesGizmo
end
function gui.WIFilmmaker:OnSkinApplied()
	self:GetMenuBar():Update()
end
function gui.WIFilmmaker:ClearActiveGameViewFilmClip()
	pfm.ProjectManager.ClearActiveGameViewFilmClip(self)
	self:GetAnimationManager():Reset()
end
function gui.WIFilmmaker:OnProjectInitialized(project)
	local session = self:GetSession()
	if session == nil then
		return
	end
	local settings = session:GetSettings():GetRenderSettings()
	settings:AddChangeListener("frameRate", function(renderSettings, frameRate)
		if util.is_valid(self.m_playhead) then
			self.m_playhead:SetFrameRate(frameRate)
			local offset = self.m_playhead:ClampTimeOffsetToFrameRate(self.m_playhead:GetTimeOffset())
			self.m_playhead:SetTimeOffset(offset)
		end
	end)
	if util.is_valid(self.m_playhead) then
		self.m_playhead:SetFrameRate(settings:GetFrameRate())
	end

	local track = session:GetFilmTrack()
	local cb = track:AddChangeListener("OnFilmClipTimeFramesUpdated", function(c)
		if self:IsValid() == false or self.m_filmStrip:IsValid() == false then
			return
		end
		for _, elFilmClip in ipairs(self.m_filmStrip:GetFilmClips()) do
			if elFilmClip:IsValid() then
				elFilmClip:UpdateFilmClipData()
			end
		end
	end)
	local cbNewFc = track:AddChangeListener("OnFilmClipAdded", function(c, newFc)
		if self:IsValid() == false or self.m_filmStrip:IsValid() == false then
			return
		end
		local elFc = self:AddFilmClipElement(newFc)
		self.m_timeline:GetTimeline():AddTimelineItem(elFc, newFc:GetTimeFrame())
	end)
	local cbFcRem = track:AddChangeListener("OnFilmClipRemoved", function(c, filmClip)
		if util.is_same_object(self:GetActiveGameViewFilmClip(), filmClip) then
			self:ClearActiveGameViewFilmClip()
		end

		local actorEditor = self:GetActorEditor()
		if util.is_valid(actorEditor) and util.is_same_object(actorEditor:GetFilmClip(), filmClip) then -- TODO: Game view film clip should be independent of actor editor film clip
			actorEditor:Clear()
		end

		local el = self.m_filmStrip:FindFilmClipElement(filmClip)
		if util.is_valid(el) == false then
			return
		end
		-- TODO: This probably requires some cleanup
		el:Remove()
	end)
	self.m_trackCallbacks = { cb, cbNewFc, cbFcRem }

	local activeClip = session:GetActiveClip()
	if activeClip ~= nil then
		activeClip:AddChangeListener("bookmarkSets", function(c, i, ev, oldVal)
			if ev == udm.BaseSchemaType.ARRAY_EVENT_ADD or ev == udm.BaseSchemaType.ARRAY_EVENT_REMOVE then
				self:UpdateBookmarks()
			end
		end)
	end
	self:UpdateBookmarks()
end
function gui.WIFilmmaker:RestoreWorkCamera()
	local session = self:GetSession()
	local vp = self:GetViewport()
	if session == nil or util.is_valid(vp) == false then
		return
	end
	local settings = session:GetSettings()
	local workCameraSettings = settings:GetWorkCamera()
	vp:SetWorkCameraPose(workCameraSettings:GetPose())
	local workCamera = vp:GetWorkCamera()
	if util.is_valid(workCamera) then
		workCamera:SetFOV(workCameraSettings:GetFov())
	end

	local camView = settings:GetCameraView()
	vp:SetCameraView(camView)
end
function gui.WIFilmmaker:UpdateWorkCamera(cameraView)
	local session = self:GetSession()
	local vp = self:GetViewport()
	if session == nil or util.is_valid(vp) == false then
		return
	end
	local settings = session:GetSettings()
	if vp:IsWorkCamera() then
		local cam = vp:GetWorkCamera()
		if util.is_valid(cam) == false then
			return
		end
		local workCamera = settings:GetWorkCamera()
		workCamera:SetPose(math.Transform(cam:GetEntity():GetPose()))
		workCamera:SetFov(cam:GetFOV())
	end
	cameraView = cameraView or vp:GetCameraView()
	if cameraView ~= nil then
		settings:SetCameraView(cameraView)
	end
end
function gui.WIFilmmaker:SaveSettings()
	local udmData, err = udm.create("PFMST", 1)
	local assetData = udmData:GetAssetData()
	assetData:GetData():Merge(self.m_settings:Get())
	file.create_path("cfg/pfm")
	local f = file.open("cfg/pfm/settings.udm", file.OPEN_MODE_WRITE)
	if f ~= nil then
		udmData:SaveAscii(f)
		f:Close()
	end
end

function gui.WIFilmmaker:GetOverlayScene()
	return self.m_overlayScene
end
function gui.WIFilmmaker:SetOverlaySceneEnabled(enabled)
	if self.m_overlaySceneEnabled == enabled then
		return
	end
	util.remove(self.m_overlaySceneCallback)
	console.run("render_clear_scene " .. (enabled and "0" or "1"))
	self.m_overlaySceneEnabled = enabled
	game.set_default_game_render_enabled(enabled == false)

	local vp = self:GetViewport()
	local rtVp = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	local te = util.is_valid(rtVp) and rtVp:GetToneMappedImageElement() or nil
	if te ~= nil then
		self.m_overlaySceneCallback = te:AddCallback("OnTextureApplied", function(te, tex)
			if enabled then
				self.m_nonOverlayRtTexture = te.m_elTex:GetTexture()
				te.m_elTex:SetTexture(game.get_scene():GetRenderer():GetHDRPresentationTexture())
			elseif self.m_nonOverlayRtTexture ~= nil then
				te.m_elTex:SetTexture(self.m_nonOverlayRtTexture)
				self.m_nonOverlayRtTexture = nil
			end
		end)
	end

	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:AddActor(filmClip, group, dontRefreshAnimation)
	group = group or filmClip:GetScene()
	local actor = group:AddActor()
	if dontUpdateActor ~= true then
		self:UpdateActor(actor, filmClip, nil, dontRefreshAnimation)
	end
	return actor
end
function gui.WIFilmmaker:UpdateActor(actor, filmClip, reload, dontRefreshAnimation)
	if reload == true then
		for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR) }) do
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if util.is_same_object(actorC:GetActorData(), actor) then
				ent:Remove()
			end
		end
	end

	local ent = filmClip:FindEntity()
	local filmClipC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP) or nil
	if filmClipC ~= nil then
		filmClipC:InitializeActors()
		filmClipC:UpdateCamera()
	end
	self:TagRenderSceneAsDirty()
	if dontRefreshAnimation ~= true then
		self:SetTimeOffset(self:GetTimeOffset())
	end
end
function gui.WIFilmmaker:TagRenderSceneAsDirty(dirty)
	if self.m_overlaySceneEnabled ~= true then
		game.set_default_game_render_enabled(true)
	end
	if dirty == nil then
		self.m_renderSceneDirty = self.m_renderSceneDirty or 24
		return
	end
	self.m_renderSceneDirty = dirty and math.huge or nil
end
function gui.WIFilmmaker:ReloadInterface()
	local projectData = self:MakeProjectPersistent()
	self:Close()

	local interface = tool.open_filmmaker()
	interface:RestorePersistentProject(projectData)
end
function gui.WIFilmmaker:GetGameScene()
	return self:GetRenderTab():GetGameScene()
end
function gui.WIFilmmaker:GetGameplayViewport()
	for _, vp in ipairs({ self:GetViewport(), self:GetSecondaryViewport(), self:GetTertiaryViewport() }) do
		if vp:IsValid() then
			if vp:IsInCameraControlMode() then
				return vp
			end
		end
	end
end
function gui.WIFilmmaker:GetGameplayCamera()
	local vp = self:GetGameplayViewport()
	if vp == nil then
		return
	end
	return vp:GetCamera()
end
function gui.WIFilmmaker:GetViewport()
	return self:GetWindow("primary_viewport") or nil
end
function gui.WIFilmmaker:GetViewportElement()
	local vp = self:GetWindow("primary_viewport")
	return util.is_valid(vp) and vp:GetViewport() or nil
end
function gui.WIFilmmaker:GetSecondaryViewport()
	return self:GetWindow("secondary_viewport") or nil
end
function gui.WIFilmmaker:GetTertiaryViewport()
	return self:GetWindow("tertiary_viewport") or nil
end
function gui.WIFilmmaker:GetRenderTab()
	return self:GetWindow("render") or nil
end
function gui.WIFilmmaker:GetActorEditor()
	return self:GetWindow("actor_editor") or nil
end
function gui.WIFilmmaker:GetElementViewer()
	return self:GetWindow("element_viewer") or nil
end
function gui.WIFilmmaker:CreateNewActor()
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActor()
end
function gui.WIFilmmaker:CreateNewActorComponent(actor, componentType, updateActor, initComponent)
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActorComponent(actor, componentType, updateActor, initComponent)
end
function gui.WIFilmmaker:OnGameViewCreated(projectC)
	pfm.GameView.OnGameViewCreated(self, projectC)
	projectC:AddEventCallback(ents.PFMProject.EVENT_ON_ENTITY_CREATED, function(ent)
		local trackC = ent:GetComponent(ents.COMPONENT_PFM_TRACK)
		if trackC ~= nil then
			trackC:SetKeepClipsAlive(false)
		end
	end)
end
function gui.WIFilmmaker:GoToNeighborBookmark(next)
	local timeline = self:GetTimeline()
	local bookmarkTimes = {}
	for _, bm in ipairs(timeline:GetBookmarks()) do
		table.insert(bookmarkTimes, bm:GetBookmark():GetTime())
	end
	table.sort(bookmarkTimes)

	if #bookmarkTimes == 0 then
		return
	end

	local t = self:GetTimeOffset()
	if next and t < bookmarkTimes[1] then
		self:SetTimeOffset(bookmarkTimes[1])
		return
	end
	if not next and t > bookmarkTimes[#bookmarkTimes] then
		self:SetTimeOffset(bookmarkTimes[#bookmarkTimes])
		return
	end

	if next then
		for i = 1, #bookmarkTimes - 1 do
			local bm0 = bookmarkTimes[i]
			local bm1 = bookmarkTimes[i + 1]
			if t >= bm0 and t < bm1 then
				self:SetTimeOffset(bm1)
				break
			end
		end
	else
		for i = #bookmarkTimes, 2, -1 do
			local bm0 = bookmarkTimes[i - 1]
			local bm1 = bookmarkTimes[i]
			if t > bm0 and t <= bm1 then
				self:SetTimeOffset(bm0)
				break
			end
		end
	end
end
function gui.WIFilmmaker:GoToNextBookmark()
	self:GoToNeighborBookmark(true)
end
function gui.WIFilmmaker:GoToPreviousBookmark()
	self:GoToNeighborBookmark(false)
end
function gui.WIFilmmaker:GetSelectionManager()
	return self.m_selectionManager
end
function gui.WIFilmmaker:OnThink()
	local cursorPos = input.get_cursor_pos()
	if cursorPos ~= self.m_lastCursorPos then
		self.m_lastCursorPos = cursorPos
		self.m_tLastCursorMove = time.real_time()
	end

	if self.m_raytracingJob == nil then
		return
	end

	local progress = self.m_raytracingJob:GetProgress()
	if util.is_valid(self.m_raytracingProgressBar) then
		self.m_raytracingProgressBar:SetProgress(progress)
	end
	if self.m_raytracingJob:IsComplete() == false then
		return
	end
	if self.m_raytracingJob:IsSuccessful() == false then
		self.m_raytracingJob = nil
		return
	end
	local imgBuffer = self.m_raytracingJob:GetResult()
	local img = prosper.create_image(imgBuffer)
	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local tex = prosper.create_texture(img, prosper.TextureCreateInfo(), imgViewCreateInfo, prosper.SamplerCreateInfo())
	tex:SetDebugName("pfm_render_result_tex")
	if self.m_renderResultWindow ~= nil then
		self.m_renderResultWindow:SetTexture(tex)
	end
	if util.is_valid(self.m_raytracingProgressBar) then
		self.m_raytracingProgressBar:SetVisible(false)
	end

	self.m_raytracingJob = nil
	if self:IsRecording() == false then
		return
	end
	-- Write the rendered frame and kick off the next one
	self.m_videoRecorder:WriteFrame(imgBuffer)

	local gameView = self:GetGameView()
	local projectC = util.is_valid(gameView) and gameView:GetComponent(ents.COMPONENT_PFM_PROJECT) or nil
	if projectC ~= nil then
		projectC:SetPlaybackOffset(projectC:GetPlaybackOffset() + self.m_videoRecorder:GetFrameDeltaTime())
		self:CaptureRaytracedImage()
	end
end
function gui.WIFilmmaker:OnRemove()
	gui.WIBaseFilmmaker.OnRemove(self)
	self:CloseProject()
	pfm.clear_pragma_renderer_scene()
	game.set_default_game_render_enabled(true)
	util.remove(self.m_worldAxesGizmo)
	util.remove(self.m_pfmManager)
	util.remove(self.m_cbDisableDefaultSceneDraw)
	util.remove(self.m_cbOnWindowShouldClose)
	util.remove(self.m_cbOnLuaError)
	util.remove(self.m_cbPreRenderScenes)
	util.remove(self.m_cbOnRenderTargetResized)
	util.remove(self.m_overlaySceneCallback)
	if util.is_valid(self.m_overlayScene) then
		self.m_overlayScene:GetEntity():Remove()
	end
	if util.is_valid(self.m_sceneDepth) then
		self.m_sceneDepth:GetEntity():Remove()
	end
	util.remove(self.m_cbDropped)
	util.remove(self.m_openDialogue)
	util.remove(self.m_previewWindow)
	util.remove(self.m_renderResultWindow)
	util.remove(self.m_updateProgressBar)
	self.m_selectionManager:Remove()

	local window = gui.get_primary_window()
	if util.is_valid(window) then
		window:SetWindowTitle(self.m_originalWindowTitle)
	end

	if self.m_animRecorder ~= nil then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end

	-- util.remove(self.m_reflectionProbe)
	-- util.remove(self.m_entLight)

	self:SaveSettings()
	self:SaveGlobalStateData()

	local layers = {}
	for _, layer in pairs(self.m_inputBindingLayers) do
		table.insert(layers, layer)
	end
	local udmData, err = udm.create("PFMKB", 1)
	local assetData = udmData:GetAssetData()
	input.InputBindingLayer.save(assetData, layers)
	file.create_path("cfg/pfm")
	local f = file.open("cfg/pfm/keybindings.udm", file.OPEN_MODE_WRITE)
	if f ~= nil then
		udmData:SaveAscii(f)
		f:Close()
	end
	for _, layer in ipairs(self.m_inputBindingLayers) do
		input.remove_input_binding_layer(layer.identifier)
	end
	self:UpdateInputBindings()

	if self.m_runUpdaterOnShutdown then
		util.run_updater()
	end

	gui.set_context_menu_skin()
	collectgarbage()
end
function gui.WIFilmmaker:StartRecording(fileName)
	local success = self.m_videoRecorder:StartRecording(fileName)
	if success == false then
		return false
	end
	self:CaptureRaytracedImage()
	return success
end
function gui.WIFilmmaker:IsRecording()
	return self.m_videoRecorder:IsRecording()
end
function gui.WIFilmmaker:StopRecording()
	self.m_videoRecorder:StopRecording()
end
function gui.WIFilmmaker:SetGameViewOffset(offset)
	self:TagRenderSceneAsDirty()
	self.m_updatingProjectTimeOffset = true
	if util.is_valid(self.m_playhead) then
		self.m_playhead:SetTimeOffset(offset)
	end

	gui.WIBaseFilmmaker.SetGameViewOffset(self, offset)

	local session = self:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	if activeClip ~= nil then
		if util.is_valid(self:GetViewport()) then
			self:GetViewport():SetGlobalTime(offset)

			local childClip = self:GetActiveGameViewFilmClip()
			if childClip ~= nil then
				self:GetViewport():SetLocalTime(childClip:GetTimeFrame():LocalizeOffset(offset))
				self:GetViewport():SetFilmClipName(childClip:GetName())
				self:GetViewport():SetFilmClipParentName(activeClip:GetName())
			end
		end
	end
	self.m_updatingProjectTimeOffset = false

	self:CallCallbacks("OnTimeOffsetChanged", self:GetTimeOffset())
end
function gui.WIFilmmaker:OnActorControlSelected(actorEditor, actor, component, controlData, slider)
	local memberInfo = controlData.getMemberInfo(controlData.name)
	if memberInfo == nil then
		return
	end
	local filmClip = actorEditor:GetFilmClip()
	if filmClip == nil then
		return
	end
	local graphEditor = self:GetTimeline():GetGraphEditor()
	local itemCtrl = graphEditor:AddControl(filmClip, actor, controlData, memberInfo)

	local fRemoveCtrl = function()
		if util.is_valid(itemCtrl) then
			itemCtrl:Remove()
		end
	end
	slider:AddCallback("OnDeselected", fRemoveCtrl)
	slider:AddCallback("OnRemove", fRemoveCtrl)
end
function gui.WIFilmmaker:OpenEscapeMenu()
	self:OpenWindow("settings")
	self:GoToWindow("settings")
end
function gui.WIFilmmaker:GetPictureTrackGroup()
	return self.m_trackGroupPicture
end
function gui.WIFilmmaker:GetSoundTrackGroup()
	return self.m_trackGroupSound
end
function gui.WIFilmmaker:GetOverlayTrackGroup()
	return self.m_trackGroupOverlay
end
function gui.WIFilmmaker:OnGameViewReloaded()
	local function apply_viewport(vp)
		if util.is_valid(vp) == false then
			return
		end
		vp:RefreshCamera()
	end
	apply_viewport(self:GetViewport())
	apply_viewport(self:GetSecondaryViewport())
	apply_viewport(self:GetTertiaryViewport())
end
function gui.WIFilmmaker:OpenFileInUdmEditor(filePath)
	self:OpenWindow("element_viewer")
	self:GoToWindow("element_viewer")
	local udmEditor = self:GetWindow("element_viewer")
	if util.is_valid(udmEditor) == false then
		return
	end
	udmEditor:OpenUdmFile(filePath)
end
function gui.WIFilmmaker:UpdateBookmarks()
	if util.is_valid(self.m_timeline) == false then
		return
	end
	self.m_timeline:ClearBookmarks()

	if self.m_timeline:GetEditor() == gui.PFMTimeline.EDITOR_CLIP then
		local mainClip = self:GetMainFilmClip()
		if mainClip ~= nil then
			local activeSet = mainClip:GetActiveBookmarkSet()
			if activeSet ~= nil then
				self.m_timeline:AddBookmarkSet(activeSet)
			end
		end
	else
		local filmClip = self:GetActiveFilmClip()
		if filmClip ~= nil then
			local bms = filmClip:FindBookmarkSet(pfm.Project.KEYFRAME_BOOKMARK_SET_NAME)
			if bms == nil then
				bms = filmClip:AddBookmarkSet()
				bms:SetName(pfm.Project.KEYFRAME_BOOKMARK_SET_NAME)
			end
			self.m_timeline:AddBookmarkSet(bms)
		end
		self.m_timeline:GetActiveEditor():InitializeBookmarks()
	end
end
function gui.WIFilmmaker:RemoveBookmark(t)
	local filmClip = self:GetActiveFilmClip()
	if filmClip == nil then
		return
	end
	local bmSet = filmClip:GetActiveBookmarkSet()
	if bmSet == nil then
		return
	end
	bmSet:RemoveBookmarkAtTimestamp(t)
end
function gui.WIFilmmaker:AbsoluteTimeToFilmClipTime(t)
	local filmClip = self:GetActiveFilmClip()
	if filmClip == nil then
		return t
	end
	return t - filmClip:GetTimeFrame():GetStart()
end
function gui.WIFilmmaker:GetTimelineMode()
	local timeline = self:GetTimeline()
	if util.is_valid(timeline) == false then
		return gui.PFMTimeline.EDITOR_CLIP
	end
	return timeline:GetEditor()
end
function gui.WIFilmmaker:AddBookmark(t, noKeyframe)
	local filmClip = self:GetActiveFilmClip()
	if filmClip == nil then
		return
	end
	t = t or (self:GetTimeOffset() - filmClip:GetTimeFrame():GetStart())
	if self.m_timeline:GetEditor() == gui.PFMTimeline.EDITOR_GRAPH and noKeyframe ~= true then
		local graphEditor = self.m_timeline:GetGraphEditor()
		local cmd = pfm.create_command("composition")
		for _, graph in ipairs(graphEditor:GetGraphs()) do
			if graph.curve:IsValid() then
				local valueType = graph.valueType
				local value = udm.get_default_value(valueType)
				local timestamp = graphEditor:InterfaceTimeToDataTime(graph, t)
				local panimaChannel = graph.curve:GetPanimaChannel()
				if panimaChannel ~= nil then
					local idx0, idx1, factor = panimaChannel:FindInterpolationIndices(timestamp)
					if idx0 ~= nil then
						local v0 = panimaChannel:GetValue(idx0)
						local v1 = panimaChannel:GetValue(idx1)
						value = udm.lerp(v0, v1, factor)
					end
				end

				local actorUuid = tostring(graph.actor:GetUniqueId())
				local propertyPath = graph.targetPath
				local baseIndex = graph.typeComponentIndex

				local res, subCmd =
					cmd:AddSubCommand("keyframe_property_composition", actorUuid, propertyPath, baseIndex)

				local curve = graph.curve
				local editorChannel = curve:GetEditorChannel()
				local channel = curve:GetChannel()
				if editorChannel ~= nil and channel ~= nil then
					local graphCurve = editorChannel:GetGraphCurve()
					local prevKeyframeIdx = editorChannel:FindLowerKeyIndex(timestamp, baseIndex)
					local nextKeyframeIdx = editorChannel:FindUpperKeyIndex(timestamp, baseIndex)

					local prevKfTime, nextKfTime
					if prevKeyframeIdx ~= nil then
						prevKfTime = graphCurve:GetKey(baseIndex):GetTime(prevKeyframeIdx)
					end
					if nextKeyframeIdx ~= nil then
						nextKfTime = graphCurve:GetKey(baseIndex):GetTime(nextKeyframeIdx)
					end

					local function add_fitting_keyframes(tStart, tEnd)
						local keyframes = channel:CalculateCurveFittingKeyframes(tStart, tEnd, baseIndex)
						if keyframes ~= nil and #keyframes > 1 then
							subCmd:AddSubCommand(
								"apply_curve_fitting",
								actorUuid,
								propertyPath,
								keyframes,
								udm.TYPE_FLOAT,
								baseIndex
							)
						end
					end
					if prevKfTime ~= nil then
						add_fitting_keyframes(prevKfTime, timestamp)
					end
					if nextKfTime ~= nil then
						add_fitting_keyframes(timestamp, nextKfTime)
					end
				end

				local componentValue = udm.get_numeric_component(value, baseIndex)
				subCmd:AddSubCommand(
					"create_keyframe",
					actorUuid,
					propertyPath,
					valueType,
					timestamp,
					baseIndex,
					componentValue
				)
			end
		end
		pfm.undoredo.push("create_keyframe", cmd)()
		return
	end

	local mainClip = self:GetMainFilmClip()
	if mainClip == nil then
		return
	end
	return pfm.undoredo.push(
		"create_bookmark",
		pfm.create_command("create_bookmark", mainClip, pfm.Project.DEFAULT_BOOKMARK_SET_NAME, t)
	)()
end
function gui.WIFilmmaker:ImportSequence(actor, animName)
	local mdlName = actor:GetModel()
	if mdlName == nil then
		return
	end
	local mdl = game.get_model(mdlName)
	if mdl == nil then
		return
	end
	local animId = mdl:LookupAnimation(animName)
	if animId == nil then
		return
	end
	local anim = mdl:GetAnimation(animId)

	local panimaAnim = anim:ToPanimaAnimation(mdl:GetSkeleton(), mdl:GetReferencePose())
	local cmd = pfm.create_command("composition")
	for _, channel in ipairs(panimaAnim:GetChannels()) do
		local propertyPath = channel:GetTargetPath():ToUri(false)
		local valueType = channel:GetValueType()
		local res, subCmd = cmd:AddSubCommand("add_editor_channel", actor, propertyPath, valueType)
		if res == pfm.Command.RESULT_SUCCESS then
			subCmd:AddSubCommand("add_animation_channel", actor, propertyPath, valueType)
		end
		cmd:AddSubCommand(
			"set_animation_channel_range_data",
			actor,
			propertyPath,
			channel:GetTimes(),
			channel:GetValues(),
			valueType
		)
	end
	pfm.undoredo.push("import_sequence", cmd)()
end
function gui.WIFilmmaker:SetTimeOffset(offset)
	gui.WIBaseFilmmaker.SetTimeOffset(self, offset)
	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end
	actorEditor:UpdateControlValues() -- TODO: Panima animations don't update right away, we need to call this *after* they have been updated
end
function gui.WIFilmmaker:OpenMaterialEditor(mat, optMdl)
	self:CloseWindow("material_editor")
	local tab, matEd = self:OpenWindow("material_editor", true)
	matEd:SetMaterial(mat, optMdl)
end
function gui.WIFilmmaker:OpenParticleEditor(ptFile, ptName)
	self:CloseWindow("particle_editor")
	local tab, ptEd = self:OpenWindow("particle_editor", true)
	ptEd:LoadParticleSystem(ptFile, ptName)
end
function gui.WIFilmmaker:OnActorSelectionChanged(ent, selected)
	self:TagRenderSceneAsDirty()
	if util.is_valid(self:GetViewport()) == false then
		return
	end
	self:GetViewport():OnActorSelectionChanged(ent, selected)
end
function gui.WIFilmmaker:GetActiveCamera()
	return game.get_render_scene_camera()
end
function gui.WIFilmmaker:GetMainFilmClip()
	local session = self:GetSession()
	return (session ~= nil) and session:GetActiveClip() or nil
end
function gui.WIFilmmaker:GetActiveFilmClip()
	local mainClip = self:GetMainFilmClip()
	if mainClip == nil then
		return
	end
	return mainClip:GetChildFilmClip(self:GetTimeOffset())
end
function gui.WIFilmmaker:ShowInElementViewer(el)
	if util.is_valid(self:GetElementViewer()) == false then
		return
	end
	self:GetElementViewer():MakeElementRoot(el)

	self:GoToWindow("element_viewer")
end
function gui.WIFilmmaker:SelectActor(actor, deselectCurrent, property, goToActorEditor)
	if util.is_valid(self:GetActorEditor()) == false then
		return
	end
	self:GetActorEditor():SelectActor(actor, deselectCurrent, property)

	if goToActorEditor ~= false then
		self:GoToWindow("actor_editor")
	else
		local actorEditor = self:GetActorEditor()
		if util.is_valid(actorEditor) then
			actorEditor:InvokeThink()
		end
	end
end
function gui.WIFilmmaker:DeselectAllActors()
	if util.is_valid(self:GetActorEditor()) == false then
		return
	end
	self:GetActorEditor():DeselectAllActors()
end
function gui.WIFilmmaker:IsActorSelected(actor)
	if util.is_valid(self:GetActorEditor()) == false then
		return false
	end
	return self:GetActorEditor():IsActorSelected(actor)
end
function gui.WIFilmmaker:DeselectActor(actor)
	if util.is_valid(self:GetActorEditor()) == false then
		return
	end
	self:GetActorEditor():DeselectActor(actor)

	self:GoToWindow("actor_editor")
end
function gui.WIFilmmaker:GetSelectedClip()
	return self:GetTimeline():GetSelectedClip()
end
function gui.WIFilmmaker:GetTimeline()
	return self.m_timeline
end
function gui.WIFilmmaker:GetGraphEditor()
	local timeline = self:GetTimeline()
	if util.is_valid(timeline) == false then
		return
	end
	return timeline:GetGraphEditor()
end
function gui.WIFilmmaker:GetFilmStrip()
	return self.m_filmStrip
end
function gui.WIFilmmaker:GetModelViewer()
	return self:GetWindow("model_viewer")
end
function gui.WIFilmmaker:OpenModelView(mdl, animName)
	self:OpenWindow("model_viewer", true)
	if util.is_valid(self.m_mdlView) == false then
		return
	end
	if mdl ~= nil then
		self.m_mdlView:SetModel(mdl)
	end

	if animName ~= nil then
		self.m_mdlView:PlayAnimation(animName)
	else
		self.m_mdlView:PlayIdleAnimation()
	end
	self.m_mdlView:Update()
end
function gui.WIFilmmaker:SetQuickAxisTransformMode(axes)
	local vp = self:GetViewport()
	if util.is_valid(vp) == false then
		return
	end
	if self.m_quickAxisTransformModeEnabled then
		local entTransform = vp:GetTransformEntity()
		self.m_quickAxisTransformModeEnabled = nil

		for _, v in ipairs(self.m_quickAxisTransformAxes) do
			if v:IsValid() then
				v:StopTransform()
			end
		end
		self.m_quickAxisTransformAxes = nil

		vp:SetManipulatorMode(self.m_preAxisManipulatorMode or gui.PFMViewport.MANIPULATOR_MODE_SELECT)
		self.m_preAxisManipulatorMode = nil

		if util.is_valid(entTransform) then
			vp:OnActorTransformChanged(entTransform)
		end
		return
	end
	self.m_preAxisManipulatorMode = vp:GetManipulatorMode()
	local useRotationGizmo = (vp:GetManipulatorMode() == gui.PFMViewport.MANIPULATOR_MODE_ROTATE)
	if useRotationGizmo == false then
		vp:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_MOVE)
	end
	local c = vp:GetTransformWidgetComponent()
	if util.is_valid(c) then
		self.m_quickAxisTransformModeEnabled = true
		self.m_quickAxisTransformAxes = {}
		for _, axis in ipairs(axes) do
			local v = c:GetTransformUtility(
				useRotationGizmo and ents.UtilTransformArrowComponent.TYPE_ROTATION
					or ents.UtilTransformArrowComponent.TYPE_TRANSLATION,
				axis,
				useRotationGizmo and "rotation" or "translation"
			)
			if v ~= nil then
				v = v:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
				v:StartTransform()
				table.insert(self.m_quickAxisTransformAxes, v)
			end
		end
	end
end
function gui.WIFilmmaker:WriteActorsToUdmElement(filmClip, actors, el, name)
	actors = pfm.dereference(actors)

	local pfmCopy = el:Add(name or "pfm_copy")

	local track = filmClip:FindAnimationChannelTrack()
	local animationData = {}
	for _, actor in ipairs(actors) do
		local channelClip = track:FindActorAnimationClip(actor)
		if channelClip ~= nil then
			table.insert(animationData, channelClip:GetUdmData())
		end
	end
	pfmCopy:AddArray("data", #actors + #animationData, udm.TYPE_ELEMENT)
	local data = pfmCopy:Get("data")
	for i, actor in ipairs(actors) do
		local udmData = data:Get(i - 1)
		udmData:SetValue("type", udm.TYPE_STRING, "actor")
		udmData:Add("data"):Merge(actor:GetUdmData())

		local parentCollections = {}
		local parent = actor:GetParent()
		while parent ~= nil and util.get_type_name(parent) == "Group" do
			table.insert(parentCollections, parent:GetName())
			parent = parent:GetParent()
		end
		parentCollections[#parentCollections] = nil

		local a = udmData:AddArray("parentCollections", #parentCollections, udm.TYPE_STRING)
		for i, name in ipairs(parentCollections) do
			a:SetValue(i - 1, udm.TYPE_STRING, name)
		end
	end
	local offset = #actors
	for i, animData in ipairs(animationData) do
		local udmData = data:Get(offset + i - 1)
		udmData:SetValue("type", udm.TYPE_STRING, "animation")
		udmData:Add("data"):Merge(animData)
	end
end
function gui.WIFilmmaker:RestoreActorsFromUdmElement(filmClip, data, keepOriginalUuids, name)
	local pfmCopy = data:Get(name or "pfm_copy")
	local data = pfmCopy:Get("data")
	if data:IsValid() == false then
		console.print_warning("No copy data found in clipboard UDM string!")
		return
	end
	local track = filmClip:FindAnimationChannelTrack()

	-- Assign new unique ids to prevent id collisions
	local oldIdToNewId = {}
	local function iterate_elements(udmData, f)
		f(udmData)

		for _, udmChild in pairs(udmData:GetChildren()) do
			iterate_elements(udmChild, f)
		end

		if udm.is_array_type(udmData:GetType()) and udmData:GetValueType() == udm.TYPE_ELEMENT then
			local n = udmData:GetSize()
			for i = 1, n do
				iterate_elements(udmData:Get(i - 1), f)
			end
		end
	end
	if keepOriginalUuids ~= true then
		iterate_elements(data, function(udmData)
			if udmData:HasValue("uniqueId") then
				local oldUniqueId = udmData:GetValue("uniqueId", udm.TYPE_STRING)
				local newUniqueId = tostring(util.generate_uuid_v4())
				udmData:SetValue("uniqueId", udm.TYPE_STRING, newUniqueId)
				oldIdToNewId[oldUniqueId] = newUniqueId
			end
		end)
		iterate_elements(data, function(udmData)
			for name, udmChild in pairs(udmData:GetChildren()) do
				if udmChild:GetType() == udm.TYPE_STRING then
					local val = udmData:GetValue(name, udm.TYPE_STRING)
					if oldIdToNewId[val] ~= nil then
						udmData:SetValue(name, udm.TYPE_STRING, oldIdToNewId[val])
					end
				end
			end
		end)
	end
	--

	local actorEditor = self:GetActorEditor()
	local n = data:GetSize()
	local filmClipUniqueId = tostring(filmClip:GetUniqueId())
	local filmClips = {}
	local actors = {}
	for i = 1, n do
		local udmData = data:Get(i - 1)
		local type = udmData:GetValue("type", udm.TYPE_STRING)
		if type == "actor" then
			local parentCollections = udmData:GetArrayValues("parentCollections", udm.TYPE_STRING)

			local group = filmClip:GetScene()
			group = actorEditor:FindCollection(parentCollections, true, group)
			local actor = group:AddActor()
			actor:Reinitialize(udmData:Get("data"))
			for ent, c in ents.citerator(ents.COMPONENT_PFM_FILM_CLIP) do
				if tostring(c:GetClipData():GetUniqueId()) == filmClipUniqueId then
					filmClips[c] = true
				end
			end

			table.insert(actors, {
				actor = actor,
				parentCollections = parentCollections,
			})
		elseif type == "animation" then
			local animData = udmData:Get("data")
			local actorUniqueId = animData:GetValue("actor", udm.TYPE_STRING)
			local actor = filmClip:FindActorByUniqueId(actorUniqueId)
			if actor == nil then
				console.print_warning(
					"Animation data refers to unknown actor with unique id " .. actorUniqueId .. "! Ignoring..."
				)
			else
				local channelClip = track:FindActorAnimationClip(actor, true)
				channelClip:Reinitialize(animData)
			end
		else
			console.print_warning("Copy type " .. type .. " is not compatible!")
		end
	end
	for c, _ in pairs(filmClips) do
		c:InitializeActors()
	end
	local root = actorEditor:GetTree():GetRoot()
	for _, actor in ipairs(actors) do
		local item = root
		if #actor.parentCollections > 0 then
			item = item:FindItemByText("Scene")
			for _, colName in ipairs(actor.parentCollections) do
				if util.is_valid(item) then
					item = item:FindItemByText(colName)
				else
					break
				end
			end
			if util.is_valid(item) == false then
				item = nil
			end
		end
		actorEditor:AddActor(actor.actor, item)
	end
end
gui.register("WIFilmmaker", gui.WIFilmmaker)

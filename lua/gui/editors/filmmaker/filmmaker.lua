--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../base_editor.lua")
include("/pfm/project_manager.lua")

util.register_class("gui.WIFilmmaker",gui.WIBaseEditor,pfm.ProjectManager)

include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/gui/filmstrip.lua")
include("/gui/genericclip.lua")
include("/gui/witabbedpanel.lua")
include("/gui/editors/wieditorwindow.lua")
include("/gui/patreon_ticker.lua")
include("/gui/pfm/viewport.lua")
include("/gui/pfm/postprocessing.lua")
include("/gui/pfm/videoplayer.lua")
include("/gui/pfm/timeline.lua")
include("/gui/pfm/elementviewer.lua")
include("/gui/pfm/actoreditor.lua")
include("/gui/pfm/modelcatalog.lua")
include("/gui/pfm/materialcatalog.lua")
include("/gui/pfm/particlecatalog.lua")
include("/gui/pfm/tutorialcatalog.lua")
include("/gui/pfm/actorcatalog.lua")
include("/gui/pfm/renderpreview.lua")
include("/gui/pfm/material_editor/materialeditor.lua")
include("/gui/pfm/particleeditor.lua")
include("/pfm/util_particle_system.lua")

gui.load_skin("pfm")
locale.load("pfm_user_interface.txt")
locale.load("pfm_popup_messages.txt")
locale.load("physics_materials.txt")

include("windows")
include("video_recorder.lua")
include("selection_manager.lua")
include("animation_export.lua")

include_component("pfm_camera")
include_component("pfm_sound_source")
include_component("pfm_grid")

function gui.WIFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
	pfm.ProjectManager.__init(self)

	pfm.set_project_manager(self)
end
function gui.WIFilmmaker:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)
	tool.editor = self -- TODO: This doesn't really belong here (check lua/autorun/client/cl_filmmaker.lua)
	tool.filmmaker = self

	local infoBar = self:GetInfoBar()
	local infoBarContents = infoBar:GetContents()
	local patronTickerContainer = gui.create("PatreonTicker",infoBarContents,0,0,infoBarContents:GetWidth(),infoBarContents:GetHeight(),0,0,1,1)
	local engineInfo = engine.get_info()
	infoBar:AddIcon("wgui/patreon_logo",engineInfo.patreonURL,"Patreon")
	infoBar:AddIcon("third_party/twitter_logo",engineInfo.twitterURL,"Twitter")
	infoBar:AddIcon("third_party/reddit_logo",engineInfo.redditURL,"Reddit")
	infoBar:AddIcon("third_party/discord_logo",engineInfo.discordURL,"Discord")
	infoBar:Update()

	-- Disable default scene drawing for the lifetime of the Filmmaker; We'll only render the viewport(s) if something has actually changed, which
	-- saves up a huge amount of rendering resources.
	self.m_cbDisableDefaultSceneDraw = game.add_callback("RenderScenes",function(drawSceneInfo)
		if(self.m_renderSceneDirty == nil) then
			game.set_default_game_render_enabled(false)
			return
		end
		self.m_renderSceneDirty = self.m_renderSceneDirty -1
		if(self.m_renderSceneDirty == 0) then self.m_renderSceneDirty = nil end
		return false
	end)
	game.set_default_game_render_enabled(false)

	self:EnableThinking()
	self:SetSize(1280,1024)
	self:SetSkin("pfm")
	self.m_selectionManager = pfm.SelectionManager()
	self.m_selectionManager:AddChangeListener(function(ent,selected)
		self:OnActorSelectionChanged(ent,selected)
	end)
	local pMenuBar = self:GetMenuBar()
	self.m_menuBar = pMenuBar

	self.m_cbDropped = game.add_callback("OnFilesDropped",function(tFiles)
		local foundElement = false
		gui.get_element_under_cursor(function(el)
			if(foundElement or el:IsDescendantOf(self) == false) then return false end
			local result = el:CallCallbacks("OnFilesDropped",tFiles)
			if(result == util.EVENT_REPLY_HANDLED) then
				foundElement = true
				return true
			end
			return false
		end)
	end)

	pMenuBar:AddItem(locale.get_text("file"),function(pContext)
		--[[pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end

		end)]]
		pContext:AddItem(locale.get_text("new"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:CreateNewProject()
		end)
		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			util.remove(self.m_openDialogue)
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				fileName = "projects/" .. file.remove_file_extension(fileName) .. ".pfm"
				self:LoadProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("projects")
			self.m_openDialogue:SetExtensions({"pfm"})
			self.m_openDialogue:Update()
		end)
		pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			util.remove(self.m_openDialogue)
			self.m_openDialogue = gui.create_file_save_dialog(function(pDialog,fileName)
				file.create_directory("projects")
				fileName = "projects/" .. file.remove_file_extension(fileName) .. ".pfm"
				self:SaveProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("projects")
			self.m_openDialogue:SetExtensions({"pfm"})
			self.m_openDialogue:Update()
		end)
		pContext:AddItem(locale.get_text("import") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			util.remove(self.m_openDialogue)
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				self:ImportSFMProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("elements/sessions")
			self.m_openDialogue:SetExtensions({"dmx"})
			self.m_openDialogue:GetFileList():SetFileFinder(function(path)
				local tFiles,tDirs = file.find(path .. "*")
				tFiles = file.find(path .. "*.dmx")

				local tFilesExt,tDirsExt = file.find_external_game_asset_files(path .. "*")
				tFilesExt = file.find_external_game_asset_files(path .. ".dmx")
				
				local tFilesExtUnique = {}
				for _,f in ipairs(tFilesExt) do
					f = file.remove_file_extension(f) .. ".dmx"
					tFilesExtUnique[f] = true
				end
				for _,f in ipairs(tFiles) do
					f = file.remove_file_extension(f) .. ".dmx"
					tFilesExtUnique[f] = true
				end
				
				local tDirsExtUnique = {}
				for _,f in ipairs(tDirsExt) do
					tDirsExtUnique[f] = true
				end
				for _,f in ipairs(tDirs) do
					tDirsExtUnique[f] = true
				end
				
				tFiles = {}
				tDirs = {}
				for f,_ in pairs(tFilesExtUnique) do
					table.insert(tFiles,f)
				end
				table.sort(tFiles)
				
				for d,_ in pairs(tDirsExtUnique) do
					table.insert(tDirs,d)
				end
				table.sort(tDirs)
				return tFiles,tDirs
			end)
			self.m_openDialogue:Update()
		end)
		--[[pContext:AddItem(locale.get_text("pfm_export_blender_scene") .. "...",function(pItem)
			local dialoge = gui.create_file_save_dialog(function(pDialoge)
				local fname = pDialoge:GetFilePath(true)
				file.create_path(file.get_file_path(fname))

				import.export_scene(fname)
			end)
			dialoge:SetExtensions({"fbx"})
			dialoge:SetRootPath(util.get_addon_path())
			dialoge:Update()
		end)]]
		pContext:AddItem(locale.get_text("pfm_pack_project") .. "...",function(pItem)
			local dialoge = gui.create_file_save_dialog(function(pDialoge)
				local fname = pDialoge:GetFilePath(true)
				self:PackProject(fname)
			end)
			dialoge:SetExtensions({"zip"})
			dialoge:SetRootPath(util.get_addon_path())
			dialoge:Update()
		end)
		--[[pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			local project = self:GetProject()
			local node = project:GetUDMRootNode()
			local ds = util.DataStream()
			print("Node: ",node)
			node:SaveToBinary(ds)
			print("Size: ",ds:GetSize())
		end)]]
		--[[pContext:AddItem(locale.get_text("close"),function(pItem)
			if(util.is_valid(self) == false) then return end
			tool.close_filmmaker()
		end)]]
		pContext:AddItem(locale.get_text("close"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:CreateNewProject()
		end)
		pContext:AddItem(locale.get_text("exit"),function(pItem)
			if(util.is_valid(self) == false) then return end
			tool.close_filmmaker()
			engine.shutdown()
		end)
		pContext:Update()
	end)
	--[[pMenuBar:AddItem(locale.get_text("edit"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("windows"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("view"),function(pContext)

	end)]]
	pMenuBar:AddItem(locale.get_text("render"),function(pContext)
		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pbr"))
		pSubMenu:AddItem(locale.get_text("pfm_generate_ambient_occlusion_maps"),function(pItem)
			if(util.is_valid(self) == false) then return end
			local entPbrConverter = ents.find_by_component("pbr_converter")[1]
			if(util.is_valid(entPbrConverter) == false) then return end
			local pbrC = entPbrConverter:GetComponent(ents.COMPONENT_PBR_CONVERTER)
			for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_MODEL)}) do
				if(ent:IsWorld() == false) then
					local mdl = ent:GetModel()
					if(mdl == nil or ent:IsWorld()) then return end
					pbrC:GenerateAmbientOcclusionMaps(mdl)
					-- TODO: Also include all models for entire project which haven't been loaded yet
				end
			end
		end)
		pSubMenu:AddItem(locale.get_text("pfm_rebuild_reflection_probes"),function(pItem)
			
		end)
		pSubMenu:Update()

		pContext:Update()
	end)
	--[[pMenuBar:AddItem(locale.get_text("map"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_generate_lightmaps"),function(pItem)
			
		end)
		pContext:AddItem(locale.get_text("pfm_write_lightmaps_to_bsp"),function(pItem)
			
		end)
		pContext:Update()
	end)]]
	pMenuBar:AddItem(locale.get_text("preferences"),function(pContext)
		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("language"))
		for lan,lanLoc in pairs(locale.get_languages()) do
			pSubMenu:AddItem(lanLoc,function(pItem)
				if(util.is_valid(self) == false) then return end
				locale.change_language(lan)
				self:ReloadInterface()
			end)
		end
		pSubMenu:Update()

		pContext:Update()
	end)
	pMenuBar:AddItem(locale.get_text("tools"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_export_map"),function(pItem)
			if(util.is_valid(self) == false) then return end
			local mapName = game.get_map_name()
			local exportInfo = game.Model.ExportInfo()
			exportInfo.exportAnimations = false
			exportInfo.exportSkinnedMeshData = false
			exportInfo.exportMorphTargets = false
			exportInfo.exportImages = true
			exportInfo.saveAsBinary = true
			exportInfo.verbose = true
			exportInfo.generateAo = false
			exportInfo.mergeMeshesByMaterial = true
			exportInfo.imageFormat = game.Model.ExportInfo.IMAGE_FORMAT_PNG
			exportInfo.scale = util.units_to_metres(1)

			local mapExportInfo = asset.MapExportInfo()
			local vp = self:GetViewport()
			if(util.is_valid(vp)) then
				local cam = vp:GetCamera()
				if(util.is_valid(cam)) then mapExportInfo:AddCamera(cam) end
			end
			mapExportInfo.includeMapLightSources = false
			for light in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_LIGHT)}) do
				local lightC = light:GetComponent(ents.COMPONENT_LIGHT)
				mapExportInfo:AddLightSource(lightC)
			end

			local success,errMsg = asset.export_map(mapName,exportInfo,mapExportInfo)
			if(success) then
				util.open_path_in_explorer("export/maps/" .. mapName .. "/" .. mapName .. "/",mapName .. ".glb")
				return
			end
			pfm.log("Unable to export map: " .. errMsg,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		end)

		pContext:Update()
	end)
	self:AddWindowsMenuBarItem()
	pMenuBar:AddItem(locale.get_text("help"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_getting_started"),function(pItem)
			util.open_url_in_browser("https://wiki.pragma-engine.com/index.php?title=Pfm_firststeps")
		end)
		pContext:AddItem(locale.get_text("pfm_report_a_bug"),function(pItem)
			util.open_url_in_browser("https://github.com/Silverlan/pfm/issues")
		end)
		pContext:Update()
	end)
	pMenuBar:Update()

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
	self:SetKeyboardInputEnabled(true)
	self:ClearProjectUI()

	if(ents.get_world() == nil) then
		pfm.log("Empty map. Creating a default reflection probe and light source...",pfm.LOG_CATEGORY_PFM)
		local entReflectionProbe = ents.create("env_reflection_probe")
		entReflectionProbe:SetKeyValue("ibl_material","pbr/ibl/venice_sunset")
		entReflectionProbe:SetKeyValue("ibl_strength","1.4")
		entReflectionProbe:Spawn()
		self.m_reflectionProbe = entReflectionProbe

		local entLight = ents.create("env_light_environment")
		entLight:SetKeyValue("spawnflags",tostring(1024))
		entLight:SetAngles(EulerAngles(65,45,0))
		entLight:Spawn()

		local colorC = entLight:GetComponent(ents.COMPONENT_COLOR)
		if(colorC ~= nil) then colorC:SetColor(light.color_temperature_to_color(light.get_average_color_temperature(light.NATURAL_LIGHT_TYPE_CLEAR_BLUESKY))) end

		local lightC = entLight:GetComponent(ents.COMPONENT_LIGHT)
		if(lightC ~= nil) then
			lightC:SetShadowType(ents.LightComponent.SHADOW_TYPE_FULL)
			lightC:SetLightIntensity(4)
		end
		local toggleC = entLight:GetComponent(ents.COMPONENT_TOGGLE)
		if(toggleC ~= nil) then toggleC:TurnOn() end
		self.m_entLight = entLight
	end
	pfm.ProjectManager.OnInitialize(self)
	self:SetCachedMode(false)
end
function gui.WIFilmmaker:PackProject(fileName)
	local project = self:GetProject()
	local session = self:GetSession()

	local assetFiles = project:CollectAssetFiles()
	
	fileName = file.remove_file_extension(fileName) .. ".zip"
	util.pack_zip_archive(fileName,assetFiles)
	util.open_path_in_explorer(util.get_addon_path(),fileName)
end
function gui.WIFilmmaker:AddActor(actor,filmClip)
	filmClip:GetActors():PushBack(actor)
	self:UpdateActor(actor,filmClip)
end
function gui.WIFilmmaker:UpdateActor(actor,filmClip,reload)
	if(reload == true) then
		for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(util.is_same_object(actorC:GetActorData(),actor)) then
				ent:Remove()
			end
		end
	end

	local ent = filmClip:FindEntity()
	local filmClipC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP) or nil
	if(filmClipC ~= nil) then filmClipC:InitializeActors() end
	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:TagRenderSceneAsDirty(dirty)
	game.set_default_game_render_enabled(true)
	if(dirty == nil) then
		self.m_renderSceneDirty = self.m_renderSceneDirty or 1
		return
	end
	self.m_renderSceneDirty = dirty and math.huge or nil
end
function gui.WIFilmmaker:ReloadInterface()
	local project = self:GetProject()
	self:Close()
	local interface = tool.open_filmmaker()
	interface:InitializeProject(project)
end
function gui.WIFilmmaker:GetGameScene() return self:GetRenderTab():GetGameScene() end
function gui.WIFilmmaker:GetViewport() return self:GetWindow("primary_viewport") or nil end
function gui.WIFilmmaker:GetRenderTab() return self:GetWindow("render") or nil end
function gui.WIFilmmaker:GetActorEditor() return self:GetWindow("actor_editor") or nil end
function gui.WIFilmmaker:GetElementViewer() return self:GetWindow("element_viewer") or nil end
function gui.WIFilmmaker:CreateNewActor()
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActor()
end
function gui.WIFilmmaker:CreateNewActorComponent(actor,componentType)
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActorComponent(actor,componentType)
end
function gui.WIFilmmaker:OnGameViewCreated(projectC)
	pfm.GameView.OnGameViewCreated(self,projectC)
	projectC:AddEventCallback(ents.PFMProject.EVENT_ON_ENTITY_CREATED,function(ent)
		local trackC = ent:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:SetKeepClipsAlive(false) end
	end)
end
function gui.WIFilmmaker:KeyboardCallback(key,scanCode,state,mods)
	-- TODO: Implement a keybinding system for this! Keybindings should also appear in tooltips!
	if(key == input.KEY_SPACE) then
		if(state == input.STATE_PRESS and util.is_valid(self:GetViewport())) then
			local playButton = self:GetViewport():GetPlayButton()
			playButton:TogglePlay()
		end
		return util.EVENT_REPLY_HANDLED
	elseif(key == input.KEY_COMMA) then
		if(state == input.STATE_PRESS) then self:GoToPreviousFrame() end
		return util.EVENT_REPLY_HANDLED
	elseif(key == input.KEY_PERIOD) then
		if(state == input.STATE_PRESS) then self:GoToNextFrame() end
		return util.EVENT_REPLY_HANDLED
	else
		-- TODO: UNDO ME
		--[[local entGhost = ents.find_by_class("pfm_ghost")[1]
		if(util.is_valid(entGhost)) then
			local lightC = entGhost:GetComponent(ents.COMPONENT_LIGHT)
			lightC.colTemp = lightC.colTemp or light.get_average_color_temperature(light.NATURAL_LIGHT_TYPE_LED_LAMP)
			if(key == input.KEY_KP_ADD and state == input.STATE_PRESS) then
				lightC.colTemp = lightC.colTemp +500
			elseif(key == input.KEY_KP_SUBTRACT and state == input.STATE_PRESS) then
				lightC.colTemp = lightC.colTemp -500
			end
			lightC.colTemp = math.clamp(lightC.colTemp,965,12000)
			local colorC = entGhost:GetComponent(ents.COMPONENT_COLOR)
			colorC:SetColor(light.color_temperature_to_color(lightC.colTemp))
		end
		return util.EVENT_REPLY_HANDLED]]
	end
	--[[elseif(key == input.KEY_KP_ADD and state == input.STATE_PRESS) then
		ents.PFMGrid.decrease_grid_size()
		return util.EVENT_REPLY_HANDLED
	elseif(key == input.KEY_KP_SUBTRACT and state == input.STATE_PRESS) then
		ents.PFMGrid.increase_grid_size()
		return util.EVENT_REPLY_HANDLED
	end]]
	return util.EVENT_REPLY_UNHANDLED
end
function gui.WIFilmmaker:GetSelectionManager() return self.m_selectionManager end
function gui.WIFilmmaker:OnThink()
	local cursorPos = input.get_cursor_pos()
	if(cursorPos ~= self.m_lastCursorPos) then
		self.m_lastCursorPos = cursorPos
		self.m_tLastCursorMove = time.real_time()
	end

	if(self.m_raytracingJob == nil) then return end

	local progress = self.m_raytracingJob:GetProgress()
	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetProgress(progress) end
	if(self.m_raytracingJob:IsComplete() == false) then return end
	if(self.m_raytracingJob:IsSuccessful() == false) then
		self.m_raytracingJob = nil
		return
	end
	local imgBuffer = self.m_raytracingJob:GetResult()
	local img = prosper.create_image(imgBuffer)
	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),imgViewCreateInfo,prosper.SamplerCreateInfo())
	tex:SetDebugName("pfm_render_result_tex")
	if(self.m_renderResultWindow ~= nil) then self.m_renderResultWindow:SetTexture(tex) end
	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetVisible(false) end

	self.m_raytracingJob = nil
	if(self:IsRecording() == false) then return end
	-- Write the rendered frame and kick off the next one
	self.m_videoRecorder:WriteFrame(imgBuffer)

	local gameView = self:GetGameView()
	local projectC = util.is_valid(gameView) and gameView:GetComponent(ents.COMPONENT_PFM_PROJECT) or nil
	if(projectC ~= nil) then
		projectC:SetOffset(projectC:GetOffset() +self.m_videoRecorder:GetFrameDeltaTime())
		self:CaptureRaytracedImage()
	end
end
function gui.WIFilmmaker:OnRemove()
	self:CloseProject()
	util.remove(self.m_cbDisableDefaultSceneDraw)
	util.remove(self.m_cbDropped)
	util.remove(self.m_openDialogue)
	util.remove(self.m_previewWindow)
	util.remove(self.m_renderResultWindow)
	self.m_selectionManager:Remove()

	if(self.m_animRecorder ~= nil) then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end

	util.remove(self.m_reflectionProbe)
	util.remove(self.m_entLight)
	collectgarbage()
end
function gui.WIFilmmaker:CaptureRaytracedImage()
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	local job = util.capture_raytraced_screenshot(1024,1024,512)--2048,2048,1024)
	job:Start()
	self.m_raytracingJob = job

	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetVisible(true) end
end
function gui.WIFilmmaker:StartRecording(fileName)
	local success = self.m_videoRecorder:StartRecording(fileName)
	if(success == false) then return false end
	self:CaptureRaytracedImage()
	return success
end
function gui.WIFilmmaker:IsRendering()
	local vp = self:GetRenderTab()
	return util.is_valid(vp) and vp:IsRendering()
end
function gui.WIFilmmaker:IsRecording() return self.m_videoRecorder:IsRecording() end
function gui.WIFilmmaker:StopRecording()
	self.m_videoRecorder:StopRecording()
end
function gui.WIFilmmaker:SetGameViewOffset(offset)
	self:TagRenderSceneAsDirty()
	self.m_updatingProjectTimeOffset = true
	if(util.is_valid(self.m_playhead)) then self.m_playhead:SetTimeOffset(offset) end

	pfm.ProjectManager.SetGameViewOffset(self,offset)

	local session = self:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	if(activeClip ~= nil) then
		if(util.is_valid(self:GetViewport())) then
			self:GetViewport():SetGlobalTime(offset)

			local childClip = self:GetActiveGameViewFilmClip()
			if(childClip ~= nil) then
				self:GetViewport():SetLocalTime(childClip:GetTimeFrame():LocalizeOffset(offset))
				self:GetViewport():SetFilmClipName(childClip:GetName())
				self:GetViewport():SetFilmClipParentName(activeClip:GetName())
			end
		end
	end
	self.m_updatingProjectTimeOffset = false

	self:CallCallbacks("OnTimeOffsetChanged",self:GetTimeOffset())
end
function gui.WIFilmmaker:InitializeProject(project)
	if(util.is_valid(self.m_playbackControls)) then
		local timeFrame = projectC:GetTimeFrame()
		self.m_playbackControls:SetDuration(timeFrame:GetDuration())
		self.m_playbackControls:SetOffset(0.0)
	end

	local entScene = pfm.ProjectManager.InitializeProject(self,project)

	-- We want the frame offset to start at 0, but the default value is already 0, which means the
	-- callbacks would not get triggered properly. To fix that, we'll just set it to some random value != 0
	-- before actually setting it to 0 further below.
	self:SetTimeOffset(1.0)
	local session = self:GetSession()
	if(session ~= nil) then
		local filmTrack = session:GetFilmTrack()
		if(filmTrack ~= nil) then
			filmTrack:GetFilmClipsAttr():AddChangeListener(function(newEl)
				if(util.is_valid(self.m_timeline) == false) then return end
				self:AddFilmClipElement(newEl)
				self:ReloadGameView() -- TODO: We don't really need to refresh the entire game view, just the current film clip would be sufficient.
			end)

			-- TODO
			--[[for _,filmClip in ipairs(filmTrack:GetFilmClips():GetTable()) do
				local timeFrame = filmClip:GetTimeFrame()
				local start = timeFrame:GetStart()
				if(start > 0.0) then self.m_timeline:AddChapter(start) end
			end]]
		end
	end

	self:InitializeProjectUI()
	self:SetTimeOffset(0)

	return entScene
end
function gui.WIFilmmaker:OnFilmClipAdded(el)
	if(util.is_valid(self.m_timeline) == false) then return end
	self:AddFilmClipElement(newEl)
end
function gui.WIFilmmaker:AddFilmClipElement(filmClip)
	local pFilmClip = self.m_timeline:AddFilmClip(self.m_filmStrip,filmClip,function(elFilmClip)
		local filmClipData = elFilmClip:GetFilmClipData()
		if(util.is_valid(self:GetActorEditor())) then
			self:GetActorEditor():Setup(filmClipData)
		end
	end)
	pFilmClip:AddCallback("OnMouseEvent",function(pFilmClip,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("pfm_show_in_element_viewer"),function()
				self:ShowInElementViewer(filmClip)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	return pFilmClip
end
function gui.WIFilmmaker:ClearProjectUI()
	self:ClearLayout()
end
function gui.WIFilmmaker:InitializeProjectUI()
	self:ClearProjectUI()
	if(util.is_valid(self.m_menuBar) == false or util.is_valid(self.m_infoBar) == false) then return end
	self:InitializeGenericLayout()

	local actorDataFrame = self:AddFrame()
	self.m_actorDataFrame = actorDataFrame
	
	gui.create("WIResizer",self.m_contents):SetFraction(0.25)

	self.m_contentsRight = gui.create("WIVBox",self.m_contents)
	self.m_contents:Update()
	self.m_contentsRight:SetAutoFillContents(true)

	local viewportFrame = self:AddFrame(self.m_contentsRight)
	self.m_viewportFrame = viewportFrame
	viewportFrame:SetHeight(self:GetHeight())

	self:RegisterWindow(self.m_actorDataFrame,"actor_editor",locale.get_text("pfm_actor_editor"),function()
		local actorEditor = gui.create("WIPFMActorEditor")
		actorEditor:AddCallback("OnControlSelected",function(actorEditor,component,controlData,slider)
			local filmClip = actorEditor:GetFilmClip()
			if(filmClip == nil) then return end
			if(controlData.type == "flexController" or controlData.type == "bone") then
				local graphEditor = self:GetTimeline():GetGraphEditor()
				local itemCtrl = graphEditor:AddControl(filmClip,controlData)

				local fRemoveCtrl = function() if(util.is_valid(itemCtrl)) then itemCtrl:Remove() end end
				slider:AddCallback("OnDeselected",fRemoveCtrl)
				slider:AddCallback("OnRemove",fRemoveCtrl)
			else
				-- TODO: Allow generic properties?
			end
		end)
		return actorEditor
	end)
	self:RegisterWindow(self.m_actorDataFrame,"model_catalog",locale.get_text("pfm_model_catalog"),function()
		local mdlCatalog = gui.create("WIPFMModelCatalog")
		local explorer = mdlCatalog:GetExplorer()
		explorer:AddCallback("PopulateContextMenu",function(explorer,pContext,tSelectedFiles,tExternalFiles)
			local hasExternalFiles = (#tExternalFiles > 0)
			if(hasExternalFiles == true) then return end
			if(#tSelectedFiles == 1) then
				local path = tSelectedFiles[1]:GetRelativeAsset()
				pContext:AddItem(locale.get_text("pfm_show_in_model_viewer"),function()
					local pDialog,frame,el = gui.open_model_dialog()
					el:SetModel(path)
				end)

				if(asset.is_loaded(path,asset.TYPE_MODEL) == false) then
					pContext:AddItem(locale.get_text("pfm_load"),function()
						game.load_model(path)
					end)
				else
					local mdl = game.load_model(path)
					local materials = mdl:GetMaterials()
					if(#materials > 0) then
						local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_edit_material"))
						for _,mat in pairs(materials) do
							if(mat ~= nil and mat:IsError() == false) then
								local name = file.remove_file_extension(file.get_file_name(mat:GetName()))
								pSubMenu:AddItem(name,function(pItem)
									tool.get_filmmaker():OpenMaterialEditor(mat:GetName(),path)
								end)
							end
						end
						pSubMenu:Update()
					end
				end
			end
		end)
		explorer:AddCallback("OnIconAdded",function(explorer,icon)
			if(icon:IsDirectory() == false) then
				gui.enable_drag_and_drop(icon,"ModelCatalog",function(elGhost)
					elGhost:SetAlpha(128)
					elGhost:AddCallback("OnDragTargetHoverStart",function(elGhost,elTgt)
						elGhost:SetAlpha(0)
						elGhost:SetAlwaysUpdate(true)

						if(util.is_valid(entGhost)) then entGhost:Remove() end
						local path = util.Path(icon:GetAsset())
						path:PopFront()
						local mdlPath = path:GetString()
						if(icon:IsValid() and asset.exists(mdlPath,asset.TYPE_MODEL) == false) then icon:Reload(true) end -- Import the asset and generate the icon
						entGhost = ents.create("pfm_ghost")

						local ghostC = entGhost:GetComponent(ents.COMPONENT_PFM_GHOST)
						if(string.compare(elTgt:GetClass(),"WIViewport",false) and ghostC ~= nil) then
							ghostC:SetViewport(elTgt)
						end

						entGhost:Spawn()
						entGhost:SetModel(path:GetString())
					end)
					elGhost:AddCallback("OnDragTargetHoverStop",function(elGhost)
						elGhost:SetAlpha(128)
						elGhost:SetAlwaysUpdate(false)
						if(util.is_valid(entGhost)) then entGhost:Remove() end
					end)
				end)
				icon:AddCallback("OnDragDropped",function(elIcon,elDrop)
					if(util.is_valid(entGhost) == false) then return end
					local filmmaker = tool.get_filmmaker()
					local actor = filmmaker:CreateNewActor()
					if(actor == nil) then return end
					local mdlC = filmmaker:CreateNewActorComponent(actor,"PFMModel")
					if(mdlC == nil) then return end
					local path = util.Path(elIcon:GetAsset())
					path:PopFront()
					mdlC:SetModelName(path:GetString())
					local t = actor:GetTransform()
					t:SetPosition(entGhost:GetPos())
					t:SetRotation(entGhost:GetRotation())
					filmmaker:ReloadGameView() -- TODO: No need to reload the entire game view

					local mdl = game.load_model(path:GetString())
					if(mdl ~= nil) then
						for _,fc in ipairs(mdl:GetFlexControllers()) do
							mdlC:GetFlexControllerNames():PushBack(udm.String(fc.name))
						end
					end

					local entActor = actor:FindEntity()
					if(util.is_valid(entActor)) then
						local tc = entActor:AddComponent("util_transform")
						if(tc ~= nil) then
							tc:SetTranslationEnabled(false)
							tc:SetRotationAxisEnabled(math.AXIS_X,false)
							tc:SetRotationAxisEnabled(math.AXIS_Z,false)
							local trUtil = tc:GetTransformUtility(ents.UtilTransformArrowComponent.TYPE_ROTATION,math.AXIS_Y)
							local arrowC = util.is_valid(trUtil) and trUtil:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) or nil
							if(arrowC ~= nil) then
								arrowC:StartTransform()
								local cb
								cb = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
									if(mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
										if(util.is_valid(entActor)) then
											entActor:RemoveComponent("util_transform")
											t:SetPosition(entActor:GetPos())
											t:SetRotation(entActor:GetRotation())
										end
										cb:Remove()
										return util.EVENT_REPLY_HANDLED
									end
								end)
							end
						end
					end
				end)
			end
		end)
		return mdlCatalog
	end)
	self:RegisterWindow(self.m_actorDataFrame,"material_catalog",locale.get_text("pfm_material_catalog"),function() return gui.create("WIPFMMaterialCatalog") end)
	self:RegisterWindow(self.m_actorDataFrame,"particle_catalog",locale.get_text("pfm_particle_catalog"),function() return gui.create("WIPFMParticleCatalog") end)
	self:RegisterWindow(self.m_actorDataFrame,"tutorial_catalog",locale.get_text("pfm_tutorial_catalog"),function() return gui.create("WIPFMTutorialCatalog") end)
	self:RegisterWindow(self.m_actorDataFrame,"actor_catalog",locale.get_text("pfm_actor_catalog"),function() return gui.create("WIPFMActorCatalog") end)
	self:RegisterWindow(self.m_actorDataFrame,"element_viewer",locale.get_text("pfm_element_viewer"),function() return gui.create("WIPFMElementViewer") end)
	self:RegisterWindow(self.m_actorDataFrame,"material_editor",locale.get_text("pfm_material_editor"),function() return gui.create("WIPFMMaterialEditor") end)
	self:RegisterWindow(self.m_actorDataFrame,"particle_editor",locale.get_text("pfm_particle_editor"),function() return gui.create("WIPFMParticleEditor") end)

	self:RegisterWindow(self.m_viewportFrame,"primary_viewport",locale.get_text("pfm_primary_viewport"),function() return gui.create("WIPFMViewport") end)
	self:RegisterWindow(self.m_viewportFrame,"render",locale.get_text("pfm_render"),function()
		local el = gui.create("WIPFMRenderPreview")
		el:GetVisibilityProperty():AddCallback(function(wasVisible,isVisible)
			if(self.m_renderWasSceneCameraEnabled == nil) then self.m_renderWasSceneCameraEnabled = ents.PFMCamera.is_camera_enabled() end
			if(isVisible) then ents.PFMCamera.set_camera_enabled(false) -- Switch to game camera for VR renders
			else
				ents.PFMCamera.set_camera_enabled(self.m_renderWasSceneCameraEnabled)
				self.m_renderWasSceneCameraEnabled = nil
			end
		end)
		el:AddCallback("InitializeRender",function(el,rtJob,settings,preview)
			rtJob:AddCallback("PrepareFrame",function()
				if(self.m_renderWasSceneCameraEnabled == nil) then self.m_renderWasSceneCameraEnabled = ents.PFMCamera.is_camera_enabled() end
				ents.PFMCamera.set_camera_enabled(self.m_renderWasSceneCameraEnabled)
			end)
			rtJob:AddCallback("OnFrameStart",function()
				ents.PFMCamera.set_camera_enabled(false) -- Switch back to game cam for 360 preview
			end)
		end)
		return el
	end)
	self:RegisterWindow(self.m_viewportFrame,"post_processing",locale.get_text("pfm_post_processing"),function() return gui.create("WIPFMPostProcessing") end)
	self:RegisterWindow(self.m_viewportFrame,"video_player",locale.get_text("pfm_video_player"),function() return gui.create("WIPFMVideoPlayer") end)

	self:OpenWindow("actor_editor")
	self:OpenWindow("element_viewer")
	-- self:OpenWindow("tutorial_catalog")

	self:OpenWindow("primary_viewport")
	self:OpenWindow("render")

	gui.create("WIResizer",self.m_contentsRight):SetFraction(0.75)

	local timelineFrame = self:AddFrame(self.m_contentsRight)
	local pfmTimeline = gui.create("WIPFMTimeline")
	self.m_timeline = pfmTimeline
	timelineFrame:AddTab("timeline",locale.get_text("pfm_timeline"),pfmTimeline)

	-- Populate UI with project data
	local project = self:GetProject()
	local root = project:GetUDMRootNode()
	self:GetElementViewer():Setup(root)

	local playhead = pfmTimeline:GetPlayhead()
	self.m_playhead = playhead
	playhead:GetTimeOffsetProperty():AddCallback(function(oldOffset,offset)
		if(self.m_updatingProjectTimeOffset ~= true) then
			self:SetTimeOffset(offset)
		end
	end)
	local playButton = self:GetViewport():GetPlayButton()
	playButton:AddCallback("OnTimeAdvance",function(el,dt)
		if(playhead:IsValid()) then
			playhead:SetTimeOffset(playhead:GetTimeOffset() +dt)
		end
	end)
	playButton:AddCallback("OnStateChanged",function(el,oldState,state)
		ents.PFMSoundSource.set_audio_enabled(state == gui.PFMPlayButton.STATE_PLAYING)
		if(state == gui.PFMPlayButton.STATE_PAUSED) then
			self:ClampTimeOffsetToFrame()
		end
	end)

	pfmTimeline:AddCallback("OnClipSelected",function(el,clip)
		if(util.is_valid(self:GetActorEditor()) and util.get_type_name(clip) == "PFMFilmClip") then self:GetActorEditor():Setup(clip) end
	end)

	-- Film strip
	local session = project:GetSessions()[1]
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	local filmStrip
	if(filmClip ~= nil) then
		local timeline = pfmTimeline:GetTimeline()

		filmStrip = gui.create("WIFilmStrip")
		self.m_filmStrip = filmStrip
		filmStrip:SetScrollInputEnabled(true)
		filmStrip:AddCallback("OnScroll",function(el,x,y)
			if(timeline:IsValid()) then
				local axis = timeline:GetTimeAxis():GetAxis()
				timeline:SetStartOffset(axis:GetStartOffset() -y *axis:GetZoomLevelMultiplier())
				timeline:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_UNHANDLED
		end)

		local trackFilm = session:GetFilmTrack()
		if(trackFilm ~= nil) then
			for _,filmClip in ipairs(trackFilm:GetFilmClips():GetTable()) do
				self:AddFilmClipElement(filmClip)
			end
		end
		filmStrip:SetSize(1024,64)
		filmStrip:Update()

		local pfmClipEditor = pfmTimeline:GetEditorTimelineElement(gui.PFMTimeline.EDITOR_CLIP)
		local groupPicture = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_picture"))
		if(filmStrip ~= nil) then
			for _,filmClip in ipairs(filmStrip:GetFilmClips()) do
				timeline:AddTimelineItem(filmClip,filmClip:GetTimeFrame())
			end
		end
		groupPicture:AddElement(filmStrip)

		local timeFrame = filmClip:GetTimeFrame()
		local groupSound = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_sound"))
		local trackGroupSound = filmClip:GetTrackGroups():FindElementsByName("Sound")[1]
		if(trackGroupSound ~= nil) then
			for _,track in ipairs(trackGroupSound:GetTracks():GetTable()) do
				--if(track:GetName() == "Music") then
					local subGroup = groupSound:AddGroup(track:GetName())
					timeline:AddTimelineItem(subGroup,timeFrame)

					for _,audioClip in ipairs(track:GetAudioClips():GetTable()) do
						pfmTimeline:AddAudioClip(subGroup,audioClip)
					end
				--end
			end
		end

		local groupOverlay = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_overlay"))
		local trackGroupOverlay = filmClip:GetTrackGroups():FindElementsByName("Overlay")[1]
		if(trackGroupOverlay ~= nil) then
			for _,track in ipairs(trackGroupOverlay:GetTracks():GetTable()) do
				local subGroup = groupOverlay:AddGroup(track:GetName())
				timeline:AddTimelineItem(subGroup,timeFrame)

				for _,overlayClip in ipairs(track:GetOverlayClips():GetTable()) do
					pfmTimeline:AddOverlayClip(subGroup,overlayClip)
				end
			end
		end

		local activeBookmarkSet = filmClip:GetActiveBookmarkSet()
		local bookmarkSet = filmClip:GetBookmarkSets():Get(activeBookmarkSet +1)
		if(bookmarkSet ~= nil) then
			for _,bookmark in ipairs(bookmarkSet:GetBookmarks():GetTable()) do
				timeline:AddBookmark(bookmark:GetTimeRange():GetTimeAttr())
			end
		end
	end
end
function gui.WIFilmmaker:OpenMaterialEditor(mat,optMdl)
	self:CloseWindow("material_editor")
	local tab,matEd = self:OpenWindow("material_editor",true)
	matEd:SetMaterial(mat,optMdl)
end
function gui.WIFilmmaker:OpenParticleEditor(ptFile,ptName)
	self:CloseWindow("particle_editor")
	local tab,ptEd = self:OpenWindow("particle_editor",true)
	ptEd:LoadParticleSystem(ptFile,ptName)
end
function gui.WIFilmmaker:OnActorSelectionChanged(ent,selected)
	self:TagRenderSceneAsDirty()
	if(util.is_valid(self:GetViewport()) == false) then return end
	self:GetViewport():OnActorSelectionChanged(ent,selected)
end
function gui.WIFilmmaker:GetActiveCamera()
	return game.get_render_scene_camera()
end
function gui.WIFilmmaker:GetActiveFilmClip()
	local session = self:GetSession()
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	return (filmClip ~= nil) and filmClip:GetChildFilmClip(self:GetTimeOffset()) or nil
end
function gui.WIFilmmaker:ShowInElementViewer(el)
	if(util.is_valid(self:GetElementViewer()) == false) then return end
	self:GetElementViewer():MakeElementRoot(el)

	self:GoToWindow("element_viewer")
end
function gui.WIFilmmaker:SelectActor(actor)
	if(util.is_valid(self:GetActorEditor()) == false) then return end
	self:GetActorEditor():SelectActor(actor)

	self:GoToWindow("actor_editor")
end
function gui.WIFilmmaker:ExportAnimation(actor)
	if(self.m_animRecorder ~= nil) then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end
	local activeFilmClip = self:GetActiveFilmClip()
	if(activeFilmClip == nil) then return end
	local recorder = pfm.AnimationRecorder(actor,activeFilmClip)
	recorder:StartRecording()
	self.m_animRecorder = recorder
end
function gui.WIFilmmaker:GetSelectedClip() return self:GetTimeline():GetSelectedClip() end
function gui.WIFilmmaker:GetTimeline() return self.m_timeline end
function gui.WIFilmmaker:GetFilmStrip() return self.m_filmStrip end
gui.register("WIFilmmaker",gui.WIFilmmaker)

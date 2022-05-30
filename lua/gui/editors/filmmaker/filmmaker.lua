--[[
    Copyright (C) 2021 Silverlan

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
include("/gui/bone_retargeting.lua")
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
include("/gui/pfm/webbrowser.lua")
include("/pfm/util_particle_system.lua")
include("/pfm/auto_save.lua")
include("/util/table_bininsert.lua")

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

local function updateAutosave()
	local fm = tool.get_filmmaker()
	if(util.is_valid(fm)) then fm:UpdateAutosave() end
end
console.add_change_callback("pfm_autosave_enabled",updateAutosave)
console.add_change_callback("pfm_autosave_time_interval",updateAutosave)

function gui.WIFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
	pfm.ProjectManager.__init(self)

	pfm.set_project_manager(self)
end
include("/pfm/bake/ibl.lua")
function gui.WIFilmmaker:CheckForUpdates(verbose)
	if(util.is_valid(self.m_updateChecker)) then return end
	-- TODO: Locale, etc
	local url = "http://wiki.pragma-engine.com/queries/query_version.php"
	self.m_updateChecker = util.UpdateChecker(url,function(version)
		if(version > pfm.VERSION) then
			-- New version available!
			local updateUrl = "https://wiki.pragma-engine.com/download_pfm.php"
			local el = pfm.create_popup_message(locale.get_text("vrp_new_version_available",{version:ToString(),updateUrl}))
			el:SetMouseInputEnabled(true)
			el:SetCursor(gui.CURSOR_SHAPE_HAND)
			el:AddCallback("OnMouseEvent",function(el,button,state,mods)
				if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
					util.open_url_in_browser(updateUrl)
					return util.EVENT_REPLY_HANDLED
				end
			end)
		elseif(verbose) then
			pfm.create_popup_message(locale.get_text("vrp_up_to_date",{pfm.VERSION:ToString()}))
		end
	end)
end
function gui.WIFilmmaker:OnInitialize()
	self:SetDeveloperModeEnabled(tool.is_developer_mode_enabled())

	gui.WIBaseEditor.OnInitialize(self)
	tool.editor = self -- TODO: This doesn't really belong here (check lua/autorun/client/cl_filmmaker.lua)
	tool.filmmaker = self
	fudm.PFMChannel.set_all_channels_enabled(false)

	local udmData,err = udm.load("cfg/pfm/keybindings.udm")
	local layers = {}
	if(udmData ~= false) then
		local loadedLayers = input.InputBindingLayer.load(udmData:GetAssetData())
		if(loadedLayers ~= false) then
			for _,layer in ipairs(loadedLayers) do layers[layer.identifier] = layer end
		end
	end
	if(layers["pfm"] == nil) then
		local bindingLayer = input.InputBindingLayer("pfm")
		bindingLayer:BindKey("space","pfm_action toggle_play")
		bindingLayer:BindKey(",","pfm_action previous_frame")
		bindingLayer:BindKey(".","pfm_action next_frame")
		bindingLayer:BindKey("[","pfm_action previous_bookmark")
		bindingLayer:BindKey("]","pfm_action next_bookmark")
		bindingLayer:BindKey("m","pfm_action create_bookmark")

		bindingLayer:BindKey("f2","pfm_action select_editor clip")
		bindingLayer:BindKey("f3","pfm_action select_editor motion")
		bindingLayer:BindKey("f4","pfm_action select_editor graph")
		layers["pfm"] = bindingLayer
	end
	if(layers["pfm_graph_editor"] == nil) then
		local bindingLayer = input.InputBindingLayer("pfm_graph_editor")
		bindingLayer:BindKey("m","pfm_graph_editor_action bookmark")

		bindingLayer:BindKey("q","pfm_graph_editor_action select select")
		bindingLayer:BindKey("w","pfm_graph_editor_action select move")
		bindingLayer:BindKey("e","pfm_graph_editor_action select pan")
		bindingLayer:BindKey("r","pfm_graph_editor_action select scale")
		bindingLayer:BindKey("t","pfm_graph_editor_action select zoom")

		bindingLayer:BindKey("1","pfm_graph_editor_action select tangent_linear")
		bindingLayer:BindKey("2","pfm_graph_editor_action select tangent_flat")
		bindingLayer:BindKey("3","pfm_graph_editor_action select tangent_spline")
		bindingLayer:BindKey("4","pfm_graph_editor_action select tangent_step")
		bindingLayer:BindKey("5","pfm_graph_editor_action select tangent_unify")
		bindingLayer:BindKey("6","pfm_graph_editor_action select tangent_equalize")
		bindingLayer:BindKey("7","pfm_graph_editor_action select tangent_weighted")
		bindingLayer:BindKey("8","pfm_graph_editor_action select tangent_unweighted")

		-- TODO: Enable these when modifier keybinds are implemented
		-- bindingLayer:BindKey("n","pfm_graph_editor_action select snap")
		-- bindingLayer:BindKey("r","pfm_graph_editor_action select snap_frame")

		-- bindingLayer:BindKey("m","pfm_graph_editor_action select mute")
		layers["pfm_graph_editor"] = bindingLayer
	end
	if(layers["pfm_viewport"] == nil) then
		local bindingLayer = input.InputBindingLayer("pfm_viewport")
		bindingLayer:BindKey("scrlup","pfm_action zoom in")
		bindingLayer:BindKey("scrldn","pfm_action zoom out")

		layers["pfm_viewport"] = bindingLayer
	end
	layers["pfm"].priority = 1000
	layers["pfm_graph_editor"].priority = 2000
	for _,layer in pairs(layers) do
		input.add_input_binding_layer(layer)
		input.set_binding_layer_enabled(layer.identifier,(layer.identifier == "pfm"))
	end
	self.m_inputBindingLayers = layers
	self:UpdateInputBindings()

	local infoBar = self:GetInfoBar()

	local infoBarContents = infoBar:GetContents()
	local patronTickerContainer = gui.create("PatreonTicker",infoBarContents,0,0,infoBarContents:GetWidth(),infoBarContents:GetHeight(),0,0,1,1)
	patronTickerContainer:SetQueryUrl("http://pragma-engine.com/patreon/request_patrons.php")
	local engineInfo = engine.get_info()
	infoBar:AddIcon("wgui/patreon_logo",pfm.PATREON_JOIN_URL,"Patreon")
	-- infoBar:AddIcon("third_party/twitter_logo",engineInfo.twitterURL,"Twitter")
	-- infoBar:AddIcon("third_party/reddit_logo",engineInfo.redditURL,"Reddit")
	infoBar:AddIcon("third_party/discord_logo",engineInfo.discordURL,"Discord")

	local elVersion = gui.create("WIText")
	elVersion:SetColor(Color.White)
	elVersion:SetText("v" .. pfm.VERSION:ToString())
	elVersion:SetFont("pfm_medium")
	elVersion:SetColor(Color(200,200,200))
	elVersion:SetY(5)
	elVersion:SizeToContents()

	infoBar:AddRightElement(elVersion)
	local gap = gui.create("WIBase")
	gap:SetSize(10,1)
	infoBar:AddRightElement(gap)
	
	infoBar:Update()

	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local scene = ents.create_scene(sceneCreateInfo) -- ,gameScene)
	scene:SetRenderer(gameRenderer)
	scene:SetActiveCamera(gameScene:GetActiveCamera())
	self.m_overlayScene = scene

	local sceneDepth = ents.create_scene(sceneCreateInfo,gameScene)
	sceneDepth:SetRenderer(gameRenderer)
	sceneDepth:SetActiveCamera(gameScene:GetActiveCamera())
	self.m_sceneDepth = sceneDepth

	-- Disable default scene drawing for the lifetime of the Filmmaker; We'll only render the viewport(s) if something has actually changed, which
	-- saves up a huge amount of rendering resources.
	self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes",function(drawSceneInfo)
		self:PreRenderScenes(drawSceneInfo)
	end)
	self.m_cbDisableDefaultSceneDraw = game.add_callback("RenderScenes",function(drawSceneInfo)
		if(self.m_renderSceneDirty == nil) then
			game.set_default_game_render_enabled(false)
			return
		end
		drawSceneInfo.renderFlags = bit.band(drawSceneInfo.renderFlags,bit.bnot(game.RENDER_FLAG_BIT_VIEW))
		self.m_renderSceneDirty = self.m_renderSceneDirty -1
		if(self.m_renderSceneDirty == 0) then self.m_renderSceneDirty = nil end
		return false
	end)
	game.set_default_game_render_enabled(false)

	self:EnableThinking()
	self:SetSize(1280,1024)
	self:SetSkin("pfm")
	self.m_selectionManager = pfm.ActorSelectionManager()
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

		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("new"))
		pSubMenu:AddItem(locale.get_text("pfm_simple_project"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:CreateSimpleProject()
		end)
		pSubMenu:AddItem(locale.get_text("pfm_empty_project"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:CreateEmptyProject()
		end)
		pSubMenu:Update()

		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			util.remove(self.m_openDialogue)
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				fileName = "projects/" .. fileName
				self:LoadProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("projects")
			self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())
			self.m_openDialogue:Update()
		end)
		pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			self:Save()
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
				self:Start()
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
		if(self:IsDeveloperModeEnabled()) then
			local recorder
			pContext:AddItem("Record animation as image sequence",function(pItem)
				if(recorder == nil or recorder:IsRecording() == false) then
					include("/gui/editors/filmmaker/image_recorder.lua")

					recorder = pfm.ImageRecorder(self)
					file.create_path("render/recording/recording")
					recorder:StartRecording("render/recording/recording")
				else
					recorder:StopRecording()
					recorder = nil
				end
			end)
			pContext:AddItem("Generate lightmap uvs",function(pItem)
				local actorEditor = self:GetActorEditor()
				if(util.is_valid(actorEditor) == false) then return end
				for _,actor in ipairs(actorEditor:GetSelectedActors()) do
					local ent = actor:FindEntity()
					if(util.is_valid(ent)) then
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
						local bakedC = ent:AddComponent("pfm_baked_lighting")
						bakedC:GenerateLightmapUvs()
					end
				end
			end)
			pContext:AddItem("Test build lightmaps Low",function(pItem)
				local actorEditor = self:GetActorEditor()
				if(util.is_valid(actorEditor) == false) then return end
				for _,actor in ipairs(actorEditor:GetSelectedActors()) do
					local ent = actor:FindEntity()
					if(util.is_valid(ent)) then
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
						local bakedC = ent:AddComponent("pfm_baked_lighting")
						bakedC:GenerateLightmaps(false,10)
					end
				end
			end)
			pContext:AddItem("Test build lightmaps High",function(pItem)
				local actorEditor = self:GetActorEditor()
				if(util.is_valid(actorEditor) == false) then return end
				for _,actor in ipairs(actorEditor:GetSelectedActors()) do
					local ent = actor:FindEntity()
					if(util.is_valid(ent)) then
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
						ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
						local bakedC = ent:AddComponent("pfm_baked_lighting")
						bakedC:GenerateLightmaps(false,10)
					end
				end
			end)

			pContext:AddItem(locale.get_text("pfm_reload_in_dev_mode"),function(pItem)
				console.run("pfm -log all -dev -reload")
			end)
		end

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

	console.run("cl_max_fps",tostring(console.get_convar_int("pfm_max_fps")))

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
	if(unirender ~= nil) then unirender.set_log_enabled(pfm.is_log_category_enabled(pfm.LOG_CATEGORY_PFM_UNIRENDER)) end
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
	pfm.ProjectManager.OnInitialize(self)
	self:SetCachedMode(false)
end
function gui.WIFilmmaker:PreRenderScenes(drawSceneInfo)
	if(self.m_overlaySceneEnabled ~= true) then return end
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if(util.is_valid(rt)) then
		local el = rt:GetToneMappedImageElement()
		if(util.is_valid(el)) then
			local tex = gameRenderer:GetSceneTexture()
			local texRt = el:GetTexture()
			if(texRt ~= nil) then
				local drawCmd = drawSceneInfo.commandBuffer
				drawCmd:RecordImageBarrier(texRt:GetImage(),prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
				drawCmd:RecordImageBarrier(tex:GetImage(),prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
				drawCmd:RecordBlitImage(texRt:GetImage(),tex:GetImage(),prosper.BlitInfo())
				drawCmd:RecordImageBarrier(texRt:GetImage(),prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
				drawCmd:RecordImageBarrier(tex:GetImage(),prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
			end
		end
	end

	-- Render depth only
	local drawSceneInfoDepth = game.DrawSceneInfo()
	drawSceneInfoDepth.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfoDepth.scene = self.m_sceneDepth
	drawSceneInfoDepth.flags = bit.bor(drawSceneInfoDepth.flags,game.DrawSceneInfo.FLAG_DISABLE_LIGHTING_PASS_BIT)
	drawSceneInfoDepth.clearColor = Color.Lime

	-- Render overlay objects (e.g. object wireframes)
	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfo.scene = self.m_overlayScene
	drawSceneInfo.renderFlags = bit.band(drawSceneInfo.renderFlags,bit.bnot(game.RENDER_FLAG_BIT_VIEW)) -- Don't render view models

	-- Does not work for some reason?
	-- drawSceneInfo.flags = bit.bor(drawSceneInfo.flags,game.DrawSceneInfo.FLAG_DISABLE_PREPASS_BIT)
	-- drawSceneInfo:AddSubPass(drawSceneInfoDepth)

	game.queue_scene_for_rendering(drawSceneInfo)
	--
end
function gui.WIFilmmaker:GetOverlayScene() return self.m_overlayScene end
function gui.WIFilmmaker:SetOverlaySceneEnabled(enabled)
	console.run("render_clear_scene " .. (enabled and "0" or "1"))
	self.m_overlaySceneEnabled = enabled
	game.set_default_game_render_enabled(enabled == false)
	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:Save(fileName,setAsProjectName)
	if(setAsProjectName == nil) then setAsProjectName = true end
	local project = self:GetProject()
	if(project == nil) then return end
	local function saveProject(fileName)
		file.create_directory("projects")
		fileName = file.remove_file_extension(fileName,pfm.Project.get_format_extensions())
		self:SaveProject(pfm.Project.get_full_project_file_name(fileName),setAsProjectName and ("projects/" .. fileName) or nil)
	end
	if(fileName == nil) then
		local projectFileName = self:GetProjectFileName()
		if(projectFileName ~= nil) then
			fileName = util.Path.CreateFilePath(projectFileName)
			fileName:PopFront() -- Pop "projects/"
			fileName = fileName:GetString()
		end
	end
	if(fileName ~= nil) then saveProject(fileName)
	else
		util.remove(self.m_openDialogue)
		self.m_openDialogue = gui.create_file_save_dialog(function(pDialog,fileName)
			saveProject(fileName)
		end)
		self.m_openDialogue:SetRootPath("projects")
		self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())
		self.m_openDialogue:Update()
	end
end
function gui.WIFilmmaker:CreateInitialProject() self:CreateSimpleProject(true) end
function gui.WIFilmmaker:CreateSimpleProject()
	self:CreateEmptyProject()

	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end

	actorEditor:AddSkyActor()
	local cam = actorEditor:CreateNewActorWithComponents("camera",{"pfm_actor","pfm_camera","camera"})

	local entProbe = actorEditor:CreateNewActorWithComponents("reflection_probe",{
		"pfm_actor",
		{
			"reflection_probe",
			function(c)
				c:SetMemberValue("iblStrength",udm.TYPE_FLOAT,1.4)
				c:SetMemberValue("iblMaterial",udm.TYPE_STRING,"pbr/ibl/venice_sunset")
			end
		}
	})

	local filmClip = self:GetActiveGameViewFilmClip()
	if(filmClip ~= nil) then filmClip:SetCamera(cam) end
end
function gui.WIFilmmaker:CreateEmptyProject()
	self:CreateNewProject()

	local filmClip = self:GetActiveFilmClip()
	if(filmClip == nil) then return end

	self:SelectFilmClip(filmClip)
end
function gui.WIFilmmaker:PackProject(fileName)
	local project = self:GetProject()
	local session = self:GetSession()

	local assetFiles = project:CollectAssetFiles()
	local projectFileName = self:GetProjectFileName()
	if(projectFileName ~= nil) then table.insert(assetFiles,projectFileName) end
	
	fileName = file.remove_file_extension(fileName) .. ".zip"
	util.pack_zip_archive(fileName,assetFiles)
	util.open_path_in_explorer(util.get_addon_path(),fileName)
end
function gui.WIFilmmaker:AddActor(filmClip)
	local actor = filmClip:GetScene():AddActor()
	self:UpdateActor(actor,filmClip)
	return actor
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
	if(filmClipC ~= nil) then
		filmClipC:InitializeActors()
		filmClipC:UpdateCamera()
	end
	self:TagRenderSceneAsDirty()
	self:SetTimeOffset(self:GetTimeOffset()) -- Refresh animation
end
function gui.WIFilmmaker:StopLiveRaytracing()
	local vp = self:GetViewport()
	if(util.is_valid(vp) == false) then return end
	vp:StopLiveRaytracing()
end
function gui.WIFilmmaker:TagRenderSceneAsDirty(dirty)
	if(self.m_overlaySceneEnabled ~= true) then game.set_default_game_render_enabled(true) end
	if(dirty == nil) then
		self.m_renderSceneDirty = self.m_renderSceneDirty or 24
		return
	end
	self.m_renderSceneDirty = dirty and math.huge or nil
end
function gui.WIFilmmaker:OnProjectClosed()
	pfm.ProjectManager.OnProjectClosed(self)
	self:UpdateAutosave(true)
end
function gui.WIFilmmaker:ReloadInterface()
	local projectData = self:MakeProjectPersistent()
	self:Close()

	local interface = tool.open_filmmaker()
	interface:RestorePersistentProject(projectData)
end
function gui.WIFilmmaker:GetGameScene() return self:GetRenderTab():GetGameScene() end
function gui.WIFilmmaker:GetGameplayViewport()
	for _,vp in ipairs({self:GetViewport(),self:GetSecondaryViewport(),self:GetTertiaryViewport()}) do
		if(vp:IsValid()) then
			if(vp:IsInCameraControlMode()) then return vp end
		end
	end
end
function gui.WIFilmmaker:GetGameplayCamera()
	local vp = self:GetGameplayViewport()
	if(vp == nil) then return end
	return vp:GetCamera()
end
function gui.WIFilmmaker:GetViewport() return self:GetWindow("primary_viewport") or nil end
function gui.WIFilmmaker:GetViewportElement()
	local vp = self:GetWindow("primary_viewport")
	return util.is_valid(vp) and vp:GetViewport() or nil
end
function gui.WIFilmmaker:GetSecondaryViewport() return self:GetWindow("secondary_viewport") or nil end
function gui.WIFilmmaker:GetTertiaryViewport() return self:GetWindow("tertiary_viewport") or nil end
function gui.WIFilmmaker:GetRenderTab() return self:GetWindow("render") or nil end
function gui.WIFilmmaker:GetActorEditor() return self:GetWindow("actor_editor") or nil end
function gui.WIFilmmaker:GetElementViewer() return self:GetWindow("element_viewer") or nil end
function gui.WIFilmmaker:CreateNewActor()
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActor()
end
function gui.WIFilmmaker:CreateNewActorComponent(actor,componentType,updateActor,initComponent)
	-- TODO: What if no actor editor is open?
	return self:GetActorEditor():CreateNewActorComponent(actor,componentType,updateActor,initComponent)
end
function gui.WIFilmmaker:OnGameViewCreated(projectC)
	pfm.GameView.OnGameViewCreated(self,projectC)
	projectC:AddEventCallback(ents.PFMProject.EVENT_ON_ENTITY_CREATED,function(ent)
		local trackC = ent:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:SetKeepClipsAlive(false) end
	end)
end
function gui.WIFilmmaker:GoToNeighborBookmark(next)
	local timeline = self:GetTimeline()
	local bookmarkTimes = {}
	for _,bm in ipairs(timeline:GetBookmarks()) do
		table.insert(bookmarkTimes,bm:GetBookmark():GetTime())
	end
	table.sort(bookmarkTimes)

	if(#bookmarkTimes == 0) then return end

	local t = self:GetTimeOffset()
	if(next and t < bookmarkTimes[1]) then
		self:SetTimeOffset(bookmarkTimes[1])
		return
	end
	if(not next and t > bookmarkTimes[#bookmarkTimes]) then
		self:SetTimeOffset(bookmarkTimes[#bookmarkTimes])
		return
	end

	if(next) then
		for i=1,#bookmarkTimes -1 do
			local bm0 = bookmarkTimes[i]
			local bm1 = bookmarkTimes[i +1]
			if(t >= bm0 and t < bm1) then
				self:SetTimeOffset(bm1)
				break
			end
		end
	else
		for i=#bookmarkTimes,2,-1 do
			local bm0 = bookmarkTimes[i -1]
			local bm1 = bookmarkTimes[i]
			if(t > bm0 and t <= bm1) then
				self:SetTimeOffset(bm0)
				break
			end
		end
	end
end
function gui.WIFilmmaker:GoToNextBookmark() self:GoToNeighborBookmark(true) end
function gui.WIFilmmaker:GoToPreviousBookmark() self:GoToNeighborBookmark(false) end
function gui.WIFilmmaker:KeyboardCallback(key,scanCode,state,mods)
	if(input.is_ctrl_key_down()) then
		if(key == input.KEY_S) then
			if(state == input.STATE_PRESS) then self:Save() end
			return util.EVENT_REPLY_HANDLED
		elseif(key == input.KEY_C) then
			if(state == input.STATE_PRESS) then
				local actorEditor = self:GetActorEditor()
				if(util.is_valid(actorEditor)) then
					actorEditor:CopyToClipboard()
				end
			end
			return util.EVENT_REPLY_HANDLED
		elseif(key == input.KEY_V) then
			if(state == input.STATE_PRESS) then
				local actorEditor = self:GetActorEditor()
				if(util.is_valid(actorEditor)) then
					actorEditor:PasteFromClipboard()
				end
			end
			return util.EVENT_REPLY_HANDLED
		end
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
		projectC:SetPlaybackOffset(projectC:GetPlaybackOffset() +self.m_videoRecorder:GetFrameDeltaTime())
		self:CaptureRaytracedImage()
	end
end
function gui.WIFilmmaker:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
	self:CloseProject()
	util.remove(self.m_cbDisableDefaultSceneDraw)
	util.remove(self.m_cbPreRenderScenes)
	if(util.is_valid(self.m_overlayScene)) then self.m_overlayScene:GetEntity():Remove() end
	if(util.is_valid(self.m_sceneDepth)) then self.m_sceneDepth:GetEntity():Remove() end
	util.remove(self.m_cbDropped)
	util.remove(self.m_openDialogue)
	util.remove(self.m_previewWindow)
	util.remove(self.m_renderResultWindow)
	self.m_selectionManager:Remove()

	if(self.m_animRecorder ~= nil) then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end

	-- util.remove(self.m_reflectionProbe)
	-- util.remove(self.m_entLight)

	local layers = {}
	for _,layer in pairs(self.m_inputBindingLayers) do table.insert(layers,layer) end
	local udmData,err = udm.create("PFMKB",1)
	local assetData = udmData:GetAssetData()
	input.InputBindingLayer.save(assetData,layers)
	file.create_path("cfg/pfm")
	local f = file.open("cfg/pfm/keybindings.udm",file.OPEN_MODE_WRITE)
	if(f ~= nil) then
		udmData:SaveAscii(f)
		f:Close()
	end
	for _,layer in ipairs(self.m_inputBindingLayers) do input.remove_input_binding_layer(layer.identifier) end
	self:UpdateInputBindings()

	collectgarbage()
end
function gui.WIFilmmaker:GetInputBindingLayers() return self.m_inputBindingLayers end
function gui.WIFilmmaker:GetInputBindingLayer(id) return self.m_inputBindingLayers[id or "pfm"] end
function gui.WIFilmmaker:UpdateInputBindings() input.update_effective_input_bindings() end
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
function gui.WIFilmmaker:UpdateAutosave(clear)
	if(self.m_autoSave ~= nil) then
		self.m_autoSave:Clear()
		self.m_autoSave = nil
	end
	if(clear or console.get_convar_bool("pfm_autosave_enabled") == false) then return end
	self.m_autoSave = pfm.AutoSave()
end
function gui.WIFilmmaker:IsAutosaveEnabled() return self.m_autoSave ~= nil end
function gui.WIFilmmaker:InitializeProject(project)
	self:UpdateAutosave()
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
			--[[filmTrack:GetFilmClipsAttr():AddChangeListener(function(newEl)
				if(util.is_valid(self.m_timeline) == false) then return end
				self:AddFilmClipElement(newEl)
				self:ReloadGameView() -- TODO: We don't really need to refresh the entire game view, just the current film clip would be sufficient.
			end)]]

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

	local cam = self:GetActiveCamera()
	if(util.is_valid(cam)) then
		local pos = cam:GetEntity():GetPos()
		console.run("setpos",tostring(pos.x),tostring(pos.y),tostring(pos.z))

		local ang = cam:GetEntity():GetAngles()
		console.run("setang",tostring(ang.p),tostring(ang.y),0)
	end

	return entScene
end
function gui.WIFilmmaker:OnFilmClipAdded(el)
	if(util.is_valid(self.m_timeline) == false) then return end
	self:AddFilmClipElement(newEl)
end
function gui.WIFilmmaker:SelectFilmClip(filmClip)
	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end
	actorEditor:Setup(filmClip)
end
function gui.WIFilmmaker:AddFilmClipElement(filmClip)
	local pFilmClip = self.m_timeline:AddFilmClip(self.m_filmStrip,filmClip,function(elFilmClip)
		local filmClipData = elFilmClip:GetFilmClipData()
		if(util.is_valid(self:GetActorEditor())) then
			self:SelectFilmClip(filmClipData)
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
function gui.WIFilmmaker:UpdateKeyframe(actor,targetPath,panimaChannel,keyIdx,time,value,baseIndex)
	local animManager = self:GetAnimationManager()
	animManager:UpdateKeyframe(actor,targetPath,panimaChannel,keyIdx,time,value,baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor)) then actorEditor:UpdateActorProperty(actor,targetPath) end
end
function gui.WIFilmmaker:SetActorAnimationComponentProperty(actor,targetPath,time,value,valueType,baseIndex)
	local animManager = self:GetAnimationManager()
	animManager:SetChannelValue(actor,targetPath,time,value,valueType,nil,baseIndex)

	animManager:SetAnimationDirty(actor)
	pfm.tag_render_scene_as_dirty()

	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor)) then actorEditor:UpdateActorProperty(actor,targetPath) end
end
function gui.WIFilmmaker:SetActorGenericProperty(actor,targetPath,value,udmType)
	local actorData = actor:GetActorData()
	if(actorData == nil) then return end
	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) and actorEditor:GetTimelineMode() == gui.PFMTimeline.EDITOR_GRAPH) then
		actorEditor:SetAnimationChannelValue(actorData,targetPath,value)
		return
	end

	self:GetAnimationManager():SetAnimationDirty(actorData)
	actor:GetEntity():SetMemberValue(targetPath,value)
	if(udmType ~= nil) then
		local componentName,memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
		if(componentName ~= nil) then
			local c = actorData:AddComponentType(componentName)
			c:SetMemberValue(memberName:GetString(),udmType,value)
		end
	end
	self:GetActorEditor():UpdateActorProperty(actorData,targetPath)
	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:SetActorTransformProperty(actor,propType,value,applyUdmValue)
	local actorData = actor:GetActorData()
	if(actorData == nil) then return end
	local actorEditor = self:GetActorEditor()
	local targetPath = "ec/pfm_actor/" .. propType
	if(util.is_valid(actorEditor) and actorEditor:GetTimelineMode() == gui.PFMTimeline.EDITOR_GRAPH) then
		actorEditor:SetAnimationChannelValue(actorData,targetPath,value)
		if(applyUdmValue) then
			local actorC = actorData:AddComponentType("pfm_actor")
			if(propType == "position") then actorC:SetMemberValue(propType,udm.TYPE_VECTOR3,value)
			elseif(propType == "rotation") then actorC:SetMemberValue(propType,udm.TYPE_QUATERNION,value)
			elseif(propType == "scale") then actorC:SetMemberValue(propType,udm.TYPE_VECTOR3,value) end
		end
		return
	end
	local transform = actorData:GetTransform()
	if(propType == "position") then transform:SetOrigin(value)
	elseif(propType == "rotation") then transform:SetRotation(value)
	elseif(propType == "scale") then transform:SetScale(value) end
	actorData:SetTransform(transform)
	self:TagRenderSceneAsDirty()

	self:GetAnimationManager():SetAnimationDirty(actorData)
	actor:GetEntity():SetMemberValue(targetPath,value)
	self:GetActorEditor():UpdateActorProperty(actorData,targetPath)
end
function gui.WIFilmmaker:SetActorBoneTransformProperty(actor,propType,value)
	local actorData = actor:GetActorData()
	if(actorData == nil) then return end
	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) and actorEditor:GetTimelineMode() == gui.PFMTimeline.EDITOR_GRAPH) then
		actorEditor:SetAnimationChannelValue(actorData,"ec/animated/bone/" .. propType,value)
		return
	end
	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:OnActorControlSelected(actorEditor,actor,component,controlData,slider)
	local memberInfo = controlData.getMemberInfo(controlData.name)
	if(memberInfo == nil) then return end
	local filmClip = actorEditor:GetFilmClip()
	if(filmClip == nil) then return end
	local graphEditor = self:GetTimeline():GetGraphEditor()
	local itemCtrl = graphEditor:AddControl(filmClip,actor,controlData,memberInfo)

	local fRemoveCtrl = function() if(util.is_valid(itemCtrl)) then itemCtrl:Remove() end end
	slider:AddCallback("OnDeselected",fRemoveCtrl)
	slider:AddCallback("OnRemove",fRemoveCtrl)
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
		actorEditor:AddCallback("OnControlSelected",function(actorEditor,actor,component,controlData,slider)
			self:OnActorControlSelected(actorEditor,actor,component,controlData,slider)
		end)
		return actorEditor
	end)
	self:RegisterWindow(self.m_actorDataFrame,"bone_retargeting",locale.get_text("pfm_bone_retargeting"),function()
		local p = gui.create("WIBoneRetargeting")
		self:OpenModelView()
		p:SetModelView(self.m_mdlView)
		return p
	end)
	self:RegisterWindow(viewportFrame,"model_viewer",locale.get_text("vrp_model_viewer"),function()
		local playerBox = gui.create("WIVBox")
		playerBox:SetAutoFillContents(true)

		local vrBox = gui.create("WIBase",playerBox)
		vrBox:SetSize(128,128)
		local aspectRatioWrapper = gui.create("WIAspectRatio",vrBox)
		aspectRatioWrapper:AddCallback("OnAspectRatioChanged",function(el,aspectRatio)
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
		end)
		local vpWrapper = gui.create("WIBase",aspectRatioWrapper)
		vpWrapper:SetSize(10,10)

		local width = self:GetWidth()
		local height = self:GetHeight()
		local modelView = gui.create("WIModelView",vpWrapper,0,0,vpWrapper:GetWidth(),vpWrapper:GetHeight(),0,0,1,1)
		modelView:SetClearColor(Color.Black)
		modelView:InitializeViewport(width,height)
		modelView:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
		modelView:RequestFocus()

		aspectRatioWrapper:SetWidth(vrBox:GetWidth())
		aspectRatioWrapper:SetHeight(vrBox:GetHeight())
		aspectRatioWrapper:SetAnchor(0,0,1,1)

		self.m_mdlView = modelView
		local pRetarget = self:GetWindow("bone_retargeting")
		if(util.is_valid(pRetarget)) then pRetarget:SetModelView(modelView) end
		return playerBox
	end)
	self:RegisterWindow(self.m_actorDataFrame,"model_catalog",locale.get_text("pfm_model_catalog"),function()
		local mdlCatalog = gui.create("WIPFMModelCatalog")
		local explorer = mdlCatalog:GetExplorer()
		explorer:AddCallback("PopulateIconContextMenu",function(explorer,pContext,tSelectedFiles,tExternalFiles)
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
					local filmClip = self:GetActiveFilmClip()
					if(filmClip == nil) then return end
					local filmmaker = tool.get_filmmaker()
					local actor = filmmaker:CreateNewActor()
					if(actor == nil) then return end
					local path = util.Path(elIcon:GetAsset())
					path:PopFront()
					local mdlC = filmmaker:CreateNewActorComponent(actor,"pfm_model",false,function(mdlC) actor:ChangeModel(path:GetString()) end)
					if(mdlC == nil) then return end
					filmmaker:CreateNewActorComponent(actor,"flex",false)
					filmmaker:CreateNewActorComponent(actor,"render",false)
					filmmaker:CreateNewActorComponent(actor,"animated")

					self:UpdateActor(actor,filmClip)
					local t = actor:GetTransform()
					t:SetOrigin(entGhost:GetPos())
					t:SetRotation(entGhost:GetRotation())
					filmmaker:ReloadGameView() -- TODO: No need to reload the entire game view

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
											t:SetOrigin(entActor:GetPos())
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
		explorer:AddCallback("PopulateIconContextMenu",function(explorer,pContext,tSelectedFiles,tExternalFiles)
			if(#tSelectedFiles ~= 1) then return end
			local path = tSelectedFiles[1]:GetRelativeAsset()
			if(asset.exists(path,asset.TYPE_MODEL) == false) then return end
			pContext:AddItem(locale.get_text("pfm_edit_retarget_rig"),function()
				gui.open_model_dialog(function(result,mdlName)
					if(result ~= gui.DIALOG_RESULT_OK) then return end
					self:OpenBoneRetargetWindow(path,mdlName)
				end)
			end)
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
	self:RegisterWindow(self.m_actorDataFrame,"web_browser",locale.get_text("pfm_web_browser"),function()
		local el = gui.create("WIPFMWebBrowser")
		el:AddCallback("OnDetached",function(el,window) window:Maximize() end)
		return el
	end)

	self:RegisterWindow(self.m_viewportFrame,"primary_viewport",locale.get_text("pfm_primary_viewport"),function()
		local el = gui.create("WIPFMViewport")
		el:AddCallback("OnReattached",function(el,window) self:RequestFocus() end)
		return el
	end)
	self:RegisterWindow(self.m_viewportFrame,"secondary_viewport",locale.get_text("pfm_secondary_viewport"),function()
		local el = gui.create("WIPFMViewport")
		el:AddCallback("OnReattached",function(el,window) self:RequestFocus() end)
		el:InitializeCustomScene()
		return el
	end)
	self:RegisterWindow(self.m_viewportFrame,"tertiary_viewport",locale.get_text("pfm_tertiary_viewport"),function()
		local el = gui.create("WIPFMViewport")
		el:AddCallback("OnReattached",function(el,window) self:RequestFocus() end)
		el:InitializeCustomScene()
		return el
	end)
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

	local tab,elVp = self:OpenWindow("primary_viewport")
	self:OpenWindow("render")
	self:OpenWindow("web_browser")

	if(util.is_valid(elVp)) then elVp:UpdateRenderSettings() end

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
	local session = project:GetSession()
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
			for _,filmClip in ipairs(trackFilm:GetFilmClips()) do
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
		local trackGroupSound = filmClip:FindTrackGroup("Sound")
		if(trackGroupSound ~= nil) then
			for _,track in ipairs(trackGroupSound:GetTracks()) do
				--if(track:GetName() == "Music") then
					local subGroup = groupSound:AddGroup(track:GetName())
					timeline:AddTimelineItem(subGroup,timeFrame)

					for _,audioClip in ipairs(track:GetAudioClips()) do
						pfmTimeline:AddAudioClip(subGroup,audioClip)
					end
				--end
			end
		end

		local groupOverlay = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_overlay"))
		local trackGroupOverlay = filmClip:FindTrackGroup("Overlay")
		if(trackGroupOverlay ~= nil) then
			for _,track in ipairs(trackGroupOverlay:GetTracks()) do
				local subGroup = groupOverlay:AddGroup(track:GetName())
				timeline:AddTimelineItem(subGroup,timeFrame)

				for _,overlayClip in ipairs(track:GetOverlayClips()) do
					pfmTimeline:AddOverlayClip(subGroup,overlayClip)
				end
			end
		end

		local activeBookmarkSet = filmClip:GetActiveBookmarkSet()
		local bookmarkSet = filmClip:GetBookmarkSet(activeBookmarkSet)
		if(bookmarkSet ~= nil) then
			for _,bookmark in ipairs(bookmarkSet:GetBookmarks()) do
				-- timeline:AddBookmark(bookmark:GetTimeRange():GetTimeAttr())
			end
		end
	end
end
function gui.WIFilmmaker:UpdateBookmarks()
	if(util.is_valid(self.m_timeline) == false) then return end
	self.m_timeline:ClearBookmarks()

	local filmClip = self:GetActiveFilmClip()
	if(filmClip == nil) then return end
	local tbms = {}
	if(self.m_timeline:GetEditor() ~= gui.PFMTimeline.EDITOR_GRAPH) then
		local bms = filmClip:GetBookmarkSet(filmClip:GetActiveBookmarkSet())
		if(bms ~= nil) then self.m_timeline:AddBookmarkSet(bms) end
	else self.m_timeline:GetActiveEditor():InitializeBookmarks() end
end
function gui.WIFilmmaker:AddBookmark()
	local filmClip = self:GetActiveFilmClip()
	if(filmClip == nil) then return end
	local t = self:GetTimeOffset() -filmClip:GetTimeFrame():GetStart()
	if(self.m_timeline:GetEditor() == gui.PFMTimeline.EDITOR_GRAPH) then
		self.m_timeline:GetGraphEditor():AddKeyframe(t)
		return
	end
	local bmSetId = filmClip:GetActiveBookmarkSet()
	local bmSet = filmClip:GetBookmarkSet(bmSetId)
	if(bmSet == nil and bmSetId == 0) then bmSet = filmClip:AddBookmarkSet() end
	if(bmSet == nil) then return end
	pfm.log("Adding bookmark at timestamp " .. t,pfm.LOG_CATEGORY_PFM)
	local bm,newBookmark = bmSet:AddBookmarkAtTimestamp(t)
	if(newBookmark == false) then return end
	self.m_timeline:AddBookmark(bm)
end
function gui.WIFilmmaker:SetTimeOffset(offset)
	pfm.ProjectManager.SetTimeOffset(self,offset)
	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end
	actorEditor:UpdateControlValues() -- TODO: Panima animations don't update right away, we need to call this *after* they have been updated
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
function gui.WIFilmmaker:OpenModelView(mdl,animName)
	self:OpenWindow("model_viewer",true)
	if(util.is_valid(self.m_mdlView) == false) then return end
	if(mdl ~= nil) then self.m_mdlView:SetModel(mdl) end

	if(animName ~= nil) then self.m_mdlView:PlayAnimation(animName)
	else self.m_mdlView:PlayIdleAnimation() end
	self.m_mdlView:Update()
end
function gui.WIFilmmaker:OpenBoneRetargetWindow(mdlSrc,mdlDst)
	local tab,el = self:OpenWindow("bone_retargeting",true)
	if(util.is_valid(el) == false) then return end
	el:SetImpostee(mdlSrc)
	el:SetImposter(mdlDst)
	--[[local mdlSrcPath = mdlSrc
	mdlSrc = game.load_model(mdlSrc)
	mdlDst = game.load_model(mdlDst)
	if(mdlSrc == nil or mdlDst == nil) then return end
	local rig = ents.RetargetRig.Rig.load(mdlSrc,mdlDst)
	if(rig == false) then
		rig = ents.RetargetRig.Rig(mdlSrc,mdlDst)

		-- local boneRemapper = ents.RetargetRig.BoneRemapper(mdlSrc:GetSkeleton(),mdlSrc:GetReferencePose(),mdlDst:GetSkeleton(),mdlDst:GetReferencePose())
		-- local translationTable = boneRemapper:AutoRemap()
		-- rig:SetTranslationTable(translationTable)
		rig:SetDstToSrcTranslationTable({})
	end
	local tab,el = self:OpenWindow("bone_retargeting",true)
	if(util.is_valid(el)) then el:SetRig(rig) end

	self:OpenModelView(mdlSrcPath)
	if(util.is_valid(self.m_mdlView)) then
		el:LinkToModelView(self.m_mdlView)
		el:InitializeModelView()
		local entSrc = self.m_mdlView:GetEntity(1)
		local entDst = self.m_mdlView:GetEntity(2)
		if(util.is_valid(entSrc) and util.is_valid(entDst)) then
			local retargetC = entDst:AddComponent("retarget_rig")
			local animSrc = entSrc:GetComponent(ents.COMPONENT_ANIMATED)
			if(retargetC ~= nil and animSrc ~= nil) then retargetC:SetRig(rig,animSrc) end

			local retargetMorphC = entDst:AddComponent("retarget_morph")
			local flexC = entSrc:GetComponent(ents.COMPONENT_FLEX)
			if(retargetMorphC ~= nil and flexC ~= nil) then retargetMorphC:SetRig(rig,flexC) end
		end
	end]]
end
gui.register("WIFilmmaker",gui.WIFilmmaker)

console.register_command("pfm_action",function(pl,...)
	local pm = tool.get_filmmaker()
	if(util.is_valid(pm) == false) then return end

	local args = {...}
	if(args[1] == "toggle_play") then
		local vp = pm:GetViewport()
		if(util.is_valid(vp)) then vp:GetPlayButton():TogglePlay() end
	elseif(args[1] == "previous_frame") then
		pm:GoToPreviousFrame()
	elseif(args[1] == "next_frame") then
		pm:GoToNextFrame()
	elseif(args[1] == "previous_bookmark") then
		pm:GoToPreviousBookmark()
	elseif(args[1] == "next_bookmark") then
		pm:GoToNextBookmark()
	elseif(args[1] == "create_bookmark") then
		pm:AddBookmark()
	elseif(args[1] == "select_editor") then
		local timeline = pm:GetTimeline()
		if(args[2] == "clip") then timeline:SetEditor(gui.PFMTimeline.EDITOR_CLIP)
		elseif(args[2] == "motion") then timeline:SetEditor(gui.PFMTimeline.EDITOR_MOTION)
		elseif(args[2] == "graph") then timeline:SetEditor(gui.PFMTimeline.EDITOR_GRAPH) end
	elseif(args[1] == "zoom") then
		local cam = pm:GetGameplayCamera()
		if(util.is_valid(cam)) then
			if(args[2] == "in") then
				cam:SetFOV(cam:GetFOV() +1.0)
			elseif(args[2] == "out") then
				cam:SetFOV(cam:GetFOV() -1.0)
			end
		end

		local vp = pm:GetGameplayViewport()
		if(vp ~= nil and vp:IsSceneCamera()) then
			local cam = vp:GetSceneCamera()
			local pfmActorC = cam:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(pfmActorC ~= nil) then
				pm:SetActorGenericProperty(pfmActorC,"ec/camera/fov",cam:GetFOV(),udm.TYPE_FLOAT)
			end
		end
	end
end)

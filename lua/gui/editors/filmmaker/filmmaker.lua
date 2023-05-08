--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_filmmaker.lua")

util.register_class("gui.WIFilmmaker",gui.WIBaseFilmmaker)

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
include("/gui/pfm/loading_screen.lua")
include("/gui/pfm/settings.lua")
include("/gui/pfm/kernels_build_message.lua")
include("/gui/pfm/progress_status_info.lua")
include("/pfm/util_particle_system.lua")
include("/pfm/auto_save.lua")
include("/pfm/util.lua")
include("/util/table_bininsert.lua")

gui.load_skin("pfm")
locale.load("pfm_user_interface.txt")
locale.load("pfm_popup_messages.txt")
locale.load("pfm_loading.txt")
locale.load("pfm_components.txt")
locale.load("physics_materials.txt")

include("windows")
include("video_recorder.lua")
include("selection_manager.lua")
include("animation_export.lua")
include("layout.lua")
include("update.lua")
include("windows.lua")

include_component("pfm_camera")
include_component("pfm_sound_source")
include_component("pfm_grid")

local function updateAutosave()
	local fm = tool.get_filmmaker()
	if(util.is_valid(fm)) then fm:UpdateAutosave() end
end
console.add_change_callback("pfm_autosave_enabled",updateAutosave)
console.add_change_callback("pfm_autosave_time_interval",updateAutosave)
console.register_variable("pfm_keep_current_layout",udm.TYPE_BOOLEAN,false,bit.bor(console.FLAG_BIT_ARCHIVE),"Keep the current layout when opening a project.")

function gui.WIFilmmaker:__init()
	gui.WIBaseFilmmaker.__init(self)
end
include("/pfm/bake/ibl.lua")
function gui.WIFilmmaker:OnInitialize()
	self:SetDeveloperModeEnabled(tool.is_developer_mode_enabled())

	gui.WIBaseFilmmaker.OnInitialize(self)
	tool.editor = self -- TODO: This doesn't really belong here (check lua/autorun/client/cl_filmmaker.lua)
	tool.filmmaker = self
	
	gui.set_context_menu_skin("pfm")
	gui.get_primary_window():SetResizable(true)

	-- Sleep mode is enabled by default, but will be disabled tempoarily if there is a continuous process going on (e.g. rendering).
	os.set_prevent_os_sleep_mode(false)

	local elConsole = gui.get_console()
	if(util.is_valid(elConsole)) then elConsole:SetExternallyOwned(true) end

	local windowTitle = ""
	local window = gui.get_primary_window()
	if(util.is_valid(window)) then windowTitle = window:GetWindowTitle() end
	self.m_originalWindowTitle = windowTitle

	self.m_editorOverlayRenderMask = game.register_render_mask("pfm_editor_overlay",false)
	self.m_worldAxesGizmo = ents.create("pfm_world_axes_gizmo")
	self.m_worldAxesGizmo:Spawn()

	self.m_pfmManager = ents.create("entity")
	self.m_pfmManager:AddComponent("pfm_manager")
	self.m_pfmManager:Spawn()

	local udmData,err = udm.load("cfg/pfm/settings.udm")
	if(udmData ~= false) then
		udmData = udmData:GetAssetData():GetData()
		self.m_settings = udmData:ClaimOwnership()
	else
		self.m_settings = udm.create_element()
	end

	local udmData,err = udm.load("cfg/pfm/keybindings.udm")
	local layers = {}
	if(udmData ~= false) then
		local loadedLayers = input.InputBindingLayer.load(udmData:GetAssetData())
		if(loadedLayers ~= false) then
			for _,layer in ipairs(loadedLayers) do layers[layer.identifier] = layer end
		end
	end

	-- Note: cfg/pfm/keybindings.udm has to be deleted or edited when these are changed
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

		bindingLayer:BindKey("x","pfm_action transform move x")
		bindingLayer:BindKey("y","pfm_action transform move y")
		bindingLayer:BindKey("z","pfm_action transform move z")

		bindingLayer:BindKey("q","pfm_action transform select")
		bindingLayer:BindKey("t","pfm_action transform translate")
		bindingLayer:BindKey("r","pfm_action transform rotate")
		bindingLayer:BindKey("s","pfm_action transform scale")

		bindingLayer:BindKey("del","pfm_delete")

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
	if(layers["pfm_transform"] == nil) then
		local bindingLayer = input.InputBindingLayer("pfm_transform")
		bindingLayer:BindKey("scrlup","pfm_transform_distance in")
		bindingLayer:BindKey("scrldn","pfm_transform_distance out")

		layers["pfm_transform"] = bindingLayer
	end
	layers["pfm"].priority = 1000
	layers["pfm_graph_editor"].priority = 2000
	layers["pfm_transform"].priority = 4000
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

	local gap = gui.create("WIBase")
	gap:SetSize(10,1)
	infoBar:AddRightElement(gap)

	local gap = gui.create("WIBase")
	gap:SetSize(10,1)
	infoBar:AddRightElement(gap,0)
	
	infoBar:Update()

	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	gameRenderer:GetEntity():AddComponent(ents.COMPONENT_RENDERER_PP_VOLUMETRIC)
	local scene = ents.create_scene(sceneCreateInfo) -- ,gameScene)
	scene:SetRenderer(gameRenderer)
	local cam = gameScene:GetActiveCamera()
	if(cam ~= nil) then scene:SetActiveCamera(cam) end
	self.m_overlayScene = scene

	local sceneDepth = ents.create_scene(sceneCreateInfo,gameScene)
	sceneDepth:SetRenderer(gameRenderer)
	if(cam ~= nil) then sceneDepth:SetActiveCamera(cam) end
	self.m_sceneDepth = sceneDepth

	gameScene:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(),self.m_editorOverlayRenderMask))
	scene:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(),self.m_editorOverlayRenderMask))
	sceneDepth:SetInclusionRenderMask(bit.bor(gameScene:GetInclusionRenderMask(),self.m_editorOverlayRenderMask))

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
		pSubMenu:ScheduleUpdate()

		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			if(self:CheckBuildKernels()) then return end
			util.remove(self.m_openDialogue)
			local pOptionKeepCurrentLayout
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				fileName = "projects/" .. fileName

				if(console.get_convar_bool("pfm_keep_current_layout")) then
					file.create_path("temp/pfm/")
					self:SaveWindowLayoutState("temp/pfm/restore_layout_state.udm",true)
				end

				self:LoadProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("projects")
			self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())

			local pOptions = self.m_openDialogue:GetOptionsPanel()
			pOptionKeepCurrentLayout = pOptions:AddToggleControl(locale.get_text("pfm_keep_current_layout"),"keep_current_layout",console.get_convar_bool("pfm_keep_current_layout"),function(el,checked)
				console.run("pfm_keep_current_layout",checked and "1" or "0")
			end)

			self.m_openDialogue:Update()
		end)
		if(self:IsDeveloperModeEnabled()) then
			pContext:AddItem(locale.get_text("reopen"),function(pItem)
				if(util.is_valid(self) == false) then return end
				if(self:CheckBuildKernels()) then return end
				self:LoadProject(self:GetProjectFileName())
			end)
		end
		local itemSave = pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			self:Save()
		end)
		local session = self:GetSession()
		if(session ~= nil and session:GetSettings():IsReadOnly() and self:IsDeveloperModeEnabled() == false) then itemSave:SetEnabled(false) end

		pContext:AddItem(locale.get_text("save_as"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:Save(nil,true,true)
		end)
		pContext:AddItem(locale.get_text("save_copy"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:Save(nil,false,true)
		end)

		local recentFiles = self.m_settings:GetArrayValues("recent_projects",udm.TYPE_STRING)
		if(#recentFiles > 0) then
			local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("recent_projects"))
			for _,f in ipairs(recentFiles) do
				pSubMenu:AddItem(f,function(pItem)
					if(util.is_valid(self) == false) then return end
					if(self:CheckBuildKernels()) then return end
					self:LoadProject(f)
				end)
				pSubMenu:ScheduleUpdate()
			end
		end

		local function initMapDialog(pFileDialog)
			pFileDialog:SetRootPath("maps")
			pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MAP,asset.FORMAT_TYPE_ALL))
			local pFileList = pFileDialog:GetFileList()
			pFileList:SetFileFinder(function(path)
				local tFiles,tDirs = file.find(path)
				local fileMap = {}
				local dirMap = {}
				for _,f in ipairs(tFiles) do
					local ext = file.get_file_extension(f)
					if(pFileList:IsValidExtension(ext)) then
						fileMap[f] = true
					end
				end
				for _,d in ipairs(tDirs) do dirMap[d] = true end

				local tFiles,tDirs = file.find_external_game_asset_files(file.get_file_path(path) .. "*.bsp")
				for _,f in ipairs(tFiles) do
					local ext = file.get_file_extension(f)
					if(pFileList:IsValidExtension(ext)) then
						fileMap[f] = true
					end
				end
				for _,d in ipairs(tDirs) do dirMap[d] = true end
				
				local fileList = {}
				for f,_ in pairs(fileMap) do table.insert(fileList,f) end
				
				local dirList = {}
				for d,_ in pairs(dirMap) do table.insert(dirList,d) end

				table.sort(fileList)
				table.sort(dirList)
				return fileList,dirList
			end)
			pFileDialog:Update()
		end

		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("import"))
		pSubMenu:AddItem(locale.get_text("map"),function(pItem)
			if(util.is_valid(self) == false) then return end
			local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
				if(fileName == nil) then return end
				self:ImportMap(el:GetFilePath(true))
			end)
			initMapDialog(pFileDialog)
		end)
		pSubMenu:AddItem(locale.get_text("pfm_sfm_project"),function(pItem)
			if(util.is_valid(self) == false) then return end
			if(self:CheckBuildKernels()) then return end
			util.remove(self.m_openDialogue)
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				self:ImportSFMProject(fileName)
			end)
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
			self.m_openDialogue:SetPath("elements/sessions")
			self.m_openDialogue:Update()
		end)
		pSubMenu:ScheduleUpdate()
		pContext:AddItem(locale.get_text("pfm_change_map"),function(pItem)
			if(util.is_valid(self) == false) then return end
			if(self:CheckBuildKernels()) then return end
			local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
				if(fileName == nil) then return end
				local map = el:GetFilePath(true)
				self:ChangeMap(map)
			end)
			initMapDialog(pFileDialog)
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
			file.create_directory("export")
			local dialoge = gui.create_file_save_dialog(function(pDialoge)
				local fname = pDialoge:GetFilePath(true)
				self:PackProject(fname)
			end)
			dialoge:SetExtensions({"zip"})
			dialoge:SetRootPath(util.get_addon_path() .. "export/")
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
			if(self:CheckBuildKernels()) then return end
			tool.close_filmmaker()
			engine.shutdown()
		end)
		pContext:ScheduleUpdate()
	end):SetName("file")
	--[[pMenuBar:AddItem(locale.get_text("edit"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("windows"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("view"),function(pContext)

	end)]]
	if(self:IsDeveloperModeEnabled()) then
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
			pSubMenu:ScheduleUpdate()

			pContext:ScheduleUpdate()
		end):SetName("render")
	end
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
				console.run("cl_language",lan)
				self:ReloadInterface()
			end)
		end
		pSubMenu:ScheduleUpdate()

		pContext:ScheduleUpdate()
	end):SetName("preferences")
	pMenuBar:AddItem(locale.get_text("tools"),function(pContext)
		if(self:IsDeveloperModeEnabled()) then
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
			pContext:ScheduleUpdate()
		end
		pContext:AddItem(locale.get_text("pfm_convert_map_to_actors"),function(pItem)
			if(util.is_valid(self) == false) then return end
			local mapName = game.get_map_name()
			local mapFile = asset.find_file(mapName,asset.TYPE_MAP)
			if(mapFile == nil) then return end
			util.remove(ents.get_all(ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_MAP)})))

			local session = self:GetSession()
			if(session ~= nil) then
				local settings = session:GetSettings()
				-- The map is now part of the project, so we want to load an empty map next time the project is loaded
				settings:SetMapName("empty")
			end

			self:ImportMap(mapFile)
		end)
		pContext:AddItem(locale.get_text("pfm_convert_static_actors_to_map"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:ConvertStaticActorsToMap()
		end)
		pContext:AddItem(locale.get_text("pfm_build_kernels"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:BuildKernels()
		end)
		pContext:AddItem(locale.get_text("pfm_start_lua_debugger_server"),function(pItem)
			if(util.is_valid(self) == false) then return end
			debug.start_debugger_server()
			pfm.create_popup_message(
				locale.get_text("pfm_lua_debugger_server_active"),
				10,gui.InfoBox.TYPE_WARNING,{
					url = "https://wiki.pragma-engine.com/books/lua-api/page/visual-studio-code"
				}
			)
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

		pContext:ScheduleUpdate()
	end):SetName("tools")
	self:AddWindowsMenuBarItem(function(pContext)
		local path = "cfg/pfm/layouts/"
		local tFiles,tDirs = file.find(path .. "*.udm")
		if(#tFiles == 0) then return end
		local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("layout"))
		for _,f in ipairs(tFiles) do
			pSubMenu:AddItem(file.remove_file_extension(f),function(pItem)
				if(util.is_valid(self) == false) then return end
				self:LoadLayout(path .. f)
			end)
		end
		pSubMenu:ScheduleUpdate()

		pContext:AddItem(locale.get_text("pfm_save_current_layout_state_as_default"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:SaveWindowLayoutState("cfg/pfm/default_layout_state.udm",true)
		end)
		pContext:AddItem(locale.get_text("pfm_restore_default_layout_state"),function(pItem)
			if(util.is_valid(self) == false) then return end
			self:RestoreWindowLayoutState("cfg/pfm/default_layout_state.udm")
		end)

		pContext:ScheduleUpdate()
	end)
	pMenuBar:AddItem(locale.get_text("help"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_getting_started"),function(pItem)
			self:OpenUrlInBrowser("https://wiki.pragma-engine.com/books/pragma-filmmaker")
		end)
		pContext:AddItem(locale.get_text("pfm_report_a_bug"),function(pItem)
			util.open_url_in_browser("https://github.com/Silverlan/pfm/issues")
		end)
		pContext:AddItem(locale.get_text("pfm_check_for_updates"),function(pItem)
			self:CheckForUpdates(true)
		end)
		pContext:AddItem(locale.get_text("pfm_community"),function(pItem)
			local engineInfo = engine.get_info()
			self:OpenUrlInBrowser(engineInfo.discordURL)
		end)
		pContext:ScheduleUpdate()
	end):SetName("help")
	pMenuBar:ScheduleUpdate()

	-- Version Info
	local engineInfo = engine.get_info()
	local versionString = "v" .. pfm.VERSION:ToString()
	local sha = pfm.get_git_sha("addons/filmmaker/git_info.txt")
	if(sha ~= nil) then
		versionString = versionString .. ", " .. sha
	end
	versionString = versionString .. " [P " .. engineInfo.prettyVersion
	local gitInfo = engine.get_git_info()
	if(gitInfo ~= nil) then
		-- Pragma SHA
		versionString = versionString .. ", " .. gitInfo.commitSha:sub(0,7)
	end
	versionString = versionString .. "]"
	local elVersion = gui.create("WIText",pMenuBar)
	elVersion:SetColor(Color.White)
	elVersion:SetText(versionString)
	elVersion:SetFont("pfm_medium")
	elVersion:SetColor(Color(200,200,200))
	elVersion:SetY(5)
	elVersion:SizeToContents()
	elVersion:SetCursor(gui.CURSOR_SHAPE_HAND)
	elVersion:SetMouseInputEnabled(true)
	elVersion:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
			util.set_clipboard_string(elVersion:GetText())
			pfm.create_popup_message(locale.get_text("pfm_version_copied_to_clipboard"),3)
			return util.EVENT_REPLY_HANDLED
		end
	end)
	elVersion:AddCallback("OnCursorEntered",function() elVersion:SetColor(Color.White) end)
	elVersion:AddCallback("OnCursorExited",function() elVersion:SetColor(Color(200,200,200)) end)

	elVersion:SetX(pMenuBar:GetWidth() -elVersion:GetWidth() -4)
	elVersion:SetY(3)
	elVersion:SetAnchor(1,0,1,0)
	log.info("PFM Version: " .. versionString)

	if(console.get_convar_bool("pfm_should_check_for_updates")) then
		console.run("pfm_should_check_for_updates","0") -- Only auto-check once per session
		time.create_simple_timer(5.0,function()
			if(self:IsValid() == false) then return end
			self:CheckForUpdates()
		end)
	end
	--

	console.run("cl_max_fps",tostring(console.get_convar_int("pfm_max_fps")))
	-- Smooth camera acceleration
	console.run("sv_acceleration_ramp_up_time",tostring(0.5))

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

	self:GetAnimationManager():AddCallback("OnAnimationChannelAdded",function()
		local actorEditor = self:GetActorEditor()
		if(util.is_valid(actorEditor)) then actorEditor:SetPropertyAnimationOverlaysDirty() end
	end)

	--[[local udmNotifications = self.m_settings:Get("notifications")
	if((udmNotifications:GetValue("initial_tutorial_message",udm.TYPE_UINT8) or 0) == 0) then
		time.create_simple_timer(10.0,function()
			if(self:IsValid() == false) then return end
			pfm.create_popup_message(
				locale.get_text("pfm_initial_tutorial_message",{"{[l:url \"" .. url .. "\"]}","{[/l]}"}),
				false
			)
			udmNotifications:SetValue("initial_tutorial_message",udm.TYPE_UINT8,1)
		end)
	end]]

	self:SetSkinCallbacksEnabled(true)
	game.call_callbacks("OnFilmmakerLaunched",self)
end
function gui.WIFilmmaker:OnProjectLoaded(fileName,project)
	self:AddRecentProject(fileName)
	self:CallCallbacks("OnProjectLoaded")
end
function gui.WIFilmmaker:AddRecentProject(fileName)
	pfm.log("Adding recent project '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)
	local maxCount = 10
	local udmRecentProjects = self.m_settings:Get("recent_projects")
	if(udmRecentProjects:IsValid() == false) then
		self.m_settings:AddArray("recent_projects",0,udm.TYPE_STRING)
		udmRecentProjects = self.m_settings:Get("recent_projects")
	end
	local recentFiles = self.m_settings:GetArrayValues("recent_projects",udm.TYPE_STRING)
	for i,f in ipairs(recentFiles) do
		if(f == fileName) then
			udmRecentProjects:RemoveValue(i -1)
			break
		end
	end
	udmRecentProjects:InsertValue(0,fileName)
	if(udmRecentProjects:GetSize() > maxCount) then udmRecentProjects:Resize(maxCount) end
end
function gui.WIFilmmaker:AddProgressStatusBar(identifier,text)
	local infoBar = self:GetInfoBar()

	local statusBar = gui.create("WIProgressStatusInfo")
	statusBar:SetName("status_info_" .. identifier)
	statusBar:SetText(text)
	statusBar:SetProgress(0.0)
	statusBar:SetHeight(infoBar:GetHeight())
	statusBar:AddCallback("OnRemove",function() if(infoBar:IsValid()) then infoBar:ScheduleUpdate() end end)
	infoBar:AddRightElement(statusBar,0)
	
	infoBar:Update()
	return statusBar
end
function gui.WIFilmmaker:BuildKernels()
	if(util.is_valid(self.m_rtBuildKernels)) then return end
	local tFiles = file.find("modules/unirender/cycles/cache/kernels/*")
	if(#tFiles > 0) then return end
	local rt = gui.create("WIRealtimeRaytracedViewport",self)
	rt:Refresh(true)
	self.m_rtBuildKernels = rt
end
function gui.WIFilmmaker:SetBuildKernels(buildKernels)
	if(buildKernels == self.m_buildingKernels) then return end
	self.m_buildingKernels = buildKernels
	if(buildKernels and util.is_valid(self.m_kernelsBuildMessage)) then return end
	util.remove(self.m_kernelsBuildMessage)
	util.remove(self.m_cbKernelProgress)
	util.remove(self.m_kernelProgressBar)
	if(buildKernels == false) then
		util.remove(self.m_rtBuildKernels)
		pfm.create_popup_message(locale.get_text("pfm_render_kernels_built_msg"),false)
	end
	if(buildKernels == false) then return end
	local frame = self.m_windowFrames["timeline"]
	if(util.is_valid(frame) == false) then return end
	local tabContainer = frame:GetTabContainer()
	if(util.is_valid(tabContainer) == false) then return end
	self.m_kernelsBuildMessage = gui.create("WIKernelsBuildMessage",tabContainer)
	self.m_kernelProgressBar = self:AddProgressStatusBar("kernel",locale.get_text("pfm_building_kernels"))
	local tStart = time.real_time()
	self.m_cbKernelProgress = game.add_callback("Think",function()
		-- There's no way to get the actual kernel progress, so we'll just
		-- move the progress bar to indicate that something is happening.
		local dt = time.real_time() -tStart
		local f = (dt %5.0) /5.0
		self.m_kernelProgressBar:SetProgress(f)
	end)

	pfm.create_popup_message(locale.get_text("pfm_building_render_kernels_msg"),16)
end
function gui.WIFilmmaker:CheckBuildKernels()
	local buildingKernels = self.m_buildingKernels or false
	if(buildingKernels == false) then return false end
	pfm.create_popup_message(locale.get_text("pfm_wait_for_kernels"),16)
	return true
end
function gui.WIFilmmaker:OpenUrlInBrowser(url)
	self:OpenWindow("web_browser")
	self:GoToWindow("web_browser")
	time.create_simple_timer(0.25,function()
		if(self:IsValid() == false) then return end
		local w = self:GetWindow("web_browser")
		w = util.is_valid(w) and w:GetBrowser() or nil
		w = util.is_valid(w) and w:GetWebBrowser() or nil
		if(util.is_valid(w) == false) then return end
		w:LoadUrl(url)
	end)
end
function gui.WIFilmmaker:ConvertStaticActorsToMap()
	local filmClip = self:GetActiveGameViewFilmClip()
	if(filmClip == nil) then return end
	local function add_entity(actor,className)
		local ent = util.WorldData.EntityData()
		ent:SetFlags(bit.bor(ent:GetFlags(),util.WorldData.EntityData.FLAG_CLIENTSIDE_ONLY_BIT))
		ent:SetClassName(className)
		ent:SetKeyValue("uuid",tostring(actor:GetUniqueId()))
		ent:SetPose(actor:GetAbsolutePose())
		return ent
	end
	local function apply_key_value(c,ent,memberName,kvName)
		kvName = kvName or memberName
		local val = c:GetMemberValue(memberName)
		if(val ~= nil) then ent:SetKeyValue(kvName,tostring(val)) end
	end
	local function apply_component_property(c,cMap,propName)
		local udmData = cMap:GetData()
		local val = c:GetMemberValue(propName)
		if(val ~= nil) then udmData:SetValue(propName,c:GetMemberType(propName),val) end
	end
	local function add_component(cActor,entMap)
		if(cActor == nil) then return end
		local componentMap = entMap:AddComponent(cActor:GetType())
		componentMap:SetFlags(bit.bor(componentMap:GetFlags(),util.WorldData.ComponentData.FLAG_CLIENTSIDE_ONLY_BIT))
		for name,udmProp in pairs(cActor:GetProperties():GetChildren()) do
			apply_component_property(cActor,componentMap,name)
		end
	end
	local worldData = util.WorldData()
	for _,actor in ipairs(filmClip:GetActorList()) do
		local pfmActorC = actor:FindComponent("pfm_actor")
		local isVisible = true
		if(pfmActorC ~= nil) then
			isVisible = pfmActorC:GetMemberValue("visible")
		end
		if(isVisible) then
			local c = actor:FindComponent("light_map_receiver")
			local mdlC = actor:FindComponent("model")
			if(c ~= nil and mdlC ~= nil) then
				local ent = add_entity(actor,"prop_dynamic")

				apply_key_value(mdlC,ent,"model")
				apply_key_value(mdlC,ent,"skin")
				add_component(c,ent)

				-- TODO: Bodygroups?

				worldData:AddEntity(ent)
			end

			local cLight = actor:FindComponent("light")
			if(cLight ~= nil and cLight:GetMemberValue("baked") == true) then
				local pointC = actor:FindComponent("light_point")
				local dirC = actor:FindComponent("light_directional")
				local spotC = actor:FindComponent("light_spot")
				local ent
				if(pointC ~= nil) then
					ent = add_entity(actor,"env_light_point")
					local radiusC = actor:FindComponent("radius")
					if(radiusC ~= nil) then apply_key_value(radiusC,ent,"radius") end
				elseif(dirC ~= nil) then
					ent = add_entity(actor,"env_light_environment")

				elseif(spotC ~= nil) then
					ent = add_entity(actor,"env_light_spot")
					local radiusC = actor:FindComponent("radius")
					if(radiusC ~= nil) then apply_key_value(radiusC,ent,"radius") end
					apply_key_value(spotC,ent,"outerConeAngle","outerCutoff")
					apply_key_value(spotC,ent,"blendFraction","blendFraction")
				end
				if(ent ~= nil) then
					local colorC = actor:FindComponent("color")
					if(colorC ~= nil) then apply_key_value(colorC,ent,"color") end

					apply_key_value(cLight,ent,"intensityType","light_intensity_type")
					apply_key_value(cLight,ent,"intensity")
					worldData:AddEntity(ent)
				end
			end

			local lmC = actor:FindComponent("light_map")
			if(lmC ~= nil) then
				local ent = add_entity(actor,"entity")
				add_component(lmC,ent)
				add_component(actor:FindComponent("light_map_data_cache"),ent)
				add_component(actor:FindComponent("pfm_cuboid_bounds"),ent)

				worldData:AddEntity(ent)
			end

			local probeC = actor:FindComponent("reflection_probe")
			if(probeC ~= nil) then
				local ent = add_entity(actor,"entity")
				add_component(probeC,ent)

				worldData:AddEntity(ent)
			end

			local skyC = actor:FindComponent("pfm_sky")
			if(skyC ~= nil) then
				local ent = add_entity(actor,"entity")
				add_component(skyC,ent)

				worldData:AddEntity(ent)
			end
		end
	end

	local dialogue = gui.create_file_save_dialog(function(pDialog,fileName)
		if(fileName == nil) then return end
		fileName = "maps/" .. fileName

		local udmData,err = udm.create()
		if(udmData ~= nil) then
			local normalizedPath = asset.get_normalized_path(fileName,asset.TYPE_MAP)
			local res,err = worldData:Save(udmData:GetAssetData(),file.get_file_name(normalizedPath))
			if(res == false) then pfm.log("Failed to save world data: " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
			else
				local fileName = normalizedPath .. "." .. asset.get_udm_format_extension(asset.TYPE_MAP,true)
				file.create_path(file.get_file_path(fileName))
				res,err = udmData:Save(fileName)
				if(res == false) then pfm.log("Failed to save map file '" .. fileName .. "': " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
				else pfm.log("Successfully saved map file as '" .. fileName .. "'!",pfm.LOG_CATEGORY_PFM) end
			end
		end
	end)
	dialogue:SetRootPath("maps")
	dialogue:SetExtensions(asset.get_supported_extensions(asset.TYPE_MAP))
	dialogue:Update()
end
function gui.WIFilmmaker:GetManagerEntity() return self.m_pfmManager end
function gui.WIFilmmaker:GetWorldAxesGizmo() return self.m_worldAxesGizmo end
function gui.WIFilmmaker:OnSkinApplied()
	self:GetMenuBar():Update()
end
function gui.WIFilmmaker:ImportSFMProject(projectFilePath)
	local res = pfm.ProjectManager.ImportSFMProject(self,projectFilePath)
	if(res == false) then
		pfm.log("Failed to import SFM project '" .. projectFilePath .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local session = self:GetSession()
	if(session ~= nil) then
		local settings = session:GetSettings()
		local mapName = asset.get_normalized_path(settings:GetMapName(),asset.TYPE_MAP)
		if(mapName ~= asset.get_normalized_path(game.get_map_name(),asset.TYPE_MAP)) then
			time.create_simple_timer(0.0,function()
				if(self:IsValid()) then self:ChangeMap(mapName) end
			end)
		end
	end
	return res
end
function gui.WIFilmmaker:ChangeMap(map,projectFileName)
	pfm.log("Changing map to '" .. map .. "'...",pfm.LOG_CATEGORY_PFM)
	time.create_simple_timer(0.0,function()
		local elBase = gui.get_base_element()
		local mapName = asset.get_normalized_path(map,asset.TYPE_MAP)

		local el = udm.create_element()
		local writeNewMapName = (projectFileName == nil)
		local restoreProjectName = projectFileName
		projectFileName = projectFileName or self:GetProjectFileName()
		if(projectFileName ~= nil) then el:SetValue("originalProjectFileName",udm.TYPE_STRING,projectFileName) end

		file.create_path("temp/pfm/restore")
		if(restoreProjectName == nil) then
			restoreProjectName = "temp/pfm/restore/project"
			if(self:Save(restoreProjectName,false,nil,false) == false) then
				pfm.log("Failed to save restore project. Map will not be changed!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
				return
			end
		end
		el:SetValue("restoreProjectFileName",udm.TYPE_STRING,restoreProjectName)
		if(writeNewMapName) then el:SetValue("newProjectMapName",udm.TYPE_STRING,map) end

		local udmData,err = udm.create("PFMRST",1)
		local assetData = udmData:GetAssetData()
		assetData:GetData():Merge(el:Get())

		local f = file.open("temp/pfm/restore/restore.udm",file.OPEN_MODE_WRITE)
		if(f ~= nil) then
			local res,msg = udmData:SaveAscii(f)
			f:Close()

			if(res == false) then
				pfm.log("Failed to write restore file. Map will not be changed!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
				return
			end
		else
			pfm.log("Failed to write restore file. Map will not be changed!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
			return
		end

		tool.close_filmmaker()
		pfm.show_loading_screen(true,mapName)
		console.run("pfm_restore","1")
		console.run("map",mapName)
	end)
end
function gui.WIFilmmaker:RestoreProject()
	local udmData,err = udm.load("temp/pfm/restore/restore.udm")
	local originalProjectFileName
	if(udmData == false) then
		pfm.log("Failed to restore project: Unable to open restore file!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end
	udmData = udmData:GetAssetData():GetData()
	local restoreData = udmData:ClaimOwnership()
	originalProjectFileName = restoreData:GetValue("originalProjectFileName",udm.TYPE_STRING)
	local restoreProjectFileName = restoreData:GetValue("restoreProjectFileName",udm.TYPE_STRING)
	if(restoreProjectFileName == nil) then
		pfm.log("Failed to restore project: Invalid restore data!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local fileName = restoreProjectFileName
	if(self:LoadProject(fileName,true) == false) then
		pfm.log("Failed to restore project: Unable to load restore project!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		self:CloseProject()
		self:CreateEmptyProject()
		return false
	end
	local newProjectMapName = restoreData:GetValue("newProjectMapName")
	if(newProjectMapName ~= nil) then
		local session = self:GetSession()
		if(session ~= nil) then
			local settings = session:GetSettings()
			settings:SetMapName(asset.get_normalized_path(newProjectMapName,asset.TYPE_MAP))
		end
	end
	self:SetProjectFileName(originalProjectFileName)
	file.delete_directory("temp/pfm/restore")
end
function gui.WIFilmmaker:ImportMap(map)
	map = file.remove_file_extension(map,asset.get_supported_extensions(asset.TYPE_MAP,asset.FORMAT_TYPE_ALL))
	local origMapName = map
	map = asset.find_file(origMapName,asset.TYPE_MAP)
	if(map == nil) then
		if(asset.import("maps/" .. origMapName,asset.TYPE_MAP) == false) then return end
		map = asset.find_file(origMapName,asset.TYPE_MAP)
		if(map == nil) then return end
	end
	local actorEditor = self:GetActorEditor()
	local data,msg = udm.load("maps/" .. map)
	if(data == false) then
		pfm.log("Failed to import map '" .. map .. "': " .. msg,pfm.LOG_CATEGORY_PFM)
		return
	end

	local indexCounters = {}

	local group = actorEditor:FindCollection(file.get_file_name(asset.get_normalized_path(map,asset.TYPE_MAP)),true)
	local entityData = data:GetAssetData():GetData():Get("entities")
	for _,entData in ipairs(entityData:GetArrayValues()) do
		local keyValues = entData:Get("keyValues")
		local className = entData:GetValue("className",udm.TYPE_STRING)
		local pose = entData:GetValue("pose",udm.TYPE_SCALED_TRANSFORM) or math.ScaledTransform()
		local model = keyValues:GetValue("model",udm.TYPE_STRING)
		local uuid = keyValues:GetValue("uuid",udm.TYPE_STRING)
		local skin = keyValues:GetValue("skin",udm.TYPE_STRING) or 0
		local angles = keyValues:GetValue("angles",udm.TYPE_STRING)
		local scale = keyValues:GetValue("scale",udm.TYPE_STRING)
		if(angles ~= nil) then
			angles = EulerAngles(angles)
			pose:SetRotation(angles:ToQuaternion())
		end
		if(scale ~= nil) then
			scale = Vector(scale)
			pose:SetScale(scale)
		end
		local index
		if(indexCounters[className] == nil) then
			indexCounters[className] = 1
			index = 0
		else
			index = indexCounters[className]
			indexCounters[className] = index +1
		end
		local name = keyValues:GetValue("targetname",udm.TYPE_STRING) or (className .. index)
		if(className == "prop_physics" or className == "prop_dynamic" or className == "world") then
			if(model ~= nil) then
				name = file.get_file_name(model)
				local actor = actorEditor:CreateNewActor(name,pose,uuid,actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_SCENEBUILD,true,group))
				actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP,{
					["actor"] = actor,
					["modelName"] = model
				})
				actorEditor:UpdateActorComponents(actor)
			end
		elseif(className == "skybox") then
			local actor = actorEditor:CreateNewActor(name,pose,uuid,actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_ENVIRONMENT,true,group))

			local mdlC = actorEditor:CreateNewActorComponent(actor,"pfm_model",false,function(mdlC) actor:ChangeModel(model) end)
			actorEditor:CreateNewActorComponent(actor,"skybox",false)

			actorEditor:UpdateActorComponents(actor)
		elseif(className == "env_light_environment") then

		elseif(className == "env_light_point") then
			local actor = actorEditor:CreateNewActor(name,pose,uuid,actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_LIGHTS,true,group))

			local radius = keyValues:GetValue("radius",udm.TYPE_FLOAT) or 1000.0
			local intensity = keyValues:GetValue("light_intensity",udm.TYPE_FLOAT) or 1000.0
			local intensityType = keyValues:GetValue("light_intensity_type",udm.TYPE_UINT32) or ents.LightComponent.INTENSITY_TYPE_CANDELA
			local color = Color(keyValues:GetValue("lightcolor",udm.TYPE_STRING) or "")

			actorEditor:CreateNewActorComponent(actor,"pfm_light_point",false)
			local lightC = actorEditor:CreateNewActorComponent(actor,"light",false)
			actorEditor:CreateNewActorComponent(actor,"light_point",false)
			local radiusC = actorEditor:CreateNewActorComponent(actor,"radius",false)
			local colorC = actorEditor:CreateNewActorComponent(actor,"color",false)
			lightC:SetMemberValue("intensity",udm.TYPE_FLOAT,intensity)
			lightC:SetMemberValue("intensityType",udm.TYPE_UINT32,intensityType)
			lightC:SetMemberValue("castShadows",udm.TYPE_BOOLEAN,false)
			lightC:SetMemberValue("baked",udm.TYPE_BOOLEAN,true)
			radiusC:SetMemberValue("radius",udm.TYPE_FLOAT,radius)
			colorC:SetMemberValue("color",udm.TYPE_VECTOR3,color:ToVector())
			actorEditor:UpdateActorComponents(actor)
		elseif(className == "env_fog_controller") then
			local actor = actorEditor:CreateNewActor(name,pose,uuid,actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_ENVIRONMENT,true,group))

			local fogColor = keyValues:GetValue("fogcolor",udm.TYPE_VECTOR3)
			fogColor = (fogColor ~= nil) and (fogColor /255.0) or Vector(1,1,1)
			local fogStart = keyValues:GetValue("fogstart",udm.TYPE_FLOAT) or 500.0
			local fogEnd = keyValues:GetValue("fogend",udm.TYPE_FLOAT) or 2000.0
			local maxDensity = keyValues:GetValue("fogmaxdensity",udm.TYPE_FLOAT) or 1.0
			local fogType = keyValues:GetValue("fogtype",udm.TYPE_UINT32) or game.WorldEnvironment.FOG_TYPE_LINEAR

			local colorC = actorEditor:CreateNewActorComponent(actor,"color",false)
			colorC:SetMemberValue("color",udm.TYPE_VECTOR3,fogColor)

			local fogC = actorEditor:CreateNewActorComponent(actor,"fog_controller",false)
			fogC:SetMemberValue("start",udm.TYPE_FLOAT,fogStart)
			fogC:SetMemberValue("end",udm.TYPE_FLOAT,fogEnd)
			fogC:SetMemberValue("density",udm.TYPE_FLOAT,maxDensity)
			fogC:SetMemberValue("type",udm.TYPE_UINT32,fogType)
			actorEditor:UpdateActorComponents(actor)
		end
	end
end
function gui.WIFilmmaker:RestoreWorkCamera()
	local session = self:GetSession()
	local vp = self:GetViewport()
	if(session == nil or util.is_valid(vp) == false) then return end
	local settings = session:GetSettings()
	local workCameraSettings = settings:GetWorkCamera()
	vp:SetWorkCameraPose(workCameraSettings:GetPose())
	local workCamera = vp:GetWorkCamera()
	if(util.is_valid(workCamera)) then workCamera:SetFOV(workCameraSettings:GetFov()) end

	local camView = settings:GetCameraView()
	vp:SetCameraView(camView)
end
function gui.WIFilmmaker:UpdateWorkCamera(cameraView)
	local session = self:GetSession()
	local vp = self:GetViewport()
	if(session == nil or util.is_valid(vp) == false) then return end
	local settings = session:GetSettings()
	if(vp:IsWorkCamera()) then
		local cam = vp:GetWorkCamera()
		if(util.is_valid(cam) == false) then return end
		local workCamera = settings:GetWorkCamera()
		workCamera:SetPose(math.Transform(cam:GetEntity():GetPose()))
		workCamera:SetFov(cam:GetFOV())
	end
	cameraView = cameraView or vp:GetCameraView()
	if(cameraView ~= nil) then settings:SetCameraView(cameraView) end
end
function gui.WIFilmmaker:SaveSettings()
	local udmData,err = udm.create("PFMST",1)
	local assetData = udmData:GetAssetData()
	assetData:GetData():Merge(self.m_settings:Get())
	file.create_path("cfg/pfm")
	local f = file.open("cfg/pfm/settings.udm",file.OPEN_MODE_WRITE)
	if(f ~= nil) then
		udmData:SaveAscii(f)
		f:Close()
	end
end

function gui.WIFilmmaker:PreRenderScenes(drawSceneInfo)
	if(self.m_overlaySceneEnabled ~= true or self.m_nonOverlayRtTexture == nil) then return end
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if(util.is_valid(rt)) then
		local el = rt:GetToneMappedImageElement()
		if(util.is_valid(el)) then
			local tex = gameRenderer:GetSceneTexture()
			local texRt = self.m_nonOverlayRtTexture
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
	drawSceneInfo.renderFlags = bit.bor(bit.band(drawSceneInfo.renderFlags,bit.bnot(game.RENDER_FLAG_BIT_VIEW)),game.RENDER_FLAG_HDR_BIT) -- Don't render view models

	-- Does not work for some reason?
	-- drawSceneInfo.flags = bit.bor(drawSceneInfo.flags,game.DrawSceneInfo.FLAG_DISABLE_PREPASS_BIT)
	-- drawSceneInfo:AddSubPass(drawSceneInfoDepth)

	game.queue_scene_for_rendering(drawSceneInfo)
	--
end
function gui.WIFilmmaker:GetOverlayScene() return self.m_overlayScene end
function gui.WIFilmmaker:SetOverlaySceneEnabled(enabled)
	if(self.m_overlaySceneEnabled == enabled) then return end
	util.remove(self.m_overlaySceneCallback)
	console.run("render_clear_scene " .. (enabled and "0" or "1"))
	self.m_overlaySceneEnabled = enabled
	game.set_default_game_render_enabled(enabled == false)

	local vp = self:GetViewport()
	local rtVp = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	local te = util.is_valid(rtVp) and rtVp:GetToneMappedImageElement() or nil
	if(te ~= nil) then
		self.m_overlaySceneCallback = te:AddCallback("OnTextureApplied",function(te,tex)
			if(enabled) then
				self.m_nonOverlayRtTexture = te.m_elTex:GetTexture()
				te.m_elTex:SetTexture(game.get_scene():GetRenderer():GetHDRPresentationTexture())
			elseif(self.m_nonOverlayRtTexture ~= nil) then
				te.m_elTex:SetTexture(self.m_nonOverlayRtTexture)
				self.m_nonOverlayRtTexture = nil
			end
		end)
	end

	self:TagRenderSceneAsDirty()
end
function gui.WIFilmmaker:Save(fileName,setAsProjectName,saveAs,withProjectsPrefix)
	local project = self:GetProject()
	if(project == nil) then return end
	if(self:IsDeveloperModeEnabled() == false) then
		local session = self:GetSession()
		if(session ~= nil and session:GetSettings():IsReadOnly()) then
			pfm.log("Failed to save project: Project is read-only!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
			local msgReadOnly = locale.get_text("pfm_project_read_only")
			pfm.create_popup_message(locale.get_text("pfm_save_failed_reason",{msgReadOnly}),false,gui.InfoBox.TYPE_ERROR)
			return
		end
	end
	if(setAsProjectName == nil) then setAsProjectName = true end
	local function saveProject(fileName)
		self:UpdateWorkCamera()
		self:UpdateWindowLayoutState()
		file.create_directory("projects")
		local ext = file.get_file_extension(fileName)
		local saveAsAscii = (ext == pfm.Project.FORMAT_EXTENSION_ASCII)
		fileName = file.remove_file_extension(fileName,pfm.Project.get_format_extensions())
		fileName = pfm.Project.get_full_project_file_name(fileName,withProjectsPrefix,saveAsAscii)
		local res = self:SaveProject(fileName,setAsProjectName and fileName or nil)
		if(res) then
			pfm.create_popup_message(locale.get_text("pfm_save_success",{fileName}),1)
			if(setAsProjectName) then self:AddRecentProject(fileName) end
		else
			pfm.create_popup_message(locale.get_text("pfm_save_failed",{fileName}),false,gui.InfoBox.TYPE_ERROR)
		end
	end
	if(fileName == nil and saveAs ~= true) then
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
function gui.WIFilmmaker:CreateInitialProject()
	self:CreateSimpleProject(true)
	self:RestoreWindowLayoutState("cfg/pfm/default_layout_state.udm")
end
function gui.WIFilmmaker:CreateSimpleProject()
	self:CreateEmptyProject()

	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end

	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY)
	local cam = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA)
	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE)
	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER)

	local filmClip = self:GetActiveGameViewFilmClip()
	if(filmClip ~= nil) then filmClip:SetCamera(cam) end
end
function gui.WIFilmmaker:CreateEmptyProject()
	self:CreateNewProject()

	local session = self:GetSession()
	if(session ~= nil) then
		local settings = session:GetSettings()
		local mapName = asset.get_normalized_path(game.get_map_name(),asset.TYPE_MAP)
		pfm.log("Assigning map name '" .. mapName .. "' to new project.",pfm.LOG_CATEGORY_PFM)
		settings:SetMapName(mapName)
	end

	local filmClip = self:GetActiveFilmClip()
	if(filmClip == nil) then return end

	self:SelectFilmClip(filmClip)
end
function gui.WIFilmmaker:PackProject(fileName)
	local projName = file.remove_file_extension(file.get_file_name(self:GetProjectFileName() or "new_project"),pfm.Project.get_format_extensions())
	local project = self:GetProject()
	local session = self:GetSession()

	local assetFiles = project:CollectAssetFiles()
	local projectFileName = self:GetProjectFileName()
	if(projectFileName ~= nil) then assetFiles[projectFileName] = projectFileName end
	
	local finalAssetFiles = {}
	for fZip,f in pairs(assetFiles) do
		local rootPath = "addons/pfmp_" .. projName .. "/"
		finalAssetFiles[rootPath .. fZip] = f
	end

	pfm.save_asset_files_as_archive(finalAssetFiles,fileName)
end
function gui.WIFilmmaker:AddActor(filmClip,group,dontRefreshAnimation)
	group = group or filmClip:GetScene()
	local actor = group:AddActor()
	if(dontUpdateActor ~= true) then self:UpdateActor(actor,filmClip,nil,dontRefreshAnimation) end
	return actor
end
function gui.WIFilmmaker:UpdateActor(actor,filmClip,reload,dontRefreshAnimation)
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
	if(dontRefreshAnimation ~= true) then self:SetTimeOffset(self:GetTimeOffset()) end
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
	self:CallCallbacks("OnProjectClosed")
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
		elseif(key == input.KEY_Z) then
			if(state == input.STATE_PRESS) then pfm.undo() end
			return util.EVENT_REPLY_HANDLED
		elseif(key == input.KEY_Y) then
			if(state == input.STATE_PRESS) then pfm.redo() end
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
function gui.WIFilmmaker:OnProjectFileNameChanged(projectFileName)
	local window = gui.get_primary_window()
	if(util.is_valid(window)) then
		local title = self.m_originalWindowTitle
		if(projectFileName ~= nil) then
			title = title .. " - " .. projectFileName
		else
			title = title .. " - " .. locale.get_text("untitled")
		end
		window:SetWindowTitle(title)
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
	util.remove(self.m_cbPreRenderScenes)
	util.remove(self.m_overlaySceneCallback)
	if(util.is_valid(self.m_overlayScene)) then self.m_overlayScene:GetEntity():Remove() end
	if(util.is_valid(self.m_sceneDepth)) then self.m_sceneDepth:GetEntity():Remove() end
	util.remove(self.m_cbDropped)
	util.remove(self.m_openDialogue)
	util.remove(self.m_previewWindow)
	util.remove(self.m_renderResultWindow)
	util.remove(self.m_updateProgressBar)
	self.m_selectionManager:Remove()

	local window = gui.get_primary_window()
	if(util.is_valid(window)) then window:SetWindowTitle(self.m_originalWindowTitle) end

	if(self.m_animRecorder ~= nil) then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end

	-- util.remove(self.m_reflectionProbe)
	-- util.remove(self.m_entLight)

	self:SaveSettings()

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

	if(self.m_runUpdaterOnShutdown) then
		util.run_updater()
	end

	gui.set_context_menu_skin()
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

	gui.WIBaseFilmmaker.SetGameViewOffset(self,offset)

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

	local entScene = gui.WIBaseFilmmaker.InitializeProject(self,project)

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

	local layoutStateFileName = "temp/pfm/restore_layout_state.udm"
	local layout
	local udmLayout
	if(console.get_convar_bool("pfm_keep_current_layout") and file.exists(layoutStateFileName)) then
		-- Restore previous layout state
		local udmData = self:LoadWindowLayoutState(layoutStateFileName)
		file.delete(layoutStateFileName)

		if(udmData ~= nil) then
			udmLayout = udmData:Get("layout_state")
			layout = udmLayout:GetValue("layout",udm.TYPE_STRING)
		end
	end

	local settings = session:GetSettings()
	self:InitializeProjectUI(layout or settings:GetLayout())
	self:SetTimeOffset(0)
	self:RestoreWorkCamera()
	self:RestoreWindowLayoutState(udmLayout or settings:GetLayoutState():GetUdmData(),udmLayout == nil)
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
function gui.WIFilmmaker:ChangeFilmClipDuration(filmClip,dur)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if(util.is_valid(el) == false) then return end
	filmClip:GetTimeFrame():SetDuration(dur)
	local track = filmClip:GetParent()
	track:UpdateFilmClipTimeFrames()
	el:UpdateFilmClipData()
end
function gui.WIFilmmaker:ChangeFilmClipOffset(filmClip,offset)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if(util.is_valid(el) == false) then return end
	filmClip:GetTimeFrame():SetOffset(offset)
	el:UpdateFilmClipData()
end
function gui.WIFilmmaker:ChangeFilmClipName(filmClip,name)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if(util.is_valid(el) == false) then return end
	filmClip:SetName(name)
	el:UpdateFilmClipData()
end
function gui.WIFilmmaker:AddFilmClip()
	local session = self:GetSession()
	local trackFilm = (session ~= nil) and session:GetFilmTrack() or nil
	if(trackFilm == nil) then return end
	local lastFilmClip
	local sortedClips = trackFilm:GetSortedFilmClips()
	lastFilmClip = sortedClips[#sortedClips]
	self:InsertFilmClipAfter(lastFilmClip,name)
end
function gui.WIFilmmaker:InsertFilmClipAfter(filmClip,name)
	name = name or "shot"
	local track = filmClip:GetParent()
	local newFc = track:InsertFilmClipAfter(filmClip)
	newFc:SetName(name)

	local channelTrackGroup = newFc:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")

	local elFc = self:AddFilmClipElement(newFc)
	self.m_timeline:GetTimeline():AddTimelineItem(elFc,newFc:GetTimeFrame())
end
function gui.WIFilmmaker:InsertFilmClipBefore(filmClip,name)
	name = name or "shot"
	local track = filmClip:GetParent()
	local newFc = track:InsertFilmClipBefore(filmClip)
	newFc:SetName(name)

	local channelTrackGroup = newFc:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")
	
	local elFc = self:AddFilmClipElement(newFc)
	self.m_timeline:GetTimeline():AddTimelineItem(elFc,newFc:GetTimeFrame())
end
function gui.WIFilmmaker:MoveFilmClipToLeft(filmClip)
	local track = filmClip:GetParent()
	track:MoveFilmClipToLeft(filmClip)
end
function gui.WIFilmmaker:MoveFilmClipToRight(filmClip)
	local track = filmClip:GetParent()
	track:MoveFilmClipToRight(filmClip)
end
function gui.WIFilmmaker:RemoveFilmClip(filmClip)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if(util.is_valid(el) == false) then return end
	local track = filmClip:GetParent()
	track:RemoveFilmClip(filmClip)
	-- TODO: This probably requires some cleanup
	el:Remove()
	track:UpdateFilmClipTimeFrames()
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
			pContext:AddItem(locale.get_text("pfm_change_duration"),function()
				local p = pfm.open_single_value_edit_window(locale.get_text("duration"),function(ok,val)
					if(self:IsValid() == false) then return end
					if(ok) then
						local dur = tonumber(val)
						if(dur ~= nil) then
							self:ChangeFilmClipDuration(filmClip,math.max(dur,0.1))
						end
					end
				end,tostring(filmClip:GetTimeFrame():GetDuration()))
			end)
			pContext:AddItem(locale.get_text("pfm_change_offset"),function()
				local p = pfm.open_single_value_edit_window(locale.get_text("offset"),function(ok,val)
					if(self:IsValid() == false) then return end
					if(ok) then
						local offset = tonumber(val)
						if(offset ~= nil) then
							self:ChangeFilmClipOffset(filmClip,offset)
						end
					end
				end,tostring(filmClip:GetTimeFrame():GetOffset()))
			end)
			pContext:AddItem(locale.get_text("pfm_change_name"),function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"),function(ok,val)
					if(self:IsValid() == false) then return end
					if(ok) then
						self:ChangeFilmClipName(filmClip,val)
					end
				end,tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_add_clip_after"),function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"),function(ok,val)
					if(self:IsValid() == false) then return end
					if(ok) then
						self:InsertFilmClipAfter(filmClip,val)
					end
				end,tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_add_clip_before"),function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"),function(ok,val)
					if(self:IsValid() == false) then return end
					if(ok) then
						self:InsertFilmClipBefore(filmClip,val)
					end
				end,tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_move_clip_to_left"),function()
				self:MoveFilmClipToLeft(filmClip)
			end)
			pContext:AddItem(locale.get_text("pfm_move_clip_to_right"),function()
				self:MoveFilmClipToRight(filmClip)
			end)
			pContext:AddItem(locale.get_text("remove"),function()
				self:RemoveFilmClip(filmClip)
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

function gui.WIFilmmaker:UpdateActorAnimatedPropertyValue(actorData,targetPath,value) -- For internal use only
	local actorEditor = self:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return true end
	return actorEditor:UpdateAnimationChannelValue(actorData,targetPath,value)
end
function gui.WIFilmmaker:SetActorGenericProperty(actor,targetPath,value,udmType)
	local actorData = actor:GetActorData()
	if(actorData == nil) then return end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if(util.is_valid(rt)) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local function applyControllerTarget() -- TODO: Obsolete?
		local memberInfo = pfm.get_member_info(targetPath,actor:GetEntity())
		if(memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_CONTROLLER_BIT) and memberInfo.metaData ~= nil) then
			local meta = memberInfo.metaData
			local controllerTarget = meta:GetValue("controllerTarget")
			local applyResult = false
			if(controllerTarget ~= nil) then
				local memberInfoTarget = pfm.get_member_info(controllerTarget,actor:GetEntity())
				if(memberInfoTarget ~= nil) then
					local targetValue = actor:GetEntity():GetMemberValue(controllerTarget)
					if(targetValue ~= nil) then
						applyResult = self:SetActorGenericProperty(actor,controllerTarget,targetValue,memberInfoTarget.type)
					end
				end
			end
			return true,applyResult
		end
		return false
	end

	if(self:UpdateActorAnimatedPropertyValue(actorData,targetPath,value) == false) then return end

	self:GetAnimationManager():SetAnimationDirty(actorData)
	local res
	if(udmType ~= udm.TYPE_ELEMENT) then res = actor:GetEntity():SetMemberValue(targetPath,value)
	else res = true end
	local hasControlTarget,ctResult = applyControllerTarget()
	if(udmType ~= nil) then
		local componentName,memberName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
		if(componentName ~= nil) then
			local c = actorData:AddComponentType(componentName)
			c:SetMemberValue(memberName:GetString(),udmType,value)
		end
	end
	self:GetActorEditor():UpdateActorProperty(actorData,targetPath)
	self:TagRenderSceneAsDirty()
	if(hasControlTarget) then return ctResult end
	return res
end
function gui.WIFilmmaker:SetActorTransformProperty(actor,propType,value,applyUdmValue)
	local actorData = actor:GetActorData()
	if(actorData == nil) then return end

	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if(util.is_valid(rt)) then
		rt:MarkActorAsDirty(actor:GetEntity())
	end

	local actorEditor = self:GetActorEditor()
	local targetPath = "ec/pfm_actor/" .. propType

	if(self:UpdateActorAnimatedPropertyValue(actorData,targetPath,value) == false) then return end

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
function gui.WIFilmmaker:SetActorBoneTransformProperty(actor,propType,value,udmType) -- TODO: Obsolete?
	self:SetActorGenericProperty(actor,"ec/animated/bone/" .. propType,value,udmType)
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
function gui.WIFilmmaker:InitializeProjectUI(layoutName)
	self:ClearProjectUI()
	if(util.is_valid(self.m_menuBar) == false or util.is_valid(self.m_infoBar) == false) then return end
	self:InitializeGenericLayout()

	self:InitializeLayout(layoutName)

	for _,windowData in ipairs(pfm.get_registered_windows()) do
		self:RegisterWindow(windowData.category,windowData.name,windowData.localizedName,function()
			return windowData.factory(self)
		end)
	end
	
	self:OpenWindow("actor_editor")
	-- self:OpenWindow("element_viewer")
	-- self:OpenWindow("tutorial_catalog")

	local tab,elVp = self:OpenWindow("primary_viewport")
	self:OpenWindow("render")
	self:OpenWindow("web_browser")
	self:OpenWindow("model_catalog")
	self:OpenWindow("tutorial_catalog")

	if(util.is_valid(elVp)) then elVp:UpdateRenderSettings() end

	self:OpenWindow("timeline")

	-- Populate UI with project data
	local pfmTimeline = self.m_timeline
	local project = self:GetProject()
	local root = project:GetUDMRootNode()
	local elViewer = self:GetElementViewer()
	if(util.is_valid(elViewer)) then elViewer:Setup(root) end

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
		self.m_trackGroupPicture = groupPicture

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
		self.m_trackGroupSound = groupSound

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
		self.m_trackGroupOverlay = groupOverlay

		local activeBookmarkSet = filmClip:GetActiveBookmarkSet()
		local bookmarkSet = filmClip:GetBookmarkSet(activeBookmarkSet)
		if(bookmarkSet ~= nil) then
			for _,bookmark in ipairs(bookmarkSet:GetBookmarks()) do
				-- timeline:AddBookmark(bookmark:GetTimeRange():GetTimeAttr())
			end
		end
	end

	if(util.is_valid(self.m_trackGroupPicture)) then
		self.m_trackGroupPicture:Expand()
	end
	if(util.is_valid(filmStrip)) then
		local filmClips = filmStrip:GetFilmClips()
		local filmClip = filmClips[1]
		if(util.is_valid(filmClip)) then filmClip:SetSelected(true) end
	end

	local vp = self:GetViewport()
	local camScene = util.is_valid(vp) and vp:GetSceneCamera() or nil
	if(util.is_valid(camScene)) then
		vp:SetWorkCameraPose(camScene:GetEntity():GetPose())
	end
end
function gui.WIFilmmaker:OpenEscapeMenu()
	self:OpenWindow("settings")
	self:GoToWindow("settings")
end
function gui.WIFilmmaker:GetPictureTrackGroup() return self.m_trackGroupPicture end
function gui.WIFilmmaker:GetSoundTrackGroup() return self.m_trackGroupSound end
function gui.WIFilmmaker:GetOverlayTrackGroup() return self.m_trackGroupOverlay end
function gui.WIFilmmaker:OnGameViewReloaded()
	local function apply_viewport(vp)
		if(util.is_valid(vp) == false) then return end
		vp:RefreshCamera()
	end
	apply_viewport(self:GetViewport())
	apply_viewport(self:GetSecondaryViewport())
	apply_viewport(self:GetTertiaryViewport())
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
	gui.WIBaseFilmmaker.SetTimeOffset(self,offset)
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
function gui.WIFilmmaker:SelectActor(actor,deselectCurrent,property)
	if(util.is_valid(self:GetActorEditor()) == false) then return end
	self:GetActorEditor():SelectActor(actor,deselectCurrent,property)

	self:GoToWindow("actor_editor")
end
function gui.WIFilmmaker:DeselectAllActors()
	if(util.is_valid(self:GetActorEditor()) == false) then return end
	self:GetActorEditor():DeselectAllActors()
end
function gui.WIFilmmaker:DeselectActor(actor)
	if(util.is_valid(self:GetActorEditor()) == false) then return end
	self:GetActorEditor():DeselectActor(actor)

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
function gui.WIFilmmaker:GetModelViewer() return self:GetWindow("model_viewer") end
function gui.WIFilmmaker:OpenModelView(mdl,animName)
	self:OpenWindow("model_viewer",true)
	if(util.is_valid(self.m_mdlView) == false) then return end
	if(mdl ~= nil) then self.m_mdlView:SetModel(mdl) end

	if(animName ~= nil) then self.m_mdlView:PlayAnimation(animName)
	else self.m_mdlView:PlayIdleAnimation() end
	self.m_mdlView:Update()
end
function gui.WIFilmmaker:SetQuickAxisTransformMode(axes)
	local vp = self:GetViewport()
	if(util.is_valid(vp) == false) then return end
	if(self.m_quickAxisTransformModeEnabled) then
		local entTransform = vp:GetTransformEntity()
		self.m_quickAxisTransformModeEnabled = nil

		for _,v in ipairs(self.m_quickAxisTransformAxes) do
			if(v:IsValid()) then v:StopTransform() end
		end
		self.m_quickAxisTransformAxes = nil

		vp:SetManipulatorMode(self.m_preAxisManipulatorMode or gui.PFMViewport.MANIPULATOR_MODE_SELECT)
		self.m_preAxisManipulatorMode = nil

		if(util.is_valid(entTransform)) then vp:OnActorTransformChanged(entTransform) end
		return
	end
	self.m_preAxisManipulatorMode = vp:GetManipulatorMode()
	local useRotationGizmo = (vp:GetManipulatorMode() == gui.PFMViewport.MANIPULATOR_MODE_ROTATE)
	if(useRotationGizmo == false) then vp:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_MOVE) end
	local c = vp:GetTransformWidgetComponent()
	if(util.is_valid(c)) then
		self.m_quickAxisTransformModeEnabled = true
		self.m_quickAxisTransformAxes = {}
		for _,axis in ipairs(axes) do
			local v = c:GetTransformUtility(useRotationGizmo and ents.UtilTransformArrowComponent.TYPE_ROTATION or ents.UtilTransformArrowComponent.TYPE_TRANSLATION,axis,useRotationGizmo and "rotation" or "translation")
			if(v ~= nil) then
				v = v:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
				v:StartTransform()
				table.insert(self.m_quickAxisTransformAxes,v)
			end
		end
	end
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
	elseif(args[1] == "transform") then
		if(args[2] == "move") then
			local shift = input.is_shift_key_down()
			if(args[3] == "x") then
				if(shift) then pm:SetQuickAxisTransformMode({math.AXIS_Y,math.AXIS_Z})
				else pm:SetQuickAxisTransformMode({math.AXIS_X}) end
			elseif(args[3] == "y") then
				if(shift) then pm:SetQuickAxisTransformMode({math.AXIS_X,math.AXIS_Z})
				else pm:SetQuickAxisTransformMode({math.AXIS_Y}) end
			elseif(args[3] == "z") then
				if(shift) then pm:SetQuickAxisTransformMode({math.AXIS_X,math.AXIS_Y})
				else pm:SetQuickAxisTransformMode({math.AXIS_Z}) end
			end
		else
			local vp = pm:GetViewport()
			if(util.is_valid(vp)) then
				if(args[2] == "select") then
					vp:SetManipulatorMode(gui.PFMViewport.MANIPULATOR_MODE_SELECT)
				elseif(args[2] == "translate") then
					vp:SetTranslationManipulatorMode()
				elseif(args[2] == "rotate") then
					vp:SetRotationManipulatorMode()
				elseif(args[2] == "scale") then
					vp:SetScaleManipulatorMode()
				end
			end
		end
	end
end)

console.register_command("pfm_undo",function(pl,...)
	pfm.undo()
end)

console.register_command("pfm_redo",function(pl,...)
	pfm.redo()
end)

console.register_command("pfm_delete",function(pl,...)
	local pm = tool.get_filmmaker()
	if(util.is_valid(pm) == false) then return end
	local actorEditor = pm:GetActorEditor()
	if(util.is_valid(actorEditor) == false) then return end
	local ids = {}
	for _,actor in ipairs(actorEditor:GetSelectedActors()) do
		if(actor:IsValid()) then table.insert(ids,tostring(actor:GetUniqueId())) end
	end

	actorEditor:RemoveActors(ids)
end)

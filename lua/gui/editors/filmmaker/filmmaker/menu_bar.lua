--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:InitializeMenuBar()
	self.m_cbDropped = game.add_callback("OnFilesDropped", function(tFiles)
		local foundElement = false
		gui.get_element_under_cursor(function(el)
			if foundElement or el:IsDescendantOf(self) == false then
				return false
			end
			local result = el:CallCallbacks("OnFilesDropped", tFiles)
			if result == util.EVENT_REPLY_HANDLED then
				foundElement = true
				return true
			end
			return false
		end)
	end)

	local pMenuBar = self.m_menuBar
	pMenuBar
		:AddItem(locale.get_text("file"), function(pContext)
			--[[pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end

		end)]]

			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("new"))
			pItem:SetName("new")
			pSubMenu:SetName("new_menu")
			local pSubItem = pSubMenu:AddItem(locale.get_text("pfm_simple_project"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:ShowCloseConfirmation(function(res)
					self:CreateSimpleProject()
				end)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_simple_project"))
			pSubItem:SetName("simple_project")
			local pSubItem = pSubMenu:AddItem(locale.get_text("pfm_empty_project"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:ShowCloseConfirmation(function(res)
					self:CreateEmptyProject()
				end)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_empty_project"))
			pSubItem:SetName("empty_project")
			pSubMenu:ScheduleUpdate()

			local pSubItem = pContext:AddItem(locale.get_text("open") .. "...", function(pItem)
				if util.is_valid(self) == false then
					return
				end
				if self:CheckBuildKernels() then
					return
				end
				self:ShowCloseConfirmation(function(res)
					util.remove(self.m_openDialogue)
					local pOptionKeepCurrentLayout
					self.m_openDialogue = gui.create_file_open_dialog(function(pDialog, fileName)
						fileName = "projects/" .. fileName

						if console.get_convar_bool("pfm_keep_current_layout") then
							file.create_path("temp/pfm/")
							self:SaveWindowLayoutState("temp/pfm/restore_layout_state.udm", true)
						end

						self:LoadProject(fileName)
					end)
					self.m_openDialogue:SetRootPath("projects")
					self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())

					local pOptions = self.m_openDialogue:GetOptionsPanel()
					pOptionKeepCurrentLayout = pOptions:AddToggleControl(
						locale.get_text("pfm_keep_current_layout"),
						"keep_current_layout",
						console.get_convar_bool("pfm_keep_current_layout"),
						function(el, checked)
							console.run("pfm_keep_current_layout", checked and "1" or "0")
						end
					)

					self.m_openDialogue:Update()
				end)
			end)
			pSubItem:SetName("open")
			if self:IsDeveloperModeEnabled() then
				local pSubItem = pContext:AddItem(locale.get_text("reopen"), function(pItem)
					if util.is_valid(self) == false then
						return
					end
					if self:CheckBuildKernels() then
						return
					end
					self:LoadProject(self:GetProjectFileName())
				end)
				pSubItem:SetName("reopen")
			end
			local itemSave = pContext:AddItem(locale.get_text("save") .. "...", function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:Save(nil, nil, nil, nil, function(res)
					if res then
						self:ResetEditState()
					end
				end)
			end)
			itemSave:SetName("save")
			local session = self:GetSession()
			if session ~= nil and session:GetSettings():IsReadOnly() and self:IsDeveloperModeEnabled() == false then
				itemSave:SetEnabled(false)
			end

			local pSubItem = pContext:AddItem(locale.get_text("save_as"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:Save(nil, true, true, nil, function(res)
					if res then
						self:ResetEditState()
					end
				end)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_save_as"))
			pSubItem:SetName("save_as")

			local pSubItem = pContext:AddItem(locale.get_text("save_copy"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:Save(nil, false, true)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_save_copy"))
			pSubItem:SetName("save_copy")

			local recentFiles = self.m_settings:GetArrayValues("recent_projects", udm.TYPE_STRING)
			if #recentFiles > 0 then
				local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("recent_projects"))
				pItem:SetName("recent_projects")
				pSubMenu:SetName("recent_projects_menu")
				for _, f in ipairs(recentFiles) do
					pSubMenu:AddItem(f, function(pItem)
						if util.is_valid(self) == false then
							return
						end
						if self:CheckBuildKernels() then
							return
						end
						self:ShowCloseConfirmation(function(res)
							self:LoadProject(f)
						end)
					end)
					pSubMenu:ScheduleUpdate()
				end
			end

			local function initMapDialog(pFileDialog)
				pFileDialog:SetRootPath("maps")
				pFileDialog:SetExtensions(asset.get_supported_extensions(asset.TYPE_MAP, asset.FORMAT_TYPE_ALL))
				local pFileList = pFileDialog:GetFileList()
				pFileList:SetFileFinder(function(path)
					local tFiles, tDirs = file.find(path)
					local fileMap = {}
					local dirMap = {}
					for _, f in ipairs(tFiles) do
						local ext = file.get_file_extension(f)
						if pFileList:IsValidExtension(ext) then
							fileMap[f] = true
						end
					end
					for _, d in ipairs(tDirs) do
						dirMap[d] = true
					end

					local tFiles, tDirs = file.find_external_game_asset_files(file.get_file_path(path) .. "*.bsp")
					for _, f in ipairs(tFiles) do
						local ext = file.get_file_extension(f)
						if pFileList:IsValidExtension(ext) then
							fileMap[f] = true
						end
					end
					for _, d in ipairs(tDirs) do
						dirMap[d] = true
					end

					local fileList = {}
					for f, _ in pairs(fileMap) do
						table.insert(fileList, f)
					end

					local dirList = {}
					for d, _ in pairs(dirMap) do
						table.insert(dirList, d)
					end

					table.sort(fileList)
					table.sort(dirList)
					return fileList, dirList
				end)
				pFileDialog:Update()
			end

			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("import"))
			pItem:SetName("import")
			pSubMenu:SetName("import_menu")
			local pSubItem = pSubMenu:AddItem(locale.get_text("map"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				local pFileDialog = gui.create_file_open_dialog(function(el, fileName)
					if fileName == nil then
						return
					end
					self:ImportMap(el:GetFilePath(true))
				end)
				initMapDialog(pFileDialog)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_import_map"))
			pSubItem:SetName("map")
			local pSubItem = pSubMenu:AddItem(locale.get_text("pfm_sfm_project"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				if self:CheckBuildKernels() then
					return
				end
				util.remove(self.m_openDialogue)
				self.m_openDialogue = gui.create_file_open_dialog(function(pDialog, fileName)
					self:ShowCloseConfirmation(function(res)
						self:ImportSFMProject(fileName)
					end)
				end)
				self.m_openDialogue:SetExtensions({ "dmx" })
				self.m_openDialogue:GetFileList():SetFileFinder(function(path)
					local tFiles, tDirs = file.find(path .. "*")
					tFiles = file.find(path .. "*.dmx")

					local tFilesExt, tDirsExt = file.find_external_game_asset_files(path .. "*")
					tFilesExt = file.find_external_game_asset_files(path .. ".dmx")

					local tFilesExtUnique = {}
					for _, f in ipairs(tFilesExt) do
						f = file.remove_file_extension(f) .. ".dmx"
						tFilesExtUnique[f] = true
					end
					for _, f in ipairs(tFiles) do
						f = file.remove_file_extension(f) .. ".dmx"
						tFilesExtUnique[f] = true
					end

					local tDirsExtUnique = {}
					for _, f in ipairs(tDirsExt) do
						tDirsExtUnique[f] = true
					end
					for _, f in ipairs(tDirs) do
						tDirsExtUnique[f] = true
					end

					tFiles = {}
					tDirs = {}
					for f, _ in pairs(tFilesExtUnique) do
						table.insert(tFiles, f)
					end
					table.sort(tFiles)

					for d, _ in pairs(tDirsExtUnique) do
						table.insert(tDirs, d)
					end
					table.sort(tDirs)
					return tFiles, tDirs
				end)
				self.m_openDialogue:SetPath("elements/sessions")
				self.m_openDialogue:Update()
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_import_sfm_project"))
			pSubItem:SetName("sfm_project")
			if self:IsDeveloperModeEnabled() then
				local pSubItem = pSubMenu:AddItem(locale.get_text("pfm_pfm_project"), function(pItem)
					if util.is_valid(self) == false then
						return
					end
					util.remove(self.m_openDialogue)
					self.m_openDialogue = gui.create_file_open_dialog(function(pDialog, fileName)
						self:ImportPFMProject(fileName)
					end)
					self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())
					self.m_openDialogue:SetPath("projects")
					self.m_openDialogue:Update()
				end)
				pSubItem:SetName("pfm_project")
			end
			pSubMenu:ScheduleUpdate()

			local pSubItem = pContext:AddItem(locale.get_text("pfm_change_map"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				if self:CheckBuildKernels() then
					return
				end
				local pFileDialog = gui.create_file_open_dialog(function(el, fileName)
					if fileName == nil then
						return
					end
					local map = el:GetFilePath(true)
					self:ChangeMap(map)
				end)
				initMapDialog(pFileDialog)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_change_map"))
			pSubItem:SetName("change_map")
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
			local pSubItem = pContext:AddItem(locale.get_text("pfm_pack_project") .. "...", function(pItem)
				file.create_directory("export")
				local dialoge = gui.create_file_save_dialog(function(pDialoge)
					local fname = pDialoge:GetFilePath(true)
					self:PackProject(fname)
				end)
				dialoge:SetExtensions({ "zip" })
				dialoge:SetRootPath(util.get_addon_path() .. "export/")
				dialoge:Update()
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_pack_project"))
			pSubItem:SetName("pack_project")
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
			local pSubItem = pContext:AddItem(locale.get_text("close"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:ShowCloseConfirmation(function(res)
					self:CreateNewProject()
				end)
			end)
			pSubItem:SetName("close")
			local pSubItem = pContext:AddItem(locale.get_text("exit"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				if self:CheckBuildKernels() then
					return
				end
				self:ShowCloseConfirmation(function(res)
					tool.close_filmmaker()
					engine.shutdown()
				end)
			end)
			pSubItem:SetName("exit")
			pContext:ScheduleUpdate()
		end)
		:SetName("file")
	--[[pMenuBar:AddItem(locale.get_text("edit"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("windows"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("view"),function(pContext)

	end)]]
	if self:IsDeveloperModeEnabled() then
		pMenuBar
			:AddItem(locale.get_text("render"), function(pContext)
				local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pbr"))
				pItem:SetName("import")
				pSubMenu:SetName("pbr_menu")
				local pSubItem = pSubMenu:AddItem(
					locale.get_text("pfm_generate_ambient_occlusion_maps"),
					function(pItem)
						if util.is_valid(self) == false then
							return
						end
						local entPbrConverter = ents.find_by_component("pbr_converter")[1]
						if util.is_valid(entPbrConverter) == false then
							return
						end
						local pbrC = entPbrConverter:GetComponent(ents.COMPONENT_PBR_CONVERTER)
						for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_MODEL) }) do
							if ent:IsWorld() == false then
								local mdl = ent:GetModel()
								if mdl == nil or ent:IsWorld() then
									return
								end
								pbrC:GenerateAmbientOcclusionMaps(mdl)
								-- TODO: Also include all models for entire project which haven't been loaded yet
							end
						end
					end
				)
				pSubItem:SetTooltip(locale.get_text("pfm_menu_generate_ao"))
				pSubItem:SetName("pbr")
				local pSubItem = pSubMenu:AddItem(locale.get_text("pfm_rebuild_reflection_probes"), function(pItem) end)
				pSubItem:SetName("rebuild_reflection_probes")
				pSubMenu:ScheduleUpdate()

				pContext:ScheduleUpdate()
			end)
			:SetName("render")
	end
	--[[pMenuBar:AddItem(locale.get_text("map"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_generate_lightmaps"),function(pItem)
			
		end)
		pContext:AddItem(locale.get_text("pfm_write_lightmaps_to_bsp"),function(pItem)
			
		end)
		pContext:Update()
	end)]]
	pMenuBar
		:AddItem(locale.get_text("preferences"), function(pContext)
			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("language"))
			pItem:SetName("language")
			pSubMenu:SetName("language_menu")
			for lan, lanLoc in pairs(locale.get_languages()) do
				pSubMenu:AddItem(lanLoc, function(pItem)
					if util.is_valid(self) == false then
						return
					end
					locale.change_language(lan)
					console.run("cl_language", lan)
					self:ReloadInterface()
				end)
			end
			pItem:SetTooltip(locale.get_text("pfm_menu_change_language"))
			pSubMenu:ScheduleUpdate()

			pContext:ScheduleUpdate()
		end)
		:SetName("preferences")
	pMenuBar
		:AddItem(locale.get_text("tools"), function(pContext)
			local pSubItem = pContext:AddItem(locale.get_text("pfm_export_map"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
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
				if util.is_valid(vp) then
					local cam = vp:GetCamera()
					if util.is_valid(cam) then
						mapExportInfo:AddCamera(cam)
					end
				end
				mapExportInfo.includeMapLightSources = false
				for light in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_LIGHT) }) do
					local lightC = light:GetComponent(ents.COMPONENT_LIGHT)
					mapExportInfo:AddLightSource(lightC)
				end

				local success, errMsg = asset.export_map(mapName, exportInfo, mapExportInfo)
				if success then
					util.open_path_in_explorer("export/maps/" .. mapName .. "/" .. mapName .. "/", mapName .. ".glb")
					return
				end
				pfm.log("Unable to export map: " .. errMsg, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_export_map"))
			pSubItem:SetName("export_map")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_convert_map_to_actors"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				pfm.open_message_prompt(
					locale.get_text("pfm_prompt_continue"),
					locale.get_text("pfm_prompt_action_cannot_be_undone"),
					bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO),
					function(bt)
						if bt == gui.PfmPrompt.BUTTON_YES then
							local mapName = game.get_map_name()
							local mapFile = asset.find_file(mapName, asset.TYPE_MAP)
							if mapFile == nil then
								return
							end
							util.remove(
								ents.get_all(ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_MAP) }))
							)

							local session = self:GetSession()
							if session ~= nil then
								local settings = session:GetSettings()
								-- The map is now part of the project, so we want to load an empty map next time the project is loaded
								settings:SetMapName("empty")
							end

							self:ImportMap(mapFile)
						end
					end
				)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_convert_map_to_actors"))
			pSubItem:SetName("convert_map_to_actors")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_convert_static_actors_to_map"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:ConvertStaticActorsToMap()
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_convert_static_actors_to_map"))
			pSubItem:SetName("convert_static_actors_to_map")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_build_kernels"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:BuildKernels()
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_build_kernels"))
			pSubItem:SetName("build_kernels")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_start_lua_debugger_server"), function(pItem)
				if util.is_valid(self) == false then
					return
				end
				debug.start_debugger_server()
				pfm.create_popup_message(locale.get_text("pfm_lua_debugger_server_active"), 10, gui.InfoBox.TYPE_WARNING, {
					url = "https://wiki.pragma-engine.com/books/lua-api/page/visual-studio-code",
				})
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_start_lua_debugger_server"))
			pSubItem:SetName("start_lua_debugger_server")
			if self:IsDeveloperModeEnabled() then
				local recorder
				local pSubItem = pContext:AddItem("Record animation as image sequence", function(pItem)
					if recorder == nil or recorder:IsRecording() == false then
						include("/gui/editors/filmmaker/image_recorder.lua")

						recorder = pfm.ImageRecorder(self)
						file.create_path("render/recording/recording")
						recorder:StartRecording("render/recording/recording")
					else
						recorder:StopRecording()
						recorder = nil
					end
				end)
				pSubItem:SetName("record_animation_as_image_sequence")
				local pSubItem = pContext:AddItem("Generate lightmap uvs", function(pItem)
					local actorEditor = self:GetActorEditor()
					if util.is_valid(actorEditor) == false then
						return
					end
					for _, actor in ipairs(actorEditor:GetSelectedActors()) do
						local ent = actor:FindEntity()
						if util.is_valid(ent) then
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
							local bakedC = ent:AddComponent("pfm_baked_lighting")
							bakedC:GenerateLightmapUvs()
						end
					end
				end)
				pSubItem:SetName("generate_lightmap_uvs")
				local pSubItem = pContext:AddItem("Test build lightmaps Low", function(pItem)
					local actorEditor = self:GetActorEditor()
					if util.is_valid(actorEditor) == false then
						return
					end
					for _, actor in ipairs(actorEditor:GetSelectedActors()) do
						local ent = actor:FindEntity()
						if util.is_valid(ent) then
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
							local bakedC = ent:AddComponent("pfm_baked_lighting")
							bakedC:GenerateLightmaps(false, 10)
						end
					end
				end)
				local pSubItem = pContext:AddItem("Test build lightmaps High", function(pItem)
					local actorEditor = self:GetActorEditor()
					if util.is_valid(actorEditor) == false then
						return
					end
					for _, actor in ipairs(actorEditor:GetSelectedActors()) do
						local ent = actor:FindEntity()
						if util.is_valid(ent) then
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
							ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
							local bakedC = ent:AddComponent("pfm_baked_lighting")
							bakedC:GenerateLightmaps(false, 10)
						end
					end
				end)

				local pSubItem = pContext:AddItem(locale.get_text("pfm_reload_in_dev_mode"), function(pItem)
					console.run("pfm -log all -dev -reload")
				end)
				pSubItem:SetName("reload_in_dev_mode")
			end

			pContext:ScheduleUpdate()
		end)
		:SetName("tools")
	self:AddWindowsMenuBarItem(function(pContext)
		local path = "cfg/pfm/layouts/"
		local tFiles, tDirs = file.find(path .. "*.udm")
		if #tFiles == 0 then
			return
		end
		local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("layout"))
		pItem:SetName("layout")
		pSubMenu:SetName("layout_menu")
		for _, f in ipairs(tFiles) do
			local baseName = file.remove_file_extension(f, { "udm" })
			local pSubItem = pSubMenu:AddItem(baseName, function(pItem)
				if util.is_valid(self) == false then
					return
				end
				self:LoadLayout(path .. f)
			end)
			pSubItem:SetName(baseName)
		end
		pSubMenu:ScheduleUpdate()

		local pSubItem = pContext:AddItem(locale.get_text("pfm_save_current_layout_state_as_default"), function(pItem)
			if util.is_valid(self) == false then
				return
			end
			self:SaveWindowLayoutState("cfg/pfm/default_layout_state.udm", true)
		end)
		pSubItem:SetTooltip(locale.get_text("pfm_menu_context_save_layout_state_as_default"))
		pSubItem:SetName("save_current_layout_state_as_default")
		local pSubItem = pContext:AddItem(locale.get_text("pfm_restore_default_layout_state"), function(pItem)
			if util.is_valid(self) == false then
				return
			end
			self:RestoreWindowLayoutState("cfg/pfm/default_layout_state.udm")
		end)
		pSubItem:SetTooltip(locale.get_text("pfm_menu_context_restore_default_layout_state"))
		pSubItem:SetName("restore_default_layout_state")

		pContext:ScheduleUpdate()
	end)
	pMenuBar
		:AddItem(locale.get_text("help"), function(pContext)
			local pSubItem = pContext:AddItem(locale.get_text("pfm_getting_started"), function(pItem)
				self:ShowCloseConfirmation(function(res)
					self:LoadTutorial("intro")
				end)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_getting_started"))
			pSubItem:SetName("getting_started")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_tutorial_catalog"), function(pItem)
				self:GoToWindow("tutorial_catalog")
			end)
			pSubItem:SetName("tutorial_catalog")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_wiki"), function(pItem)
				self:OpenUrlInBrowser("https://wiki.pragma-engine.com/books/pragma-filmmaker")
			end)
			pSubItem:SetName("wiki")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_report_a_bug"), function(pItem)
				util.open_url_in_browser("https://github.com/Silverlan/pfm/issues")
			end)
			pSubItem:SetName("report_a_bug")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_check_for_updates"), function(pItem)
				self:CheckForUpdates(true)
			end)
			pSubItem:SetName("check_for_updates")
			local pSubItem = pContext:AddItem(locale.get_text("pfm_community"), function(pItem)
				local engineInfo = engine.get_info()
				self:OpenUrlInBrowser(engineInfo.discordURL)
			end)
			pSubItem:SetTooltip(locale.get_text("pfm_menu_context_pfm_community"))
			pSubItem:SetName("community")
			pContext:ScheduleUpdate()
		end)
		:SetName("help")
	pMenuBar:ScheduleUpdate()
end
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
include("/gui/pfm/frame.lua")
include("/gui/pfm/viewport.lua")
include("/gui/pfm/postprocessing.lua")
include("/gui/pfm/timeline.lua")
include("/gui/pfm/elementviewer.lua")
include("/gui/pfm/actoreditor.lua")
include("/gui/pfm/modelcatalog.lua")
include("/gui/pfm/materialcatalog.lua")
include("/gui/pfm/particlecatalog.lua")
include("/gui/pfm/actorcatalog.lua")
include("/gui/pfm/renderpreview.lua")
include("/gui/pfm/infobar.lua")
include("/gui/pfm/materialeditor.lua")
include("/gui/pfm/particleeditor.lua")
include("/pfm/util_particle_system.lua")
include("project_packer.lua")

gui.load_skin("pfm")
locale.load("pfm_user_interface.txt")

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
end
function gui.WIFilmmaker:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)
	tool.editor = self -- TODO: This doesn't really belong here (check lua/autorun/client/cl_filmmaker.lua)

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
		pContext:AddItem(locale.get_text("new") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			self:CreateNewProject()
		end)
		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
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
			if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
			self.m_openDialogue = gui.create_file_save_dialog(function(pDialog,fileName)
				fileName = "projects/" .. file.remove_file_extension(fileName) .. ".pfm"
				self:SaveProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("projects")
			self.m_openDialogue:SetExtensions({"pfm"})
			self.m_openDialogue:Update()
		end)
		pContext:AddItem(locale.get_text("import") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
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
		pContext:AddItem(locale.get_text("pfm_export_blender_scene") .. "...",function(pItem)
			local dialoge = gui.create_file_save_dialog(function(pDialoge)
				local fname = pDialoge:GetFilePath(true)
				file.create_path(file.get_file_path(fname))

				import.export_scene(fname)
			end)
			dialoge:SetExtensions({"fbx"})
			dialoge:SetRootPath(util.get_addon_path())
			dialoge:Update()
		end)
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
	pMenuBar:AddItem(locale.get_text("help"),function(pContext)
		pContext:AddItem(locale.get_text("pfm_getting_started"),function(pItem)
			util.open_url_in_browser("https://wiki.pragma-engine.com/index.php?title=Pfm_firststeps")
		end)
		pContext:AddItem(locale.get_text("pfm_report_a_bug"),function(pItem)
			util.open_url_in_browser("https://gitlab.com/Silverlan/pfm/issues")
		end)
		pContext:Update()
	end)
	pMenuBar:Update()

	local pInfoBar = gui.create("WIPFMInfobar",self)
	pInfoBar:SetWidth(self:GetWidth())
	pInfoBar:SetY(self:GetHeight() -pInfoBar:GetHeight())
	pInfoBar:SetAnchor(0,1,1,1)
	self.m_infoBar = pInfoBar

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
end
function gui.WIFilmmaker:GetGameScene() return self:GetRenderTab():GetGameScene() end
function gui.WIFilmmaker:GetViewport() return self.m_viewport end
function gui.WIFilmmaker:GetRenderTab() return self.m_viewportFrame:FindTab("render") end
function gui.WIFilmmaker:GetActorEditor() return self.m_actorEditor end
function gui.WIFilmmaker:CreateNewActor()
	-- TODO: What if no actor editor is open?
	return self.m_actorEditor:CreateNewActor()
end
function gui.WIFilmmaker:CreateNewActorComponent(actor,componentType)
	-- TODO: What if no actor editor is open?
	return self.m_actorEditor:CreateNewActorComponent(actor,componentType)
end
function gui.WIFilmmaker:KeyboardCallback(key,scanCode,state,mods)
	-- TODO: Implement a keybinding system for this! Keybindings should also appear in tooltips!
	if(key == input.KEY_SPACE) then
		if(state == input.STATE_PRESS and util.is_valid(self.m_viewport)) then
			local playButton = self.m_viewport:GetPlayButton()
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
function gui.WIFilmmaker:AddFrame(parent)
	if(util.is_valid(self.m_contents) == false) then return end
	local frame = gui.create("WIPFMFrame",parent)
	if(frame == nil) then return end
	table.insert(self.m_frames,frame)
	return frame
end
function gui.WIFilmmaker:OnThink()
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
	if(util.is_valid(self.m_cbDropped)) then self.m_cbDropped:Remove() end
	if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
	if(self.m_previewWindow ~= nil) then self.m_previewWindow:Remove() end
	if(self.m_renderResultWindow ~= nil) then self.m_renderResultWindow:Remove() end
	self.m_selectionManager:Remove()

	if(self.m_animRecorder ~= nil) then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end

	if(util.is_valid(self.m_reflectionProbe)) then self.m_reflectionProbe:Remove() end
	if(util.is_valid(self.m_entLight)) then self.m_entLight:Remove() end
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
function gui.WIFilmmaker:IsRecording() return self.m_videoRecorder:IsRecording() end
function gui.WIFilmmaker:StopRecording()
	self.m_videoRecorder:StopRecording()
end
function gui.WIFilmmaker:SetGameViewOffset(offset)
	self.m_updatingProjectTimeOffset = true
	if(util.is_valid(self.m_playhead)) then self.m_playhead:SetTimeOffset(offset) end

	pfm.ProjectManager.SetGameViewOffset(self,offset)

	local session = self:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	if(activeClip ~= nil) then
		if(util.is_valid(self.m_viewport)) then
			self.m_viewport:SetGlobalTime(offset)

			local childClip = activeClip:GetChildFilmClip(offset)
			if(childClip ~= nil) then
				self.m_viewport:SetLocalTime(childClip:GetTimeFrame():LocalizeOffset(offset))
				self.m_viewport:SetFilmClipName(childClip:GetName())
				self.m_viewport:SetFilmClipParentName(activeClip:GetName())
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
				self:RefreshGameView() -- TODO: We don't really need to refresh the entire game view, just the current film clip would be sufficient.
			end)
		end
	end

	self:InitializeProjectUI()
	self:SetTimeOffset(0)

	return entScene
end
function gui.WIFilmmaker:AddFilmClipElement(filmClip)
	local pFilmClip = self.m_timeline:AddFilmClip(self.m_filmStrip,filmClip,function(elFilmClip)
		local filmClipData = elFilmClip:GetFilmClipData()
		if(util.is_valid(self.m_actorEditor)) then
			self.m_actorEditor:Setup(filmClipData)
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
	if(util.is_valid(self.m_contents)) then self.m_contents:Remove() end
	self.m_frames = {}
end
function gui.WIFilmmaker:InitializeProjectUI()
	self:ClearProjectUI()
	if(util.is_valid(self.m_menuBar) == false or util.is_valid(self.m_infoBar) == false) then return end
	self.m_contents = gui.create("WIHBox",self,0,self.m_menuBar:GetHeight(),self:GetWidth(),self:GetHeight() -self.m_menuBar:GetHeight() -self.m_infoBar:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	local actorDataFrame = self:AddFrame(self.m_contents)
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
	actorDataFrame:AddTab("actor_editor",locale.get_text("pfm_actor_editor"),actorEditor)
	self.m_actorEditor = actorEditor -- TODO Determine dynamically

	local modelCatalog = gui.create("WIPFMModelCatalog")
	actorDataFrame:AddTab("model_catalog",locale.get_text("pfm_model_catalog"),modelCatalog)
	self.m_modelCatalog = modelCatalog -- TODO Determine dynamically

	local materialCatalog = gui.create("WIPFMMaterialCatalog")
	actorDataFrame:AddTab("material_catalog",locale.get_text("pfm_material_catalog"),materialCatalog)
	self.m_materialCatalog = materialCatalog -- TODO Determine dynamically

	local particleCatalog = gui.create("WIPFMParticleCatalog")
	actorDataFrame:AddTab("particle_catalog",locale.get_text("pfm_particle_catalog"),particleCatalog)
	self.m_materialCatalog = particleCatalog -- TODO Determine dynamically

	local actorCatalog = gui.create("WIPFMActorCatalog")
	actorDataFrame:AddTab("actor_catalog",locale.get_text("pfm_actor_catalog"),actorCatalog)
	self.m_actorCatalog = actorCatalog -- TODO Determine dynamically

	local elementViewer = gui.create("WIPFMElementViewer")
	actorDataFrame:AddTab("element_viewer",locale.get_text("pfm_element_viewer"),elementViewer)
	self.m_elementViewer = elementViewer
	self.m_actorDataFrame = actorDataFrame
	
	gui.create("WIResizer",self.m_contents):SetFraction(0.25)

	self.m_contentsRight = gui.create("WIVBox",self.m_contents)
	self.m_contents:Update()
	self.m_contentsRight:SetAutoFillContents(true)

	local viewportFrame = self:AddFrame(self.m_contentsRight)
	viewportFrame:SetHeight(self:GetHeight())
	local viewport = gui.create("WIPFMViewport")
	self.m_viewport = viewport
	self.m_viewportFrame = viewportFrame
	viewportFrame:AddTab("primary_viewport",locale.get_text("pfm_primary_viewport"),viewport)

	local renderPreview = gui.create("WIPFMRenderPreview")
	viewportFrame:AddTab("render",locale.get_text("pfm_cycles_renderer"),renderPreview)

	local postProcessing = gui.create("WIPFMPostProcessing")
	viewportFrame:AddTab("post_processing",locale.get_text("pfm_post_processing"),postProcessing)

	gui.create("WIResizer",self.m_contentsRight):SetFraction(0.75)

	local timelineFrame = self:AddFrame(self.m_contentsRight)
	local pfmTimeline = gui.create("WIPFMTimeline")
	self.m_timeline = pfmTimeline
	timelineFrame:AddTab("timeline",locale.get_text("pfm_timeline"),pfmTimeline)

	-- Populate UI with project data
	local project = self:GetProject()
	local root = project:GetUDMRootNode()
	elementViewer:Setup(root)

	local playhead = pfmTimeline:GetPlayhead()
	self.m_playhead = playhead
	playhead:GetTimeOffsetProperty():AddCallback(function(oldOffset,offset)
		if(self.m_updatingProjectTimeOffset ~= true) then
			self:SetTimeOffset(offset)
		end
	end)
	local playButton = viewport:GetPlayButton()
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
		if(util.is_valid(self.m_actorEditor) and util.get_type_name(clip) == "PFMFilmClip") then self.m_actorEditor:Setup(clip) end
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
	self.m_actorDataFrame:RemoveTab("material_editor")

	local matEd = gui.create("WIPFMMaterialEditor")
	local tabId = self.m_actorDataFrame:AddTab("material_editor",locale.get_text("pfm_material_editor"),matEd)
	self.m_actorDataFrame:SetActiveTab(tabId)

	matEd:SetMaterial(mat,optMdl)
end
function gui.WIFilmmaker:OpenParticleEditor(ptFile,ptName)
	self.m_actorDataFrame:RemoveTab("particle_editor")

	local ptEd = gui.create("WIPFMParticleEditor")
	local tabId = self.m_actorDataFrame:AddTab("particle_editor",locale.get_text("pfm_particle_editor"),ptEd)
	self.m_actorDataFrame:SetActiveTab(tabId)

	ptEd:LoadParticleSystem(ptFile,ptName)
end
function gui.WIFilmmaker:OnActorSelectionChanged(ent,selected)
	if(util.is_valid(self.m_viewport) == false) then return end
	self.m_viewport:OnActorSelectionChanged(ent,selected)
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
	if(util.is_valid(self.m_elementViewer) == false) then return end
	self.m_elementViewer:MakeElementRoot(el)

	if(util.is_valid(self.m_actorDataFrame)) then
		self.m_actorDataFrame:SetActiveTab(self.m_elementViewer)
	end
end
function gui.WIFilmmaker:SelectActor(actor)
	if(util.is_valid(self.m_actorEditor) == false) then return end
	self.m_actorEditor:SelectActor(actor)

	if(util.is_valid(self.m_actorDataFrame)) then
		self.m_actorDataFrame:SetActiveTab(self.m_actorEditor)
	end
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

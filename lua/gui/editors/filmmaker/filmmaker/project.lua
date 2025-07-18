-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/playback_state.lua")

local Element = gui.WIFilmmaker

function Element:OnProjectLoaded(fileName, project)
	self:AddRecentProject(fileName)
	self:CallCallbacks("OnProjectLoaded")
end
function Element:AddRecentProject(fileName)
	self:LogInfo("Adding recent project '" .. fileName .. "'...")
	local maxCount = 10
	local udmRecentProjects = self.m_settings:Get("recent_projects")
	if udmRecentProjects:IsValid() == false then
		self.m_settings:AddArray("recent_projects", 0, udm.TYPE_STRING)
		udmRecentProjects = self.m_settings:Get("recent_projects")
	end
	local recentFiles = self.m_settings:GetArrayValues("recent_projects", udm.TYPE_STRING)
	for i, f in ipairs(recentFiles) do
		if f == fileName then
			udmRecentProjects:RemoveValue(i - 1)
			break
		end
	end
	udmRecentProjects:InsertValue(0, fileName)
	if udmRecentProjects:GetSize() > maxCount then
		udmRecentProjects:Resize(maxCount)
	end
end
function Element:CreateInitialProject()
	self:CreateSimpleProject(true)
	self:RestoreWindowLayoutState("cfg/pfm/default_layout_state.udm")
end
function Element:CreateSimpleProject()
	self:CreateEmptyProject()

	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end

	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY)
	local cam = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA)
	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE)
	actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER)

	local filmClip = self:GetActiveGameViewFilmClip()
	if filmClip ~= nil then
		filmClip:SetCamera(cam)
	end

	pfm.undoredo.clear()
	self:ResetEditState()
end
function Element:CreateEmptyProject()
	self:CreateNewProject()

	local session = self:GetSession()
	if session ~= nil then
		local settings = session:GetSettings()
		local mapName = asset.get_normalized_path(game.get_map_name(), asset.TYPE_MAP)
		self:LogInfo("Assigning map name '" .. mapName .. "' to new project.")
		settings:SetMapName(mapName)
	end

	local filmClip = self:GetActiveFilmClip()
	if filmClip == nil then
		return
	end

	self:SelectFilmClip(filmClip)

	pfm.undoredo.clear()
	self:ResetEditState()
end
function Element:OnProjectClosed()
	pfm.ProjectManager.OnProjectClosed(self)
	if self.m_trackCallbacks ~= nil then
		util.remove(self.m_trackCallbacks)
	end
	self:UpdateAutosave(true)
	self:CallCallbacks("OnProjectClosed")
end
function Element:OnProjectFileNameChanged(projectFileName)
	local window = gui.get_primary_window()
	if util.is_valid(window) then
		local title = self.m_originalWindowTitle
		if projectFileName ~= nil then
			title = title .. " - " .. projectFileName
		else
			title = title .. " - " .. locale.get_text("untitled")
		end
		local session = self:GetSession()
		if session ~= nil and session:GetSettings():IsReadOnly() then
			title = title .. " (" .. locale.get_text("read_only") .. ")"
		end
		window:SetWindowTitle(title)
	end
end
function Element:InitializeProject(project)
	self:UpdateAutosave()
	--[[if util.is_valid(self.m_playbackControls) then
		local timeFrame = projectC:GetTimeFrame()
		self.m_playbackControls:SetDuration(timeFrame:GetDuration())
		self.m_playbackControls:SetOffset(0.0)
	end]]

	local entScene = gui.WIBaseFilmmaker.InitializeProject(self, project)

	-- We want the frame offset to start at 0, but the default value is already 0, which means the
	-- callbacks would not get triggered properly. To fix that, we'll just set it to some random value != 0
	-- before actually setting it to 0 further below.
	self:SetTimeOffset(1.0)
	local session = self:GetSession()
	if session ~= nil then
		local filmTrack = session:GetFilmTrack()
		if filmTrack ~= nil then
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
	if console.get_convar_bool("pfm_keep_current_layout") and file.exists(layoutStateFileName) then
		-- Restore previous layout state
		local udmData = self:LoadWindowLayoutState(layoutStateFileName)
		file.delete(layoutStateFileName)

		if udmData ~= nil then
			udmLayout = udmData:Get("layout_state")
			layout = udmLayout:GetValue("layout", udm.TYPE_STRING)
		end
	end

	local settings = session:GetSettings()
	self:InitializePlaybackState()
	self:InitializeProjectUI(layout or settings:GetLayout())
	self:SetTimeOffset(0)
	self:RestoreWorkCamera()
	self:RestoreWindowLayoutState(udmLayout or settings:GetLayoutState():GetUdmData(), udmLayout == nil)

	self:LoadUndoRedoStack()
	time.create_simple_timer(0.1, function()
		if self:IsValid() then
			self:RestoreUiState()
		end
	end)
	return entScene
end
function Element:ClearProjectUI()
	self:ClearLayout()
end
function Element:InitializeProjectUI(layoutName)
	self:ClearProjectUI()
	if util.is_valid(self.m_menuBar) == false or util.is_valid(self.m_infoBar) == false then
		return
	end
	self:InitializeGenericLayout()

	self:InitializeLayout(layoutName)
	self:RegisterWindows()

	self:OpenWindow("actor_editor")
	-- self:OpenWindow("element_viewer")
	-- self:OpenWindow("tutorial_catalog")

	local tab, elVp = self:OpenWindow("primary_viewport")
	self:OpenWindow("render")
	self:OpenWindow("web_browser")
	self:OpenWindow("model_catalog")
	self:OpenWindow("tutorial_catalog")

	if util.is_valid(elVp) then
		elVp:UpdateRenderSettings()
	end

	self:OpenWindow("timeline")

	-- Populate UI with project data
	local pfmTimeline = self.m_timeline
	local project = self:GetProject()
	local root = project:GetUDMRootNode()
	local elViewer = self:GetElementViewer()
	if util.is_valid(elViewer) then
		elViewer:Setup(root)
	end

	local playhead = pfmTimeline:GetPlayhead()
	playhead:SetFrameRate(self:GetFrameRate())
	self.m_playhead = playhead

	pfmTimeline:AddCallback("OnClipSelected", function(el, clip)
		clip = clip:GetClipData()
		if util.get_type_name(clip) == "FilmClip" then
			for _, editor in ipairs({ self:GetActorEditor(), self:GetGraphEditor(), self:GetMotionEditor() }) do
				if util.is_valid(editor) then
					editor:Setup(clip)
				end
			end
		end
	end)

	-- Film strip
	local session = project:GetSession()
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	local filmStrip
	if filmClip ~= nil then
		local timeline = pfmTimeline:GetTimeline()

		filmStrip = gui.create("WIFilmStrip")
		self.m_filmStrip = filmStrip
		filmStrip:SetScrollInputEnabled(true)
		filmStrip:AddCallback("OnScroll", function(el, x, y)
			if timeline:IsValid() then
				local axis = timeline:GetTimeAxis():GetAxis()
				timeline:SetStartOffset(axis:GetStartOffset() - y * axis:GetZoomLevelMultiplier())
				timeline:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_UNHANDLED
		end)

		local trackFilm = session:GetFilmTrack()
		if trackFilm ~= nil then
			for _, filmClip in ipairs(trackFilm:GetFilmClips()) do
				self:AddFilmClipElement(filmClip)
			end
		end
		filmStrip:SetSize(1024, 64)
		filmStrip:Update()

		local pfmClipEditor = pfmTimeline:GetEditorTimelineElement(gui.PFMTimeline.EDITOR_CLIP)
		local groupPicture = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_picture"))
		if filmStrip ~= nil then
			for _, filmClip in ipairs(filmStrip:GetFilmClips()) do
				timeline:AddTimelineItem(filmClip, filmClip:GetTimeFrame())
			end
		end
		groupPicture:AddElement(filmStrip)
		self.m_trackGroupPicture = groupPicture

		local timeFrame = filmClip:GetTimeFrame()
		local groupSound = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_sound"))
		groupSound:SetMouseInputEnabled(true)
		groupSound:AddCallback("OnMouseEvent", function(groupSound, button, state, mods)
			if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
				local pContext = gui.open_context_menu(self)
				if util.is_valid(pContext) == false then
					return
				end
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem("Add Track", function()
					local p = pfm.open_single_value_edit_window("Track Name", function(ok, val)
						if self:IsValid() == false then
							return
						end
						if ok then
							pfm.undoredo.push("add_audio_track", pfm.create_command("add_audio_track", val, filmClip))()
						end
					end, "")
				end)
				pContext:Update()
				return util.EVENT_REPLY_HANDLED
			end
		end)
		self.m_trackGroupSound = groupSound
		local trackGroupSound = filmClip:FindTrackGroup("Sound")
		if trackGroupSound ~= nil then
			for _, track in ipairs(trackGroupSound:GetTracks()) do
				--if(track:GetName() == "Music") then
				self:AddAudioTrack(track)
				--end
			end
		end

		local groupOverlay = pfmClipEditor:AddTrackGroup(locale.get_text("pfm_clip_editor_overlay"))
		local trackGroupOverlay = filmClip:FindTrackGroup("Overlay")
		if trackGroupOverlay ~= nil then
			for _, track in ipairs(trackGroupOverlay:GetTracks()) do
				local subGroup = groupOverlay:AddGroup(track:GetName())
				timeline:AddTimelineItem(subGroup, timeFrame)

				for _, overlayClip in ipairs(track:GetOverlayClips()) do
					pfmTimeline:AddOverlayClip(subGroup, overlayClip)
				end
			end
		end
		self.m_trackGroupOverlay = groupOverlay
	end

	if util.is_valid(self.m_trackGroupPicture) then
		self.m_trackGroupPicture:Expand()
	end
	if util.is_valid(filmStrip) then
		local filmClips = filmStrip:GetFilmClips()
		local filmClip = filmClips[1]
		if util.is_valid(filmClip) then
			filmClip:SetSelected(true)
		end
	end

	local vp = self:GetViewport()
	local camScene = util.is_valid(vp) and vp:GetSceneCamera() or nil
	if util.is_valid(camScene) then
		vp:SetWorkCameraPose(camScene:GetEntity():GetPose())
	end
end

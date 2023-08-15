--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:OnProjectLoaded(fileName, project)
	self:AddRecentProject(fileName)
	self:CallCallbacks("OnProjectLoaded")
end
function Element:AddRecentProject(fileName)
	pfm.log("Adding recent project '" .. fileName .. "'...", pfm.LOG_CATEGORY_PFM)
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
end
function Element:CreateEmptyProject()
	self:CreateNewProject()

	local session = self:GetSession()
	if session ~= nil then
		local settings = session:GetSettings()
		local mapName = asset.get_normalized_path(game.get_map_name(), asset.TYPE_MAP)
		pfm.log("Assigning map name '" .. mapName .. "' to new project.", pfm.LOG_CATEGORY_PFM)
		settings:SetMapName(mapName)
	end

	local filmClip = self:GetActiveFilmClip()
	if filmClip == nil then
		return
	end

	self:SelectFilmClip(filmClip)
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
	if util.is_valid(self.m_playbackControls) then
		local timeFrame = projectC:GetTimeFrame()
		self.m_playbackControls:SetDuration(timeFrame:GetDuration())
		self.m_playbackControls:SetOffset(0.0)
	end

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
	self:InitializeProjectUI(layout or settings:GetLayout())
	self:SetTimeOffset(0)
	self:RestoreWorkCamera()
	self:RestoreWindowLayoutState(udmLayout or settings:GetLayoutState():GetUdmData(), udmLayout == nil)
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

	for _, windowData in ipairs(pfm.get_registered_windows()) do
		self:RegisterWindow(windowData.category, windowData.name, windowData.localizedName, function()
			return windowData.factory(self)
		end)
	end

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
	playhead:GetTimeOffsetProperty():AddCallback(function(oldOffset, offset)
		if self.m_updatingProjectTimeOffset ~= true then
			self:SetTimeOffset(offset)
		end
	end)

	local playButton = self:GetViewport():GetPlayButton()
	playButton:AddCallback("OnTimeAdvance", function(el, dt)
		if playhead:IsValid() then
			playhead:SetTimeOffset(playhead:GetTimeOffset() + dt)
		end
	end)
	playButton:AddCallback("OnStateChanged", function(el, oldState, state)
		ents.PFMSoundSource.set_audio_enabled(state == gui.PFMPlayButton.STATE_PLAYING)
		if state == gui.PFMPlayButton.STATE_PAUSED then
			self:ClampTimeOffsetToFrame()
		end
	end)

	pfmTimeline:AddCallback("OnClipSelected", function(el, clip)
		if util.is_valid(self:GetActorEditor()) and util.get_type_name(clip) == "PFMFilmClip" then
			self:GetActorEditor():Setup(clip)
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
		local trackGroupSound = filmClip:FindTrackGroup("Sound")
		if trackGroupSound ~= nil then
			for _, track in ipairs(trackGroupSound:GetTracks()) do
				--if(track:GetName() == "Music") then
				local subGroup = groupSound:AddGroup(track:GetName())
				timeline:AddTimelineItem(subGroup, timeFrame)

				for _, audioClip in ipairs(track:GetAudioClips()) do
					pfmTimeline:AddAudioClip(subGroup, audioClip)
				end
				--end
			end
		end
		self.m_trackGroupSound = groupSound

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
function Element:RestoreProject()
	local udmData, err = udm.load("temp/pfm/restore/restore.udm")
	local originalProjectFileName
	if udmData == false then
		pfm.log("Failed to restore project: Unable to open restore file!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		return false
	end
	udmData = udmData:GetAssetData():GetData()
	local restoreData = udmData:ClaimOwnership()
	originalProjectFileName = restoreData:GetValue("originalProjectFileName", udm.TYPE_STRING)
	local restoreProjectFileName = restoreData:GetValue("restoreProjectFileName", udm.TYPE_STRING)
	if restoreProjectFileName == nil then
		pfm.log("Failed to restore project: Invalid restore data!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local fileName = restoreProjectFileName
	if self:LoadProject(fileName, true) == false then
		pfm.log(
			"Failed to restore project: Unable to load restore project!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_ERROR
		)
		self:CloseProject()
		self:CreateEmptyProject()
		return false
	end
	local newProjectMapName = restoreData:GetValue("newProjectMapName")
	if newProjectMapName ~= nil then
		local session = self:GetSession()
		if session ~= nil then
			local settings = session:GetSettings()
			settings:SetMapName(asset.get_normalized_path(newProjectMapName, asset.TYPE_MAP))
		end
	end
	self:SetProjectFileName(originalProjectFileName)
	file.delete_directory("temp/pfm/restore")
end

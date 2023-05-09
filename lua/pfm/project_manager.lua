--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("game_view.lua")
include("/pfm/animation_cache.lua")
include("/pfm/performance_cache.lua")
include("/pfm/panima.lua")

pfm = pfm or {}

util.register_class("pfm.ProjectManager", pfm.GameView)
function pfm.ProjectManager:__init()
	pfm.GameView.__init(self)
	self:SetCachedMode(false)
end
function pfm.ProjectManager:OnInitialize()
	self.m_gameScene = game.get_scene()
	self.m_performanceCache = pfm.PerformanceCache()
	self.m_animManager = pfm.AnimationManager()

	gui.close_main_menu()
	self.m_cbDisableDefaultConsoleInput = input.add_callback("OnCharInput", function(c)
		if c == input.KEY_GRAVE_ACCENT then
			self:OpenWindow("console")
			self:GoToWindow("console")
			local console = gui.get_console()
			if util.is_valid(console) then
				console:RequestFocus()
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)

	self.m_cbDisableEscapeMenu = input.add_callback("OnKeyboardInput", function(key, state, mods)
		if key == input.KEY_ESCAPE then
			if state == input.STATE_PRESS then
				self:OpenEscapeMenu()
			end
			return util.EVENT_REPLY_HANDLED -- Disable default behavior
		end
	end)

	self:CreateInitialProject()
	self.m_map = game.get_map_name()
end
function pfm.ProjectManager:OnRemove()
	util.remove(self.m_cbDisableEscapeMenu)
	util.remove(self.m_cbDisableDefaultConsoleInput)
end
function pfm.ProjectManager:OpenEscapeMenu() end
function pfm.ProjectManager:CreateInitialProject()
	self:CreateNewProject()
end
function pfm.ProjectManager:GetAnimationManager()
	return self.m_animManager
end
function pfm.ProjectManager:LoadMap(mapName)
	pfm.log("Loading map '" .. mapName .. "'...", pfm.LOG_CATEGORY_PFM)
	if mapName ~= nil then
		if mapName:lower() == self.m_map:lower() then
			pfm.log("Map has already been loaded!", pfm.LOG_CATEGORY_PFM)
			return
		end
		self:ClearMap()
		self.m_map = mapName
		pfm.log("Changing map to '" .. mapName .. "'...", pfm.LOG_CATEGORY_PFM)
		local packet = net.Packet()
		packet:WriteString(mapName)
		net.send(net.PROTOCOL_SLOW_RELIABLE, "sv_pfm_load_map", packet)
		return mapName
	end

	local session = self:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	if activeClip == nil then
		pfm.log(
			"Unable to load session map: Session has no active clip!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	return self:LoadMap(activeClip:GetMapName())
end
function pfm.ProjectManager:ClearMap()
	pfm.log("Clearing current map...", pfm.LOG_CATEGORY_PFM)
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_MAP) }) do
		local mapC = ent:GetComponent(ents.COMPONENT_MAP)
		if mapC:GetMapIndex() ~= 0 then
			ent:RemoveSafely()
		end
	end
end
function pfm.ProjectManager:GetActiveFilmClipFrameOffset(frameIndex)
	frameIndex = frameIndex or self:GetFrameOffset()
	local project = self:GetProject()
	local filmClip = self:GetActiveGameViewFilmClip()
	if project == nil or filmClip == nil then
		return
	end
	-- Absolute frame index to film clip frame index
	return self:TimeOffsetToFrameOffset(filmClip:LocalizeTimeOffset(self:FrameOffsetToTimeOffset(frameIndex)))
end
function pfm.ProjectManager:GetPerformanceCache()
	return self.m_performanceCache
end
function pfm.ProjectManager:SetGameScene(scene)
	self.m_gameScene = scene
end
function pfm.ProjectManager:GetGameScene()
	return self.m_gameScene
end
function pfm.ProjectManager:MakeProjectPersistent()
	self.m_persistentProject = true
	return {
		fileName = self.m_projectFileName,
		project = self.m_project,
	}
end
function pfm.ProjectManager:RestorePersistentProject(data)
	self:SetProjectFileName(data.fileName)
	self.m_project = data.project
	return util.is_valid(self:InitializeProject(self.m_project))
end
function pfm.ProjectManager:SetProjectFileName(fileName)
	self.m_projectFileName = fileName
	self:OnProjectFileNameChanged(fileName)
end
function pfm.ProjectManager:LoadProject(fileName, ignoreMap)
	local loadAsAscii = (file.get_file_extension(fileName) == pfm.Project.FORMAT_EXTENSION_ASCII)
	fileName = file.remove_file_extension(fileName, pfm.Project.get_format_extensions())
	if loadAsAscii then
		fileName = fileName .. "." .. pfm.Project.FORMAT_EXTENSION_ASCII
	else
		local binFileName = fileName .. "." .. pfm.Project.FORMAT_EXTENSION_BINARY
		if file.exists(binFileName) then
			fileName = binFileName
		else
			fileName = fileName .. "." .. pfm.Project.FORMAT_EXTENSION_ASCII
		end
	end
	self:CloseProject()
	pfm.log("Loading project '" .. fileName .. "'...", pfm.LOG_CATEGORY_PFM)
	local project, err = pfm.load_project(fileName, ignoreMap)
	if project == false then
		pfm.log(
			"Unable to load project '" .. fileName .. "': " .. (err or "Unknown error") .. "!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return self:CreateNewProject()
	end
	local session = project:GetSession()
	if session == nil then
		pfm.log("Unable to initialize project: Project has no session!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		self:CloseProject()
		return self:CreateNewProject()
	end
	self:PrecacheSessionAssets(session)
	if session ~= nil then
		self.m_animationCache = pfm.SceneAnimationCache(session)
	end
	self:SetProjectFileName(fileName)
	self.m_project = project
	-- self:LoadAnimationCache(fileName)
	self:OnProjectLoaded(fileName, project)
	return util.is_valid(self:InitializeProject(project))
end
function pfm.ProjectManager:SaveProject(fileName, newInternalName)
	local project = self:GetProject()
	if project == nil then
		pfm.log(
			"Failed to save project as '" .. fileName .. "': No project to save!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end
	pfm.log("Saving project as '" .. fileName .. "'...", pfm.LOG_CATEGORY_PFM)
	local t = time.time_since_epoch()
	local success = project:Save(fileName, nil)
	if success == false then
		pfm.log("Failed to save project as '" .. fileName .. "'!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return success
	end
	if newInternalName ~= nil then
		self:SetProjectFileName(newInternalName)
		pfm.log("New internal project name: " .. self.m_projectFileName, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_DEBUG)
	end
	-- self:SaveAnimationCache(fileName)
	local dt = time.time_since_epoch() - t
	pfm.log("Saving successful! Saving took " .. util.get_pretty_time(dt / 1000000000.0), pfm.LOG_CATEGORY_PFM)
	return success
end
function pfm.ProjectManager:GetProjectFileName(projectFileName)
	projectFileName = projectFileName or self.m_projectFileName
	if projectFileName == nil then
		return
	end
	return file.to_relative_path(projectFileName)
end
function pfm.ProjectManager:GetProjectUniqueId()
	return self:GetProject():GetUniqueId()
end
function pfm.ProjectManager:GetProjectPath()
	return util.Path.CreatePath(self.m_projectFileName):GetPath()
end
function pfm.ProjectManager:GetAnimationCacheFilePath(projectFileName)
	return "cache/pfm/" .. self:GetProjectUniqueId() .. "/animation.pfac_b"
end
function pfm.ProjectManager:IsAnimationCacheValid()
	return file.exists(self:GetAnimationCacheFilePath())
end
function pfm.ProjectManager:SaveAnimationCache(projectFileName)
	if self.m_animationCache == nil then
		return
	end
	local cacheFileName = self:GetAnimationCacheFilePath(projectFileName)
	file.create_path(file.get_file_path(cacheFileName))
	self.m_animationCache:SaveToBinary(cacheFileName)
end
function pfm.ProjectManager:ClearAnimationCache(projectFileName)
	if self:IsAnimationCacheValid() == false then
		return
	end
	file.delete(self:GetAnimationCacheFilePath())
end
function pfm.ProjectManager:PrecacheSessionAssets(session)
	debug.start_profiling_task("pfm_precache_session_assets")
	pfm.log("Precaching session assets...", pfm.LOG_CATEGORY_PFM)
	local track = session:GetFilmTrack()
	if track ~= nil then
		for _, filmClip in ipairs(track:GetFilmClips()) do
			pfm.log("Precaching assets for film clip '" .. tostring(filmClip) .. "'...", pfm.LOG_CATEGORY_PFM)
			local actors = filmClip:GetActorList()
			for _, actor in ipairs(actors) do
				local component = actor:FindComponent("model")
				if component ~= nil then
					local mdlName =
						asset.normalize_asset_name(component:GetMemberValue("model") or "", asset.TYPE_MODEL)
					if #mdlName > 0 then
						pfm.log(
							"Precaching model '" .. mdlName .. "' for actor '" .. tostring(actor) .. "'...",
							pfm.LOG_CATEGORY_PFM
						)
						if game.precache_model(mdlName) == false then
							pfm.log(
								"Unable to precache model '" .. mdlName .. "'!",
								pfm.LOG_CATEGORY_PFM,
								pfm.LOG_SEVERITY_WARNING
							)
						end
					end
				end
			end
		end
	end
	debug.stop_profiling_task()
end
function pfm.ProjectManager:WaitForSessionAssets(session)
	debug.start_profiling_task("pfm_wait_for_session_assets")
	pfm.log("Waiting for session assets...", pfm.LOG_CATEGORY_PFM)
	local track = session:GetFilmTrack()
	if track ~= nil then
		for _, filmClip in ipairs(track:GetFilmClips()) do
			local actors = filmClip:GetActorList()
			for _, actor in ipairs(actors) do
				local component = actor:FindComponent("model")
				if component ~= nil then
					local mdlName =
						asset.normalize_asset_name(component:GetMemberValue("model") or "", asset.TYPE_MODEL)
					if #mdlName > 0 then
						asset.wait_until_loaded(mdlName, asset.TYPE_MODEL)
					end
				end
			end
		end
	end
	debug.stop_profiling_task()
end
function pfm.ProjectManager:LoadAnimationCache(projectFileName)
	if self.m_animationCacheLoaded then
		return
	end
	self.m_animationCacheLoaded = true
	local cacheFileName = self:GetAnimationCacheFilePath(projectFileName)
	self.m_animationCache:LoadFromBinary(cacheFileName)
end
function pfm.ProjectManager:CreateNewProject()
	self:CloseProject()
	pfm.log("Creating new project...", pfm.LOG_CATEGORY_PFM)
	local project = pfm.create_empty_project()
	local session = project:GetSession()
	if session ~= nil then
		self.m_animationCache = pfm.SceneAnimationCache(session)
	end
	return util.is_valid(self:InitializeProject(project))
end
function pfm.ProjectManager:CloseProject()
	pfm.log("Closing project...", pfm.LOG_CATEGORY_PFM)
	self:ClearGameView()
	self.m_performanceCache:Clear()
	if util.is_valid(self.m_cbPlayOffset) then
		self.m_cbPlayOffset:Remove()
	end
	self.m_activeGameViewFilmClip = nil
	if self.m_animationCache ~= nil then
		self.m_animationCache:Clear()
	end
	self.m_animationCache = nil
	self.m_animationCacheLoaded = false
	self:SetProjectFileName(nil)
	if self.m_project then
		if self.m_persistentProject ~= true then
			self.m_project:Close()
		end
		self.m_project = nil
	end
	pfm.undoredo.clear()
	collectgarbage()
	self:OnProjectClosed()
end
function pfm.ProjectManager:OnProjectLoaded(fileName, project) end
function pfm.ProjectManager:OnProjectClosed() end
function pfm.ProjectManager:ImportSFMProject(projectFilePath)
	self:CloseProject()
	pfm.log("Converting SFM project '" .. projectFilePath .. "' to PFM...", pfm.LOG_CATEGORY_SFM)
	local pfmScene = sfm.ProjectConverter.convert_project(projectFilePath)
	if pfmScene == false then
		pfm.log(
			"Unable to convert SFM project '" .. projectFilePath .. "'!",
			pfm.LOG_CATEGORY_SFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end
	-- self.m_projectFileName = "projects/" .. file.remove_file_extension(projectFilePath) .. ".pfm"
	-- self:ClearAnimationCache()
	-- local session = pfmScene:GetSession()
	-- if(session ~= nil) then self.m_animationCache = pfm.SceneAnimationCache(session) end
	return util.is_valid(self:InitializeProject(pfmScene))
end
function pfm.ProjectManager:SetTimeOffset(offset)
	local session = self:GetSession()
	if session == nil then
		return
	end
	local settings = session:GetSettings()
	settings:SetPlayheadOffset(offset)
	self.m_animManager:SetTime(offset)
end
function pfm.ProjectManager:GetSettings()
	local session = self:GetSession()
	if session == nil then
		return
	end
	return session:GetSettings()
end
function pfm.ProjectManager:GetProject()
	return self.m_project
end
function pfm.ProjectManager:OnFilmClipAdded(el) end
function pfm.ProjectManager:GetAnimationCache()
	return self.m_animationCache
end
function pfm.ProjectManager:InitializeProject(project)
	pfm.log("Initializing PFM project...", pfm.LOG_CATEGORY_PFM)
	debug.start_profiling_task("pfm_initialize_project")

	self.m_animManager:Reset()
	pfm.undoredo.clear()
	local session = self:GetSession()
	local filmTrack = (session ~= nil) and session:GetFilmTrack() or nil

	if session ~= nil then
		self:WaitForSessionAssets(session)
	end
	local entScene = self:StartGameView(project)
	if entScene == nil then
		debug.stop_profiling_task()
		return false
	end
	local projectC = entScene:GetComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:AddEventCallback(ents.PFMProject.EVENT_ON_FILM_CLIP_CREATED, function(filmClipC)
		self.m_activeGameViewFilmClip = filmClipC:GetClipData()
		self.m_animManager:SetFilmClip(self.m_activeGameViewFilmClip)
		self:OnGameViewFilmClipChanged(filmClipC:GetClipData())
	end)
	self.m_project = project

	-- We want the frame offset to start at 0, but the default value is already 0, which means the
	-- callbacks would not get triggered properly. To fix that, we'll just set it to some random value != 0
	-- before actually setting it to 0 further below.
	self:SetTimeOffset(1.0)
	local session = self:GetSession()
	if session ~= nil then
		local filmTrack = session:GetFilmTrack()
		if filmTrack ~= nil then
			self.m_animManager:Initialize(filmTrack)
			--[[filmTrack:GetFilmClipsAttr():AddChangeListener(function(newEl)
				self:OnFilmClipAdded(newEl)
				self:ReloadGameView() -- TODO: We don't really need to refresh the entire game view, just the current film clip would be sufficient.
			end)]]
		end
		self.m_cbPlayOffset = session:GetSettings():AddChangeListener("playheadOffset", function(settings, newOffset)
			self:SetGameViewOffset(newOffset)
			self:OnTimeOffsetChanged(newOffset)
		end)
	end
	-- self:CacheAnimations()
	self:OnProjectInitialized(project)
	debug.stop_profiling_task()
	return entScene
end
function pfm.ProjectManager:CacheAnimations()
	if console.get_convar_bool("pfm_animation_cache_enabled") == false or self.m_projectFileName == nil then
		return
	end
	if self:IsAnimationCacheValid() then
		self:LoadAnimationCache()
	end
	local hasDirtyFrame = false
	local firstFrame, lastFrame = self:GetFrameIndexRange()
	for i = firstFrame, lastFrame do
		if self.m_animationCache:IsFrameDirty(i) then
			self:GoToFrame(i)
			hasDirtyFrame = true
		end
	end
	if hasDirtyFrame == false then
		return
	end
	self:SaveAnimationCache()
end
function pfm.ProjectManager:OnTimeOffsetChanged(offset) end
function pfm.ProjectManager:SetCachedMode(useCache)
	self.m_cachedMode = useCache
end
function pfm.ProjectManager:IsCachedMode()
	return self.m_cachedMode
end
function pfm.ProjectManager:GetActiveGameViewFilmClip()
	return self.m_activeGameViewFilmClip
end
function pfm.ProjectManager:SetGameViewOffset(offset)
	local tOffset = self:TranslateGameViewOffset(offset)
	if tOffset == false or util.is_valid(self:GetGameView()) == false then
		return
	end
	offset = tOffset or offset
	local isAnimCacheEnabled = false --console.get_convar_bool("pfm_animation_cache_enabled")
	local frameIndex = self:TimeOffsetToFrameOffset(offset)
	local isInterpFrame = (math.round(frameIndex) - frameIndex >= 0.001) -- If we're not exactly at a frame, we'll have to interpolate (and can't save to the cache)
	if isInterpFrame == false then
		frameIndex = math.round(frameIndex)
	end

	local updateCache = isAnimCacheEnabled and isInterpFrame == false and self.m_animationCache:IsFrameDirty(frameIndex)
	local session = self:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	local gameViewFlags = ents.PFMProject.GAME_VIEW_FLAG_NONE
	if activeClip ~= nil then
		local filter
		if
			isAnimCacheEnabled
			and self.m_animationCache:IsFrameDirty(math.floor(frameIndex)) == false
			and (isInterpFrame == false or self.m_animationCache:IsFrameDirty(math.ceil(frameIndex)) == false)
		then
			gameViewFlags = bit.bor(gameViewFlags, ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE)
			filter = function(channel)
				return channel:IsBoneTransformChannel() == false and channel:IsFlexControllerChannel() == false
			end
		end
		local curFilmClip = activeClip:GetChildFilmClip(offset)
		if util.is_same_object(curFilmClip, self.m_activeGameViewFilmClip) == false then
			--self.m_activeGameViewFilmClip = curFilmClip
			--self:OnGameViewFilmClipChanged(curFilmClip)
		end
		-- if(self.m_cachedMode == false or updateCache) then activeClip:SetPlaybackOffset(offset,filter)
		-- elseif(self.m_activeGameViewFilmClip ~= nil) then self.m_performanceCache:SetOffset(self.m_activeGameViewFilmClip,offset) end
	else
		self.m_activeGameViewFilmClip = nil
	end

	pfm.GameView.SetGameViewOffset(self, offset, gameViewFlags)

	if updateCache then
		self.m_animationCache:UpdateCache(math.round(frameIndex))
	end
end
function pfm.ProjectManager:GetSession()
	local project = self:GetProject()
	return (project ~= nil) and project:GetSession() or nil
end
function pfm.ProjectManager:GetFrameRate()
	local session = self:GetSession()
	return (session ~= nil) and session:GetFrameRate() or 24
end
function pfm.ProjectManager:GetTimeOffset()
	local session = self:GetSession()
	if session == nil then
		return 0.0
	end
	local settings = session:GetSettings()
	return settings:GetPlayheadOffset()
end
function pfm.ProjectManager:GetTimeFrameFrameIndexRange(timeFrame)
	return self:GetClampedFrameOffset(self:TimeOffsetToFrameOffset(timeFrame:GetStart())),
		self:GetClampedFrameOffset(self:TimeOffsetToFrameOffset(timeFrame:GetEnd()))
end
function pfm.ProjectManager:GetLastFrameIndex()
	local lastFrame = self:GetSession():GetLastFrameIndex()
	lastFrame = self:GetClampedFrameOffset(lastFrame)
	return lastFrame
end
function pfm.ProjectManager:GetFrameCount()
	return self:GetLastFrameIndex() + 1
end
function pfm.ProjectManager:GetFrameIndexRange()
	return self:GetSession():GetFrameIndexRange()
end
function pfm.ProjectManager:TimeOffsetToFrameOffset(offset)
	return offset * self:GetFrameRate()
end
function pfm.ProjectManager:FrameOffsetToTimeOffset(offset)
	return offset / self:GetFrameRate()
end
function pfm.ProjectManager:SetFrameOffset(frame)
	self:SetTimeOffset(self:FrameOffsetToTimeOffset(self:GetClampedFrameOffset(frame)))
end
function pfm.ProjectManager:GetFrameOffset()
	return self:TimeOffsetToFrameOffset(self:GetTimeOffset())
end
function pfm.ProjectManager:GetClampedFrameOffset(frame)
	return math.round(frame or self:GetFrameOffset())
end
function pfm.ProjectManager:ClampTimeOffsetToFrame()
	self:SetFrameOffset(self:GetClampedFrameOffset())
end
function pfm.ProjectManager:GetPlayheadClip()
	local filmTrack = self:GetSession():GetFilmTrack()
	local filmClips = filmTrack:GetFilmClips()
	local offset = self:GetTimeOffset()
	if #filmClips == 0 then
		return
	end
	for i, filmClipData in ipairs(filmClips) do
		local timeFrame = filmClipData:GetTimeFrame()
		if timeFrame:IsInTimeFrame(offset, 0.001) then
			return filmClipData
		end
	end
end
function pfm.ProjectManager:GetPlayheadClipRange()
	local clip = self:GetPlayheadClip()
	if clip == nil then
		return
	end
	return self:TimeOffsetToFrameOffset(clip:GetTimeFrame():GetStart()),
		self:TimeOffsetToFrameOffset(clip:GetTimeFrame():GetEnd())
end
function pfm.ProjectManager:GoToFrame(frame)
	self:SetFrameOffset(frame)
end
function pfm.ProjectManager:GoToNextFrame()
	self:SetFrameOffset(self:GetClampedFrameOffset() + 1)
end
function pfm.ProjectManager:GoToPreviousFrame()
	self:SetFrameOffset(self:GetClampedFrameOffset() - 1)
end
function pfm.ProjectManager:GoToFirstFrame()
	local session = self:GetSession()
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	if filmClip == nil then
		return
	end
	local timeFrame = filmClip:GetTimeFrame()
	self:SetFrameOffset(self:TimeOffsetToFrameOffset(timeFrame:GetStart()))
end
function pfm.ProjectManager:GoToPreviousClip()
	local filmTrack = self:GetSession():GetFilmTrack()
	local filmClips = filmTrack:GetFilmClips()
	local offset = self:GetTimeOffset()
	if #filmClips == 0 then
		return
	end
	for i, filmClipData in ipairs(filmClips) do
		local timeFrame = filmClipData:GetTimeFrame()
		if timeFrame:IsInTimeFrame(offset, 0.001) then
			if i > 1 then
				local filmClipPrev = filmClips[i - 1]
				self:SetFrameOffset(self:TimeOffsetToFrameOffset(filmClipPrev:GetTimeFrame():GetEnd()))
				return
			end
			-- There is no previous clip, just jump to start of this one
			self:SetFrameOffset(self:TimeOffsetToFrameOffset(filmClipData:GetTimeFrame():GetStart()))
			return
		end
	end
	-- Current offset must be either before first clip or after last clip, so we'll
	-- just clamp it to whichever it is.
	local firstTimeFrame = filmClips[1]:GetTimeFrame()
	local lastTimeFrame = filmClips[#filmClips]:GetTimeFrame()
	local newOffset = (offset < firstTimeFrame:GetStart()) and firstTimeFrame:GetStart() or lastTimeFrame:GetEnd()
	self:SetFrameOffset(self:TimeOffsetToFrameOffset(newOffset))
end
function pfm.ProjectManager:GoToNextClip()
	local filmTrack = self:GetSession():GetFilmTrack()
	local filmClips = filmTrack:GetFilmClips()
	local offset = self:GetTimeOffset()
	if #filmClips == 0 then
		return
	end
	for i = #filmClips, 1, -1 do
		local filmClipData = filmClips[i]
		local timeFrame = filmClipData:GetTimeFrame()
		if timeFrame:IsInTimeFrame(offset, 0.001) then
			if i < #filmClips then
				local filmClipNext = filmClips[i + 1]
				self:SetFrameOffset(self:TimeOffsetToFrameOffset(filmClipNext:GetTimeFrame():GetStart()))
				return
			end
			-- There is no next clip, just jump to end of this one
			self:SetFrameOffset(self:TimeOffsetToFrameOffset(filmClipData:GetTimeFrame():GetEnd()))
			return
		end
	end
	-- Current offset must be either before first clip or after last clip, so we'll
	-- just clamp it to whichever it is.
	local firstTimeFrame = filmClips[1]:GetTimeFrame()
	local lastTimeFrame = filmClips[#filmClips]:GetTimeFrame()
	local newOffset = (offset < firstTimeFrame:GetStart()) and firstTimeFrame:GetStart() or lastTimeFrame:GetEnd()
	self:SetFrameOffset(self:TimeOffsetToFrameOffset(newOffset))
end
function pfm.ProjectManager:GoToLastFrame()
	local session = self:GetSession()
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	if filmClip == nil then
		return
	end
	local timeFrame = filmClip:GetTimeFrame()
	self:SetFrameOffset(self:TimeOffsetToFrameOffset(timeFrame:GetEnd()))
end

-- These can be overriden by derived classes
function pfm.ProjectManager:OnProjectInitialized(project) end
function pfm.ProjectManager:OnGameViewFilmClipChanged(filmClip) end
function pfm.ProjectManager:TranslateGameViewOffset(offset)
	return offset
end
function pfm.ProjectManager:OnProjectFileNameChanged(projectFileName) end

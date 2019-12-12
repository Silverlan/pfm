--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../base_editor.lua")

util.register_class("gui.WIFilmmaker",gui.WIBaseEditor)

include("/gui/vbox.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/gui/filmstrip.lua")
include("/gui/genericclip.lua")
include("/gui/witabbedpanel.lua")
include("/gui/editors/wieditorwindow.lua")
include("/gui/pfm/frame.lua")
include("/gui/pfm/viewport.lua")
include("/gui/pfm/timeline.lua")
include("/gui/pfm/elementviewer.lua")
include("/gui/pfm/actoreditor.lua")
include("/gui/pfm/renderpreview.lua")

gui.load_skin("pfm")
locale.load("pfm_user_interface.txt")

include("windows")
include("video_recorder.lua")

include_component("pfm_camera")
include_component("pfm_sound_source")

function gui.WIFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
end
function gui.WIFilmmaker:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)

	self:EnableThinking()
	self:SetSize(1280,1024)
	self:SetSkin("pfm")
	local pMenuBar = self:GetMenuBar()
	self.m_menuBar = pMenuBar

	pMenuBar:AddItem(locale.get_text("file"),function(pContext)
		pContext:AddItem(locale.get_text("open") .. "...",function(pItem)
			if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
			self.m_openDialogue = gui.create_file_open_dialog(function(pDialog,fileName)
				self:LoadProject(fileName)
			end)
			self.m_openDialogue:SetRootPath("sfm_sessions")
			self.m_openDialogue:SetExtensions({"dmx"})
			self.m_openDialogue:Update()
		end)
		pContext:AddItem(locale.get_text("import") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			
		end)
		pContext:AddItem(locale.get_text("save") .. "...",function(pItem)
			if(util.is_valid(self) == false) then return end
			
		end)
		pContext:AddItem(locale.get_text("exit"),function(pItem)
			if(util.is_valid(self) == false) then return end
			tool.close_filmmaker()
		end)
		pContext:Update()
	end)
	pMenuBar:AddItem(locale.get_text("edit"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("windows"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("view"),function(pContext)

	end)
	pMenuBar:AddItem(locale.get_text("help"),function(pContext)

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

	self:ClearProjectUI()
	self:CreateNewProject()
end
function gui.WIFilmmaker:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
end
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
	local img = vulkan.create_image(imgBuffer)
	local imgViewCreateInfo = vulkan.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = vulkan.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local tex = vulkan.create_texture(img,vulkan.TextureCreateInfo(),imgViewCreateInfo,vulkan.SamplerCreateInfo())
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
	if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
	if(self.m_previewWindow ~= nil) then self.m_previewWindow:Remove() end
	if(self.m_renderResultWindow ~= nil) then self.m_renderResultWindow:Remove() end
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
function gui.WIFilmmaker:CloseProject()
	pfm.log("Closing project...",pfm.LOG_CATEGORY_PFM)
	if(util.is_valid(self.m_gameView)) then self.m_gameView:Remove() end
end
function gui.WIFilmmaker:GetGameView() return self.m_gameView end
function gui.WIFilmmaker:InitializeProject(project)
	pfm.log("Initializing PFM project...",pfm.LOG_CATEGORY_PFM)
	local entScene = ents.create("pfm_project")
	if(util.is_valid(entScene) == false) then
		pfm.log("Unable to initialize PFM project: Count not create 'pfm_project' entity!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end

	self.m_project = project
	local projectC = entScene:GetComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(self.m_project)
	entScene:Spawn()
	self.m_gameView = entScene
	projectC:Start()
	if(util.is_valid(self.m_playbackControls)) then
		local timeFrame = projectC:GetTimeFrame()
		self.m_playbackControls:SetDuration(timeFrame:GetDuration())
		self.m_playbackControls:SetOffset(0.0)
	end
	self:InitializeProjectUI()
	return entScene
end
function gui.WIFilmmaker:CreateNewProject()
	self:CloseProject()
	pfm.log("Creating new project...",pfm.LOG_CATEGORY_PFM)
	return self:InitializeProject(pfm.create_project())
end
function gui.WIFilmmaker:LoadProject(projectFilePath)
	self:CloseProject()
	pfm.log("Converting SFM project '" .. projectFilePath .. "' to PFM...",pfm.LOG_CATEGORY_SFM)
	local pfmScene = sfm.ProjectConverter.convert_project(projectFilePath)
	if(pfmScene == false) then
		pfm.log("Unable to convert SFM project '" .. projectFilePath .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	return self:InitializeProject(pfmScene)
end
function gui.WIFilmmaker:ClearProjectUI()
	if(util.is_valid(self.m_contents)) then self.m_contents:Remove() end
	self.m_frames = {}
end
function gui.WIFilmmaker:InitializeProjectUI()
	self:ClearProjectUI()
	if(util.is_valid(self.m_menuBar) == false) then return end
	self.m_contents = gui.create("WIHBox",self,0,self.m_menuBar:GetHeight(),self:GetWidth(),self:GetHeight() -self.m_menuBar:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	local actorDataFrame = self:AddFrame(self.m_contents)
	local actorEditor = gui.create("WIPFMActorEditor")
	actorDataFrame:AddTab(locale.get_text("pfm_actor_editor"),actorEditor)
	self.m_actorEditor = actorEditor -- TODO Determine dynamically

	local elementViewer = gui.create("WIPFMElementViewer")
	actorDataFrame:AddTab(locale.get_text("pfm_element_viewer"),elementViewer)
	
	gui.create("WIResizer",self.m_contents)

	self.m_contentsRight = gui.create("WIVBox",self.m_contents)
	self.m_contents:Update()
	self.m_contentsRight:SetAutoFillContents(true)

	local viewportFrame = self:AddFrame(self.m_contentsRight)
	viewportFrame:SetHeight(self:GetHeight())
	local viewport = gui.create("WIPFMViewport")
	viewportFrame:AddTab(locale.get_text("pfm_primary_viewport"),viewport)

	local renderPreview = gui.create("WIPFMRenderPreview")
	viewportFrame:AddTab(locale.get_text("pfm_render_result"),renderPreview)

	gui.create("WIResizer",self.m_contentsRight)

	local timelineFrame = self:AddFrame(self.m_contentsRight)
	local pfmTimeline = gui.create("WIPFMTimeline")
	timelineFrame:AddTab(locale.get_text("pfm_timeline"),pfmTimeline)

	-- Populate UI with project data
	local project = self:GetProject()
	local root = project:GetUDMRootNode()
	elementViewer:Setup(root)

	local playhead = pfmTimeline:GetPlayhead()
	playhead:GetTimeOffsetProperty():AddCallback(function(oldOffset,offset)
		local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
		if(projectC ~= nil) then projectC:SetOffset(offset) end
		local session = project:GetSessions()[1]
		local activeClip = (session ~= nil) and session:GetActiveClip() or nil
		if(activeClip == nil) then return end
		activeClip:SetPlaybackOffset(offset)

		if(viewport:IsValid()) then
			viewport:SetGlobalTime(offset)

			local childClip = activeClip:GetChildFilmClip(offset)
			if(childClip ~= nil) then
				viewport:SetLocalTime(childClip:GetTimeFrame():LocalizeOffset(offset))
				viewport:SetFilmClipName(childClip:GetName())
				viewport:SetFilmClipParentName(activeClip:GetName())
			end
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
	end)

	-- Film strip
	local session = project:GetSessions()[1]
	local filmClip = (session ~= nil) and session:GetActiveClip() or nil
	local filmStrip
	if(filmClip ~= nil) then
		local timeline = pfmTimeline:GetTimeline()

		filmStrip = gui.create("WIFilmStrip")
		filmStrip:SetScrollInputEnabled(true)
		filmStrip:AddCallback("OnScroll",function(el,x,y)
			if(timeline:IsValid()) then
				timeline:SetStartOffset(timeline:GetStartOffset() -y *timeline:GetZoomLevelMultiplier())
				timeline:Update()
				return util.EVENT_REPLY_HANDLED
			end
			return util.EVENT_REPLY_UNHANDLED
		end)

		local trackGroup = filmClip:FindElementsByName("subClipTrackGroup")[1]
		local trackFilm = trackGroup:FindElementsByName("Film")[1]
		if(trackFilm ~= nil) then
			for _,filmClip in ipairs(trackFilm:GetFilmClips():GetTable()) do
				filmStrip:AddFilmClip(filmClip,function(elFilmClip)
					local filmClipData = elFilmClip:GetFilmClipData()
					if(util.is_valid(self.m_actorEditor)) then
						self.m_actorEditor:Setup(filmClipData)
					end
				end)
				if(_ == 1) then
					-- TODO: For debugging only!
					self.m_actorEditor:Setup(filmClip)
				end
			end
		end
		filmStrip:SetSize(1024,64)
		filmStrip:Update()

		local timeFrame = filmStrip:GetTimeFrame()

		local pfmClipEditor = pfmTimeline:GetEditorTimelineElement(gui.PFMTimeline.EDITOR_CLIP)
		local groupPicture = pfmClipEditor:AddTrackGroup("Picture")
		if(filmStrip ~= nil) then
			for _,filmClip in ipairs(filmStrip:GetFilmClips()) do
				timeline:AddTimelineItem(filmClip,filmClip:GetTimeFrame())
			end
		end
		groupPicture:AddElement(filmStrip)

		local groupSound = pfmClipEditor:AddTrackGroup("Sound")
		local trackGroupSound = filmClip:GetTrackGroups():FindElementsByName("Sound")[1]
		if(trackGroupSound ~= nil) then
			for _,track in ipairs(trackGroupSound:GetTracks():GetTable()) do
				if(track:GetName() == "Music") then
					local subGroup = groupSound:AddGroup(track:GetName())
					timeline:AddTimelineItem(subGroup,timeFrame)

					--[[for _,audioClip in ipairs(track:GetAudioClips():GetTable()) do
						local groupClip = gui.create("WIGenericClip")
						subGroup:AddElement(groupClip)
						groupClip:SetText(audioClip:GetName())

						timeline:AddTimelineItem(groupClip,audioClip:GetTimeFrame())
					end]]
				end
			end
			--print(util.get_type_name(trackSound))
			--[[for _,audioClip in ipairs(trackSound:GetAudioClips():GetTable()) do
				print("AUDIO CLIP: ",audioClip:GetName())
			end]]
		end

		-- TODO: Same as for 'Sound'
		--[[local groupOverlay = pfmClipEditor:AddTrackGroup("Overlay")

		local activeBookmarkSet = filmClip:GetActiveBookmarkSet()
		local bookmarkSet = filmClip:GetBookmarkSets():Get(activeBookmarkSet +1)
		if(bookmarkSet ~= nil) then
			for _,bookmark in ipairs(bookmarkSet:GetBookmarks():GetTable()) do
				timeline:AddBookmark(bookmark)
			end
		end]]
	end
end
function gui.WIFilmmaker:GetProject() return self.m_project end
gui.register("WIFilmmaker",gui.WIFilmmaker)

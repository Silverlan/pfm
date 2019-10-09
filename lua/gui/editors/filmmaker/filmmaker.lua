--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../base_editor.lua")

util.register_class("gui.WIFilmmaker",gui.WIBaseEditor)

include("/gui/witabbedpanel.lua")
include("/gui/editors/wieditorwindow.lua")

locale.load("pfm_user_interface.txt")

include("windows")



pfm.register_log_category("video_recorder")
util.register_class("pfm.VideoRecorder")
function pfm.VideoRecorder:__init()
	self.m_frameIndex = 0
	self.m_frameRate = 5--60
	self.m_fileName = ""

	-- 4k
	-- TODO!
	self.m_width = 1024--3840
	self.m_height = 1024--2160
end
function pfm.VideoRecorder:WriteFrame(imgBuffer)
	if(self:IsRecording() == false) then return false end
	local timeStamp = self.m_frameIndex *self:GetFrameDeltaTime()

	pfm.log("Writing frame " .. self.m_frameIndex .. " at timestamp " .. timeStamp .. "...",pfm.LOG_CATEGORY_VIDEO_RECORDER)
	self.m_videoRecorder:WriteFrame(imgBuffer,timeStamp)

	self.m_frameIndex = self.m_frameIndex +1
	return true
end
function pfm.VideoRecorder:IsRecording() return self.m_videoRecorder ~= nil end
function pfm.VideoRecorder:GetFrameDeltaTime() return (1.0 /self.m_frameRate) end
function pfm.VideoRecorder:StartRecording(fileName)
	if(self:IsRecording()) then
		pfm.log("Unable to start recording: Recording already in progress!",pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local r = engine.load_library("video_recorder/pr_video_recorder")
	if(r ~= true) then
		pfm.log("Unable to load video recorder module: " .. r,pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local renderResolution = math.Vector2i(self.m_width,self.m_height) -- 4K
	local encodingSettings = media.VideoRecorder.EncodingSettings()
	encodingSettings.width = renderResolution.x
	encodingSettings.height = renderResolution.y
	encodingSettings.frameRate = self.m_frameRate
	encodingSettings.quality = media.QUALITY_VERY_HIGH
	encodingSettings.format = media.VIDEO_FORMAT_AVI
	encodingSettings.codec = media.VIDEO_CODEC_H264
	
	local videoRecorder = media.create_video_recorder()
	if(videoRecorder == nil) then
		pfm.log("Unable to initialize video recorder!",pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local success,errMsg = videoRecorder:StartRecording(fileName,encodingSettings)
	if(success == false) then
		pfm.log("Unable to start recording: " .. errMsg,pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	self.m_frameIndex = 0
	self.m_videoRecorder = videoRecorder
	self.m_fileName = fileName

	pfm.log("Starting video recording '" .. fileName .. "'...")
	return true
end
function pfm.VideoRecorder:StopRecording()
	if(self:IsRecording() == false) then
		pfm.log("Unable to end recording: No recording session has been started!",pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local b,errMsg = self.m_videoRecorder:EndRecording()
	if(b == false) then
		pfm.log("Unable to end recording: " .. errMsg,pfm.LOG_CATEGORY_VIDEO_RECORDER,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	pfm.log("Recording complete! Video has been saved as '" .. self.m_fileName .. "'.",pfm.LOG_CATEGORY_VIDEO_RECORDER)
	-- TODO
		--util.get_pretty_duration((time.real_time() -recordData.tStart) *1000.0,nil,true)
		--[[print("Recording complete! Recorded " .. (time.real_time() -recordData.tStart))
		print("Number of frames rendered: ",recordData.numFramesExpected)
		print("Number of frames written: ",recordData.numFramesWritten)
		print("Encoding duration: ",encodingDuration,",",recordData.tEncoding /1000000000.0)]]

	self.m_videoRecorder = nil
	return true
end










function gui.WIFilmmaker:__init()
	gui.WIBaseEditor.__init(self)
end
function gui.WIFilmmaker:OnRemove()
	gui.WIBaseEditor.OnRemove(self)
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
	local tex = vulkan.create_texture(img,vulkan.TextureCreateInfo(),vulkan.ImageViewCreateInfo(),vulkan.SamplerCreateInfo())
	if(self.m_renderResultWindow ~= nil) then self.m_renderResultWindow:SetTexture(tex) end
	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetVisible(false) end

	self.m_raytracingJob = nil
	if(self:IsRecording() == false) then return end
	-- Write the rendered frame and kick off the next one
	self.m_videoRecorder:WriteFrame(imgBuffer)

	local scene = self:GetScene()
	local sceneC = util.is_valid(scene) and scene:GetComponent(ents.COMPONENT_PFM_SCENE) or nil
	if(sceneC ~= nil) then
		sceneC:SetOffset(sceneC:GetOffset() +self.m_videoRecorder:GetFrameDeltaTime())
		self:CaptureRaytracedImage()
	end
end
function gui.WIFilmmaker:OnInitialize()
	gui.WIBaseEditor.OnInitialize(self)
	
	if(util.is_valid(self.m_pMain)) then self.m_pMain:SetVisible(false) end
	self:SetSize(1280,1024)
	local pMenuBar = self:GetMenuBar()
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

	local framePlaybackControls = gui.create("WIFrame",self)
	local playbackControls = gui.create("PlaybackControls",framePlaybackControls)
	playbackControls:SetX(10)
	playbackControls:SetY(24)
	playbackControls:SetWidth(512)
	playbackControls:AddCallback("OnProgressChanged",function(playbackControls,progress,timeOffset)
		if(util.is_valid(self.m_scene)) then
			local sceneC = self.m_scene:GetComponent(ents.COMPONENT_PFM_SCENE)
			if(sceneC ~= nil) then sceneC:SetOffset(timeOffset) end
		end
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
	
	-- This controls the behavior that allows controlling the camera while holding the right mouse button down
	self.m_cbClickMouseInput = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
		if(mouseButton ~= input.MOUSE_BUTTON_LEFT and mouseButton ~= input.MOUSE_BUTTON_RIGHT) then return util.EVENT_REPLY_UNHANDLED end
		if(state ~= input.STATE_PRESS and state ~= input.STATE_RELEASE) then return util.EVENT_REPLY_UNHANDLED end

		local pFrame = self
		if(self.m_inCameraControlMode and mouseButton == input.MOUSE_BUTTON_RIGHT and state == input.STATE_RELEASE and pFrame:IsValid() and pFrame:HasFocus() == false) then
			pFrame:TrapFocus(true)
			pFrame:RequestFocus()
			input.set_cursor_pos(self.m_oldCursorPos)
			self.m_inCameraControlMode = false
			return util.EVENT_REPLY_HANDLED
		end

		local el = gui.get_element_under_cursor()
		if(util.is_valid(el) and (el == self or el == gui.get_base_element())) then
			local action
			if(mouseButton == input.MOUSE_BUTTON_LEFT) then action = input.ACTION_ATTACK
			else action = input.ACTION_ATTACK2 end

			local pFrame = self
			if(mouseButton == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
				self.m_oldCursorPos = input.get_cursor_pos()
				input.center_cursor()
				pFrame:TrapFocus(false)
				pFrame:KillFocus()
				self.m_inCameraControlMode = true
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	self.m_previewWindow = gui.PFMRenderPreviewWindow(self)
	self.m_renderResultWindow = gui.PFMRenderResultWindow(self)
	self.m_videoRecorder = pfm.VideoRecorder()

	self:CreateNewProject()
end
function gui.WIFilmmaker:OnRemove()
	self:CloseProject()
	if(util.is_valid(self.m_cbClickMouseInput)) then self.m_cbClickMouseInput:Remove() end
	if(util.is_valid(self.m_openDialogue)) then self.m_openDialogue:Remove() end
	if(self.m_previewWindow ~= nil) then self.m_previewWindow:Remove() end
	if(self.m_renderResultWindow ~= nil) then self.m_renderResultWindow:Remove() end
end
function gui.WIFilmmaker:CaptureRaytracedImage()
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	local job = util.capture_raytraced_screenshot(1024,1024,64)--2048,2048,1024)
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
	if(util.is_valid(self.m_scene)) then self.m_scene:Remove() end
end
function gui.WIFilmmaker:GetScene() return self.m_scene end
function gui.WIFilmmaker:CreateNewProject()
	self:CloseProject()
	pfm.log("Creating new project...",pfm.LOG_CATEGORY_PFM)

	local entScene = ents.create("pfm_scene")
	if(util.is_valid(entScene) == false) then
		pfm.log("Unable to initialize PFM scene: Count not create 'pfm_scene' entity!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local sceneC = entScene:GetComponent(ents.COMPONENT_PFM_SCENE)
	sceneC:SetScene(pfm.create_scene())
	entScene:Spawn()
	self.m_scene = entScene
	sceneC:Start()
	if(util.is_valid(self.m_playbackControls)) then self.m_playbackControls:SetDuration(0.0) end
	return entScene
end
function gui.WIFilmmaker:LoadProject(projectFilePath)
	self:CloseProject()
	pfm.log("Converting SFM project '" .. projectFilePath .. "' to PFM...",pfm.LOG_CATEGORY_SFM)
	local pfmScene = sfm.ProjectConverter.convert_project(projectFilePath)
	if(pfmScene == false) then
		pfm.log("Unable to convert SFM project '" .. projectFilePath .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	pfm.log("Initializing PFM scene...",pfm.LOG_CATEGORY_PFM)
	local entScene = ents.create("pfm_scene")
	if(util.is_valid(entScene) == false) then
		pfm.log("Unable to initialize PFM scene: Count not create 'pfm_scene' entity!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local sceneC = entScene:GetComponent(ents.COMPONENT_PFM_SCENE)
	sceneC:SetScene(pfmScene)
	entScene:Spawn()
	self.m_scene = entScene
	sceneC:Start()
	if(util.is_valid(self.m_playbackControls)) then
		local timeFrame = sceneC:GetTrackTimeFrame()
		self.m_playbackControls:SetDuration(timeFrame:GetDuration())
	end
	return entScene
end
gui.register("WIFilmmaker",gui.WIFilmmaker)

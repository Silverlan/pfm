--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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


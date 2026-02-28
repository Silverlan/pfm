-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm.register_log_category("video_recorder")
util.register_class("pfm.VideoRecorder")
function pfm.VideoRecorder:__init()
	self.m_frameIndex = 0
	self.m_frameRate = 5 --60
	self.m_fileName = ""

	-- 4k
	-- TODO!
	self.m_width = 1024 --3840
	self.m_height = 1024 --2160
end
function pfm.VideoRecorder:WriteFrame(imgBuffer)
	if self:IsRecording() == false then
		return false
	end
	local timeStamp = self.m_frameIndex * self:GetFrameDeltaTime()

	self:LogInfo("Writing frame " .. self.m_frameIndex .. " at timestamp " .. timeStamp .. "...")
	self.m_videoRecorder:WriteFrame(imgBuffer, timeStamp)

	self.m_frameIndex = self.m_frameIndex + 1
	return true
end
function pfm.VideoRecorder:IsRecording()
	return self.m_videoRecorder ~= nil
end
function pfm.VideoRecorder:GetFrameDeltaTime()
	return (1.0 / self.m_frameRate)
end
function pfm.VideoRecorder:StartRecording(fileName)
	if self:IsRecording() then
		self:LogWarn("Unable to start recording: Recording already in progress!")
		return false
	end
	local r = engine.load_library("video_recorder/pr_video_recorder")
	if r ~= true then
		self:LogWarn("Unable to load video recorder module: " .. r)
		return false
	end

	local renderResolution = math.Vector2i(self.m_width, self.m_height) -- 4K
	local encodingSettings = media.VideoRecorder.EncodingSettings()
	encodingSettings.width = renderResolution.x
	encodingSettings.height = renderResolution.y
	encodingSettings.frameRate = self.m_frameRate
	encodingSettings.quality = media.QUALITY_VERY_HIGH
	encodingSettings.format = media.VIDEO_FORMAT_AVI
	encodingSettings.codec = media.VIDEO_CODEC_H264

	local videoRecorder = media.create_video_recorder()
	if videoRecorder == nil then
		self:LogWarn("Unable to initialize video recorder!")
		return false
	end
	local success, errMsg = videoRecorder:StartRecording(fileName, encodingSettings)
	if success == false then
		self:LogWarn("Unable to start recording: " .. errMsg)
		return false
	end
	self.m_frameIndex = 0
	self.m_videoRecorder = videoRecorder
	self.m_fileName = fileName

	self:LogInfo("Starting video recording '" .. fileName .. "'...")
	return true
end
function pfm.VideoRecorder:StopRecording()
	if self:IsRecording() == false then
		self:LogWarn("Unable to end recording: No recording session has been started!")
		return false
	end

	local b, errMsg = self.m_videoRecorder:EndRecording()
	if b == false then
		self:LogWarn("Unable to end recording: " .. errMsg)
		return false
	end
	self:LogInfo("Recording complete! Video has been saved as '" .. self.m_fileName .. "'.")
	-- TODO
	--util.get_pretty_duration((time.real_time() -recordData.tStart) *1000.0,nil,true)
	--[[print("Recording complete! Recorded " .. (time.real_time() -recordData.tStart))
		print("Number of frames rendered: ",recordData.numFramesExpected)
		print("Number of frames written: ",recordData.numFramesWritten)
		print("Encoding duration: ",encodingDuration,",",recordData.tEncoding /1000000000.0)]]

	self.m_videoRecorder = nil
	return true
end

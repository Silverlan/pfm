--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.ImageRecorder")
function pfm.ImageRecorder:__init(tool)
	self.m_tool = tool
	self.m_frameIndex = 0
	self.m_frameRate = 60
	self.m_fileName = ""
	self.m_recording = false
	self.m_threadPool = util.ThreadPool(10)
end
function pfm.ImageRecorder:__finalize()
	self:StopRecording()
end
function pfm.ImageRecorder:IsRecording() return self.m_recording end
function pfm.ImageRecorder:GetFrameDeltaTime() return (1.0 /self.m_frameRate) end
function pfm.ImageRecorder:RenderNextFrame()
	if(util.is_valid(self.m_tool) == false) then return end
	local vp = self.m_tool:GetViewportElement()
	if(util.is_valid(vp) == false) then return end
	local scene = vp:GetScene()
	local renderer = scene:GetRenderer()

	local tex = renderer:GetPresentationTexture()
	local img = tex:GetImage()
	local frameRate = self.m_frameRate
	local tMax = self.m_tool:GetFrameCount() /self.m_tool:GetFrameRate()
	local frameCount = tMax *frameRate
	if(self.m_frameIndex >= frameCount) then
		self:StopRecording()
		local dt = time.time_since_epoch() -self.m_startTime
		local t = dt /1000000000.0
		pfm.log("Recording complete! Recording took " .. t .. " seconds!",pfm.LOG_CATEGORY_PFM)
		return
	end

	self.m_tool:SetTimeOffset(self.m_frameIndex *(1.0 /frameRate))
	local c = 0
	self.m_cbTick = game.add_callback("Tick",function()
		if(c == 0) then c = c +1; return end
		self.m_cbTick:Remove()
		self.m_cbRender = game.add_callback("PostRender",function()
			local fileName = self.m_fileName .. string.fill_zeroes(tostring(self.m_frameIndex +1),4) .. ".png"
			pfm.log("Saving frame '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)

			local buf = img:ToImageBuffer(false,false)
			-- buf = buf:ApplyToneMapping(util.ImageBuffer.TONE_MAPPING_ACES)
			self.m_threadPool:WaitForPendingCount(15)
			local r = util.save_image(buf,fileName,util.IMAGE_FORMAT_PNG,0.0,self.m_threadPool)
			if(r ~= true) then pfm.log("Unable to save frame '" .. fileName .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING) end

			self.m_cbRender:Remove()
			self.m_frameIndex = self.m_frameIndex +1
			self:RenderNextFrame()
		end)
	end)
end
function pfm.ImageRecorder:StartRecording(fileName)
	if(self:IsRecording()) then
		pfm.log("Unable to start recording: Recording already in progress!",pfm.LOG_CATEGORY_PFM)
		return false
	end
	pfm.log("Starting video recording '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)
	self.m_recording = true
	self.m_fileName = fileName
	self.m_startTime = time.time_since_epoch()
	self:RenderNextFrame()
	return true
end
function pfm.ImageRecorder:StopRecording()
	self.m_recording = false
	util.remove(self.m_cbTick)
	util.remove(self.m_cbRender)
end

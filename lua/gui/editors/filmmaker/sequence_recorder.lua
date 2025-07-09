-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/util/image_recorder.lua")

util.register_class("pfm.SequenceRecorder", util.ImageRecorder)
function pfm.SequenceRecorder:__init(tool)
	local vp = tool:GetViewportElement()
	local scene = vp:GetScene()
	local renderer = scene:GetRenderer()

	local tex = renderer:GetPresentationTexture()
	local img = tex:GetImage()

	util.ImageRecorder.__init(self, img)

	self.m_tool = tool
end
function pfm.SequenceRecorder:GoToTimeOffset(frameIndex, t)
	local frameRate = self.m_frameRate
	local tMax = self.m_tool:GetFrameCount() / self.m_tool:GetFrameRate()
	local frameCount = tMax * frameRate
	self.m_tool:SetTimeOffset(t)
	if self.m_frameIndex >= frameCount then
		return false
	end
	return true
end
function pfm.SequenceRecorder:Log(msg, isWarning)
	pfm.log(msg, pfm.LOG_CATEGORY_PFM, isWarning and pfm.LOG_SEVERITY_WARNING or nil)
end

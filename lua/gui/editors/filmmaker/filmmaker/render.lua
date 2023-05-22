--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:CaptureRaytracedImage()
	if self.m_raytracingJob ~= nil then
		self.m_raytracingJob:Cancel()
	end
	local job = util.capture_raytraced_screenshot(1024, 1024, 512) --2048,2048,1024)
	job:Start()
	self.m_raytracingJob = job

	if util.is_valid(self.m_raytracingProgressBar) then
		self.m_raytracingProgressBar:SetVisible(true)
	end
end
function Element:StopLiveRaytracing()
	local vp = self:GetViewport()
	if util.is_valid(vp) == false then
		return
	end
	vp:StopLiveRaytracing()
end
function Element:IsRendering()
	local vp = self:GetRenderTab()
	return util.is_valid(vp) and vp:IsRendering()
end
function Element:PreRenderScenes(drawSceneInfo)
	if self.m_overlaySceneEnabled ~= true or self.m_nonOverlayRtTexture == nil then
		return
	end
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local vp = self:GetViewport()
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if util.is_valid(rt) then
		local el = rt:GetToneMappedImageElement()
		if util.is_valid(el) then
			local tex = gameRenderer:GetSceneTexture()
			local texRt = self.m_nonOverlayRtTexture
			if texRt ~= nil then
				local drawCmd = drawSceneInfo.commandBuffer
				drawCmd:RecordImageBarrier(
					texRt:GetImage(),
					prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
					prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
				)
				drawCmd:RecordImageBarrier(
					tex:GetImage(),
					prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
					prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
				)
				drawCmd:RecordBlitImage(texRt:GetImage(), tex:GetImage(), prosper.BlitInfo())
				drawCmd:RecordImageBarrier(
					texRt:GetImage(),
					prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
					prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
				)
				drawCmd:RecordImageBarrier(
					tex:GetImage(),
					prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
					prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
				)
			end
		end
	end

	-- Render depth only
	local drawSceneInfoDepth = game.DrawSceneInfo()
	drawSceneInfoDepth.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfoDepth.scene = self.m_sceneDepth
	drawSceneInfoDepth.flags = bit.bor(drawSceneInfoDepth.flags, game.DrawSceneInfo.FLAG_DISABLE_LIGHTING_PASS_BIT)
	drawSceneInfoDepth.clearColor = Color.Lime

	-- Render overlay objects (e.g. object wireframes)
	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfo.scene = self.m_overlayScene
	drawSceneInfo.renderFlags =
		bit.bor(bit.band(drawSceneInfo.renderFlags, bit.bnot(game.RENDER_FLAG_BIT_VIEW)), game.RENDER_FLAG_HDR_BIT) -- Don't render view models

	-- Does not work for some reason?
	-- drawSceneInfo.flags = bit.bor(drawSceneInfo.flags,game.DrawSceneInfo.FLAG_DISABLE_PREPASS_BIT)
	-- drawSceneInfo:AddSubPass(drawSceneInfoDepth)

	game.queue_scene_for_rendering(drawSceneInfo)
	--
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.PragmaRenderJob")
function pfm.PragmaRenderJob:__init(renderSettings)
	self.m_progress = 0.0
	self.m_renderSettings = renderSettings
end
function pfm.PragmaRenderJob:Clear()
	util.remove(self.m_cbPreRenderScenes)
	util.remove(self.m_cbPostRenderScenes)
	if(util.is_valid(self.m_scene)) then self.m_scene:GetEntity():Remove() end
	if(util.is_valid(self.m_renderer)) then self.m_renderer:GetEntity():Remove() end
end
function pfm.PragmaRenderJob:RestoreCamera()
	if(self.m_camRestoreData == nil) then return end
	local restoreData = self.m_camRestoreData
	self.m_camRestoreData = nil
	if(util.is_valid(self.m_scene) == false) then return end
	local cam = self.m_scene:GetActiveCamera()
	if(util.is_valid(cam) == false) then return end
	cam:SetFOV(restoreData.fov)
	cam:SetAspectRatio(restoreData.aspectRatio)
	cam:GetEntity():SetPose(restoreData.pose)
end
function pfm.PragmaRenderJob:RenderNextFrame(immediate,finalize)
	if(self.m_renderPanorama) then
		if(util.is_valid(self.m_scene)) then
			local cam = self.m_scene:GetActiveCamera()
			if(util.is_valid(cam)) then
				self.m_camRestoreData = {
					fov = cam:GetFOV(),
					aspectRatio = cam:GetAspectRatio(),
					pose = cam:GetEntity():GetPose()
				}
				cam:SetFOV(90.0)
				cam:SetAspectRatio(1.0)
				local interocularDistance = 0.065 -- Meters
				if(self.m_curFrame >= 6) then interocularDistance = -interocularDistance end

				local ent = cam:GetEntity()
				local angles = {
					EulerAngles(0,0,0),
					EulerAngles(0,180,0),
					EulerAngles(-90,90,0),
					EulerAngles(90,90,0),
					EulerAngles(0,90,0),
					EulerAngles(0,-90,0)
				}
				local ang = angles[(self.m_curFrame %6) +1]
				local pose = self.m_baseCameraPose:Copy()

				local pos = pose:GetOrigin()
				local rot = pose:GetRotation()

				local dir = rot:GetForward()
				pos,dir = vector.calc_spherical_stereo_transform(pos,dir,interocularDistance)

				local up = rot:GetUp()
				local right = dir:Cross(up)
				right:Normalize()
				rot = Quaternion(dir,right,up)

				pose:SetRotation(rot *ang:ToQuaternion())
				pose:SetOrigin(pos)
				ent:SetPose(pose)
			end
		end
	end
	self.m_drawCommandBuffer:StartRecording(false,false)
	local incMask,excMask = game.get_primary_camera_render_mask()
	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.toneMapping = shader.TONE_MAPPING_NONE
	drawSceneInfo.scene = self.m_scene
	drawSceneInfo.renderFlags = bit.bor(bit.band(drawSceneInfo.renderFlags,bit.bnot(game.RENDER_FLAG_BIT_VIEW)),game.RENDER_FLAG_HDR_BIT) -- Don't render view models
	drawSceneInfo.inclusionMask = incMask
	drawSceneInfo.exclusionMask = excMask
	drawSceneInfo.commandBuffer = self.m_drawCommandBuffer
	if(immediate) then
		game.render_scenes({drawSceneInfo})
		if(finalize == nil) then finalize = true end
		if(finalize) then self:FinalizeFrame() end
	else
		game.queue_scene_for_rendering(drawSceneInfo)
		self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes",function(drawSceneInfo)
			self:RenderNextFrame(true,false)
		end)

		self.m_cbPostRenderScenes = game.add_callback("PostRenderScenes",function(drawSceneInfo)
			self:FinalizeFrame()
		end)
	end
end
function pfm.PragmaRenderJob:FinalizeFrame()
	self.m_drawCommandBuffer:Flush()
	local imgOutput = self.m_renderer:GetHDRPresentationTexture():GetImage()

	if(self.m_renderPanorama) then
		if(self.m_curFrame == 0) then
			local width = imgOutput:GetWidth()
			local height = imgOutput:GetHeight()
			local createInfo = imgOutput:GetCreateInfo()
			createInfo.flags = bit.bor(createInfo.flags,prosper.ImageCreateInfo.FLAG_CUBEMAP_BIT)
			createInfo.layers = 6
			createInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_TRANSFER_DST_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)

			local img = prosper.create_image(createInfo)
			self.m_outputImages = {img}
			if(self.m_stereoscopic) then
				local img2 = prosper.create_image(createInfo)
				table.insert(self.m_outputImages,img2)
			end
		end
		local drawCmd = game.get_setup_command_buffer()
		local blitInfo = prosper.BlitInfo()
		blitInfo.srcSubresourceLayer.baseArrayLayer = 0
		blitInfo.srcSubresourceLayer.layerCount = 1
		blitInfo.dstSubresourceLayer.baseArrayLayer = (self.m_curFrame %6)
		blitInfo.dstSubresourceLayer.layerCount = 1
		drawCmd:RecordBlitImage(imgOutput,(self.m_curFrame < 6) and self.m_outputImages[1] or self.m_outputImages[2],blitInfo)
		game.flush_setup_command_buffer()
	end

	local width = self.m_renderSettings:GetWidth()
	local height = self.m_renderSettings:GetHeight()

	if(self.m_renderPanorama) then
		if(self.m_curFrame == (self.m_numFrames -1)) then
			local horizontalRange = self.m_renderSettings:GetPanoramaHorizontalRange()
			local tex = prosper.create_texture(self.m_outputImages[1],prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),prosper.SamplerCreateInfo())
			local texEqui = shader.cubemap_to_equirectangular_texture(tex,width,height,horizontalRange)
			local img = texEqui:GetImage()

			if(self.m_stereoscopic) then
				local tex2 = prosper.create_texture(self.m_outputImages[2],prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),prosper.SamplerCreateInfo())
				local texEqui2 = shader.cubemap_to_equirectangular_texture(tex2,width,height,horizontalRange)

				local createInfo = texEqui:GetImage():GetCreateInfo()
				createInfo.width = width
				createInfo.height = height *2

				img = prosper.create_image(createInfo)

				local drawCmd = game.get_setup_command_buffer()
				local blitInfo = prosper.BlitInfo()
				blitInfo.srcSubresourceLayer.baseArrayLayer = 0
				blitInfo.srcSubresourceLayer.layerCount = 1
				blitInfo.dstSubresourceLayer.baseArrayLayer = (self.m_curFrame %6)
				blitInfo.dstSubresourceLayer.layerCount = 1
				blitInfo.offsetSrc = Vector2i(0,0)
				blitInfo.extentsSrc = Vector2i(width,height)
				blitInfo.offsetDst = Vector2i(0,0)
				blitInfo.extentsDst = Vector2i(width,height)
				drawCmd:RecordBlitImage(texEqui:GetImage(),img,blitInfo)
				blitInfo.offsetDst = Vector2i(0,height)
				drawCmd:RecordBlitImage(texEqui2:GetImage(),img,blitInfo)
				game.flush_setup_command_buffer()
			end
			
			self.m_imageBuffer = img:ToImageBuffer(false,false,util.ImageBuffer.FORMAT_RGBA32,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
			local res = unirender.apply_color_transform(self.m_imageBuffer,nil,nil,self.m_renderSettings:GetColorTransform(),self.m_renderSettings:GetColorTransformLook())
		end
	else
		local imgBuf = imgOutput:ToImageBuffer(false,false,util.ImageBuffer.FORMAT_RGBA32,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
		self.m_imageBuffer = imgBuf
		local res = unirender.apply_color_transform(self.m_imageBuffer,nil,nil,self.m_renderSettings:GetColorTransform(),self.m_renderSettings:GetColorTransformLook())
	end

	self:RestoreCamera()

	self.m_progress = (self.m_numFrames > 1) and (self.m_curFrame /(self.m_numFrames -1)) or 1.0
	if(self.m_curFrame < (self.m_numFrames -1)) then
		self.m_curFrame = self.m_curFrame +1
		self:RenderNextFrame(true)
	else
		self:Clear()
	end
end
function pfm.PragmaRenderJob:Start()
	local cam = game.get_scene():GetActiveCamera()
	if(cam == nil) then return end

	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT

	-- Create temporary scene
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local scene = ents.create_scene(sceneCreateInfo,gameScene)
	scene:SetActiveCamera(cam)
	self.m_scene = scene

	self.m_renderPanorama = self.m_renderSettings:GetCamType() == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA and self.m_renderSettings:GetPanoramaType() == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR
	self.m_stereoscopic = self.m_renderPanorama and self.m_renderSettings:IsStereoscopic()

	-- Create temporary renderer
	local entRenderer = ents.create("rasterization_renderer")
	local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
	local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
	rasterizer:SetSSAOEnabled(true)
	if(self.m_renderPanorama) then
		-- TODO: This is somewhat arbitrary. How can we calculate an appropriate size for the individual cubemap faces?
		local size = self.m_renderSettings:GetHeight() *2
		renderer:InitializeRenderTarget(gameScene,size,size)
	else renderer:InitializeRenderTarget(gameScene,self.m_renderSettings:GetWidth(),self.m_renderSettings:GetHeight()) end
	scene:SetRenderer(renderer)
	self.m_renderer = renderer

	-- Create temporary command buffer
	local drawCmd = prosper.create_primary_command_buffer()
	self.m_drawCommandBuffer = drawCmd

	self.m_baseCameraPose = cam:GetEntity():GetPose()

	self.m_numFrames = self.m_stereoscopic and 12 or (self.m_renderPanorama and 6 or 1)
	self.m_curFrame = 0

	self:RenderNextFrame(true)
end
function pfm.PragmaRenderJob:IsComplete() return self:GetProgress() == 1.0 end
function pfm.PragmaRenderJob:GetProgress() return self.m_progress end
function pfm.PragmaRenderJob:IsSuccessful() return self:GetProgress() == 1.0 end
function pfm.PragmaRenderJob:GetResultCode() return -1 end
function pfm.PragmaRenderJob:GetImage() return self.m_imageBuffer end
function pfm.PragmaRenderJob:Cancel() self:Clear() end

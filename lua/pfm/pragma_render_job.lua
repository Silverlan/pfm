--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm.register_log_category("pragma_renderer")

util.register_class("pfm.PragmaRenderScene")
function pfm.PragmaRenderScene:__init(width, height, ssFactor)
	ssFactor = ssFactor or 1.0
	local sceneCreateInfo = ents.SceneComponent.CreateInfo()
	sceneCreateInfo.sampleCount = prosper.SAMPLE_COUNT_1_BIT

	-- Create temporary scene
	local gameScene = game.get_scene()
	local gameRenderer = gameScene:GetRenderer()
	local scene = ents.create_scene(sceneCreateInfo, gameScene)
	self.m_scene = scene

	-- Create temporary renderer
	local entRenderer = ents.create("rasterization_renderer")
	entRenderer:Spawn()
	local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
	local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
	entRenderer:AddComponent("pfm_pragma_renderer")
	local toneMappingC = entRenderer:AddComponent("renderer_pp_tone_mapping")
	toneMappingC:SetApplyToHdrImage(true)
	rasterizer:SetSSAOEnabled(true)
	renderer:InitializeRenderTarget(gameScene, width * ssFactor, height * ssFactor)
	renderer:GetEntity():AddComponent(ents.COMPONENT_RENDERER_PP_VOLUMETRIC)
	scene:SetRenderer(renderer)
	scene:SetWorldEnvironment(gameScene:GetWorldEnvironment())
	self.m_renderer = renderer

	self.m_width = width
	self.m_height = height
	self.m_ssFactor = ssFactor
	self:UpdateDownSampledRenderTexture()
end
function pfm.PragmaRenderScene:GetDownSampleTexture()
	return self.m_downSampleTex
end
function pfm.PragmaRenderScene:GetDownSampleRenderTarget()
	return self.m_downSampleRt
end
function pfm.PragmaRenderScene:GetDownSampleDescriptorSet()
	return self.m_downSampleDs
end
function pfm.PragmaRenderScene:UpdateDownSampledRenderTexture()
	--[[if(self.m_ssFactor == 1.0) then
		self.m_downSampleTex = nil
		return
	end]]
	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = self.m_width
	imgCreateInfo.height = self.m_height
	imgCreateInfo.format = prosper.FORMAT_R16G16B16A16_SFLOAT
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_TRANSFER_SRC_BIT, prosper.IMAGE_USAGE_TRANSFER_DST_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
	local img = prosper.create_image(imgCreateInfo)
	local tex = prosper.create_texture(
		img,
		prosper.TextureCreateInfo(),
		prosper.ImageViewCreateInfo(),
		prosper.SamplerCreateInfo()
	)
	self.m_downSampleTex = tex
	self.m_downSampleRt =
		prosper.create_render_target(prosper.RenderTargetCreateInfo(), { tex }, shader.Graphics.get_render_pass())
	self.m_downSampleDs = prosper.util.create_generic_image_descriptor_set(self.m_renderer:GetHDRPresentationTexture())
end
function pfm.PragmaRenderScene:GetResolution()
	return self.m_width, self.m_height
end
function pfm.PragmaRenderScene:ChangeResolution(width, height, ssFactor)
	if util.is_valid(self.m_renderer) == false or util.is_valid(self.m_scene) == false then
		return
	end
	if width == self.m_width and height == self.m_height and self.m_ssFactor == ssFactor then
		return
	end
	self.m_downSampleTex = nil
	self.m_downSampleRt = nil
	self.m_downSampleDs = nil
	collectgarbage()
	collectgarbage()

	self.m_ssFactor = ssFactor
	self.m_width = width
	self.m_height = height
	self.m_renderer:InitializeRenderTarget(self.m_scene, width * self.m_ssFactor, height * self.m_ssFactor)
	self:UpdateDownSampledRenderTexture()
end
function pfm.PragmaRenderScene:Clear()
	if util.is_valid(self.m_scene) then
		self.m_scene:GetEntity():Remove()
	end
	if util.is_valid(self.m_renderer) then
		self.m_renderer:GetEntity():Remove()
	end
	self.m_downSampleRt = nil
	self.m_downSampleDs = nil
	collectgarbage()
	collectgarbage()
end
function pfm.PragmaRenderScene:GetScene()
	return self.m_scene
end
function pfm.PragmaRenderScene:GetRenderer()
	return self.m_renderer
end
function pfm.get_pragma_renderer_scene()
	return pfm.g_pragmaRendererRenderScene
end
function pfm.clear_pragma_renderer_scene()
	if pfm.g_pragmaRendererRenderScene == nil then
		return
	end
	pfm.g_pragmaRendererRenderScene:Clear()
	pfm.g_pragmaRendererRenderScene = nil
end

------------------

util.register_class("pfm.PragmaRenderJob")
function pfm.PragmaRenderJob:__init(renderSettings)
	self.m_progress = 0.0
	self.m_renderSettings = renderSettings
end
function pfm.PragmaRenderJob:Clear()
	util.remove(self.m_cbPreRenderScenes)
	util.remove(self.m_cbPostRenderScenes)
end
function pfm.PragmaRenderJob:RestoreCamera()
	if self.m_camRestoreData == nil then
		return
	end
	local restoreData = self.m_camRestoreData
	self.m_camRestoreData = nil
	if util.is_valid(self.m_scene) == false then
		return
	end
	local cam = self.m_scene:GetActiveCamera()
	if util.is_valid(cam) == false then
		return
	end
	cam:SetFOV(restoreData.fov)
	cam:SetAspectRatio(restoreData.aspectRatio)
	cam:GetEntity():SetPose(restoreData.pose)
end
function pfm.PragmaRenderJob:RenderNextFrame(immediate, finalize)
	pfm.log(
		"Rendering frame "
			.. self.m_curFrame
			.. ((self.m_curTile ~= nil) and (", tile " .. self.m_curTile .. "/" .. self.m_numTiles) or ""),
		pfm.LOG_CATEGORY_PRAGMA_RENDERER,
		pfm.LOG_SEVERITY_DEBUG
	)
	local pragmaRendererC = self.m_renderer:GetEntity():GetComponent("pfm_pragma_renderer")
	if pragmaRendererC ~= nil then
		pragmaRendererC:OnRender()
	end
	if self.m_renderPanorama then
		if util.is_valid(self.m_scene) then
			local cam = self.m_scene:GetActiveCamera()
			if util.is_valid(cam) then
				self.m_camRestoreData = {
					fov = cam:GetFOV(),
					aspectRatio = cam:GetAspectRatio(),
					pose = cam:GetEntity():GetPose(),
				}
				cam:SetFOV(90.0)
				cam:SetAspectRatio(1.0)
				local interocularDistance = 0.065 -- Meters
				if self.m_curFrame >= 6 then
					interocularDistance = -interocularDistance
				end

				local ent = cam:GetEntity()
				local angles = {
					EulerAngles(0, 0, 0),
					EulerAngles(0, 180, 0),
					EulerAngles(-90, 90, 0),
					EulerAngles(90, 90, 0),
					EulerAngles(0, 90, 0),
					EulerAngles(0, -90, 0),
				}
				local ang = angles[(self.m_curFrame % 6) + 1]
				local pose = self.m_baseCameraPose:Copy()

				local pos = pose:GetOrigin()
				local rot = pose:GetRotation()

				local dir = rot:GetForward()
				pos, dir = vector.calc_spherical_stereo_transform(pos, dir, interocularDistance)

				local up = rot:GetUp()
				local right = dir:Cross(up)
				right:Normalize()
				rot = Quaternion(dir, right, up)

				pose:SetRotation(rot * ang:ToQuaternion())
				pose:SetOrigin(pos)
				ent:SetPose(pose)
			end
		end
	end

	local cam = game.get_scene():GetActiveCamera()
	if self.m_useTiledRendering then
		local x, y = self:GetTileOffsets(false, false)
		local w, h = self:GetTileSizes()

		local maxW = self.m_tileCompositeImgBuf:GetWidth()
		local maxH = self.m_tileCompositeImgBuf:GetHeight()

		local fx = 2 / (1.0 + (w / maxW))
		local fy = 2 / (1.0 + (h / maxH))

		local v0 = x
		local v1 = y
		local v2 = (w / 2.0) + maxW / fx
		local v3 = (h / 2.0) + maxH / fy
		cam:SetAspectRatio(self.m_renderWidth / self.m_renderHeight)
		local proj = ents.CameraComponent.calc_projection_matrix(
			cam:GetFOVRad(),
			cam:GetAspectRatio(),
			cam:GetNearZ(),
			cam:GetFarZ(),
			util.RenderTile(v0 / maxW, v1 / maxH, v2 / maxW, v3 / maxH)
		)
		cam:SetProjectionMatrix(proj)
		cam:UpdateViewMatrix()
	else
		cam:SetAspectRatio(self.m_renderWidth / self.m_renderHeight)
		cam:UpdateMatrices()
	end
	--

	self.m_drawCommandBuffer:StartRecording(false, false)
	local incMask, excMask = game.get_primary_camera_render_mask()
	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.toneMapping = shader.TONE_MAPPING_HDR
	drawSceneInfo.scene = self.m_scene
	drawSceneInfo.renderFlags = bit.bor(
		bit.band(drawSceneInfo.renderFlags, bit.bnot(game.RENDER_FLAG_BIT_VIEW), bit.bnot(game.RENDER_FLAG_BIT_DEBUG)),
		game.RENDER_FLAG_HDR_BIT
	) -- Don't render view models
	drawSceneInfo.inclusionMask = incMask
	drawSceneInfo.exclusionMask = excMask
	drawSceneInfo.commandBuffer = self.m_drawCommandBuffer
	if immediate then
		debug.start_profiling_task("pfm_render_pragma_frame")
		game.render_scenes({ drawSceneInfo })
		if finalize == nil then
			finalize = true
		end
		local shouldRenderNextFrame = false
		if finalize then
			shouldRenderNextFrame = self:FinalizeFrame()
		end
		debug.stop_profiling_task()

		if self.m_useTiledRendering then
			cam:UpdateMatrices()
		end
		return shouldRenderNextFrame
	end

	game.queue_scene_for_rendering(drawSceneInfo)
	self.m_cbPreRenderScenes = game.add_callback("PreRenderScenes", function(drawSceneInfo)
		self:RenderNextFrame(true, false)
	end)

	self.m_cbPostRenderScenes = game.add_callback("PostRenderScenes", function(drawSceneInfo)
		self:FinalizeFrame()
	end)
	return false
end
function pfm.PragmaRenderJob:FinalizeFrame()
	self.m_drawCommandBuffer:Flush()
	local texOutput = self.m_renderer:GetHDRPresentationTexture()

	local function finalize()
		self:RestoreCamera()

		if self.m_useTiledRendering and self.m_curTile < (self.m_numTiles - 1) then
			self.m_curTile = self.m_curTile + 1
			return true
		else
			self.m_progress = (self.m_numFrames > 1) and (self.m_curFrame / (self.m_numFrames - 1)) or 1.0
			if self.m_curFrame < (self.m_numFrames - 1) then
				self.m_curFrame = self.m_curFrame + 1
				return true
			else
				self:Clear()
			end
		end
		return false
	end

	local baseSettings = tool.get_filmmaker():GetSettings():GetRenderSettings()
	local mode = baseSettings:GetMode()
	if mode == pfm.RaytracingRenderJob.Settings.RENDER_MODE_DEPTH then
		local rasterC = self.m_renderer:GetEntity():GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
		if rasterC ~= nil then
			texOutput = rasterC:GetPostPrepassDepthTexture()
			local imgBuf = texOutput:GetImage():ToImageBuffer(
				false,
				false,
				util.ImageBuffer.FORMAT_RGBA16,
				prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
			)
			self.m_imageBuffer = imgBuf
			return finalize()
		end
	end

	local imgOutput = texOutput:GetImage()
	local downSampleRt = pfm.g_pragmaRendererRenderScene:GetDownSampleRenderTarget()
	if downSampleRt ~= nil then
		local drawCmd = game.get_setup_command_buffer()

		local wDownSampled = downSampleRt:GetTexture():GetImage():GetWidth()
		if wDownSampled == imgOutput:GetWidth() then
			-- Same image size, just blit
			local blitInfo = prosper.BlitInfo()
			blitInfo.srcSubresourceLayer.baseArrayLayer = 0
			blitInfo.srcSubresourceLayer.layerCount = 1
			blitInfo.dstSubresourceLayer.baseArrayLayer = 0
			blitInfo.dstSubresourceLayer.layerCount = 1
			drawCmd:RecordBlitImage(imgOutput, downSampleRt:GetTexture():GetImage(), blitInfo)
		else
			-- Downsample with Lanczos or Bicubic filtering
			prosper.util.record_resize_image(
				drawCmd,
				pfm.g_pragmaRendererRenderScene:GetDownSampleDescriptorSet(),
				downSampleRt
			)
		end

		game.flush_setup_command_buffer()
		imgOutput = downSampleRt:GetTexture():GetImage()
	end

	if self.m_renderPanorama then
		if self.m_curFrame == 0 then
			local width = imgOutput:GetWidth()
			local height = imgOutput:GetHeight()
			local createInfo = imgOutput:GetCreateInfo()
			createInfo.flags = bit.bor(createInfo.flags, prosper.ImageCreateInfo.FLAG_CUBEMAP_BIT)
			createInfo.layers = 6
			createInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_TRANSFER_DST_BIT, prosper.IMAGE_USAGE_SAMPLED_BIT)

			local img = prosper.create_image(createInfo)
			self.m_outputImages = { img }
			if self.m_stereoscopic then
				local img2 = prosper.create_image(createInfo)
				table.insert(self.m_outputImages, img2)
			end
		end
		local drawCmd = game.get_setup_command_buffer()
		local blitInfo = prosper.BlitInfo()
		blitInfo.srcSubresourceLayer.baseArrayLayer = 0
		blitInfo.srcSubresourceLayer.layerCount = 1
		blitInfo.dstSubresourceLayer.baseArrayLayer = (self.m_curFrame % 6)
		blitInfo.dstSubresourceLayer.layerCount = 1
		drawCmd:RecordBlitImage(
			imgOutput,
			(self.m_curFrame < 6) and self.m_outputImages[1] or self.m_outputImages[2],
			blitInfo
		)
		game.flush_setup_command_buffer()
	end

	local width = self.m_renderSettings:GetWidth()
	local height = self.m_renderSettings:GetHeight()

	pfm.log("Finalizing image buffer...", pfm.LOG_CATEGORY_PRAGMA_RENDERER, pfm.LOG_SEVERITY_DEBUG)
	if self.m_renderPanorama then
		if self.m_curFrame == (self.m_numFrames - 1) then
			local horizontalRange = self.m_renderSettings:GetPanoramaHorizontalRange()
			local tex = prosper.create_texture(
				self.m_outputImages[1],
				prosper.TextureCreateInfo(),
				prosper.ImageViewCreateInfo(),
				prosper.SamplerCreateInfo()
			)
			local texEqui = shader.cubemap_to_equirectangular_texture(tex, width, height, horizontalRange)
			local img = texEqui:GetImage()

			if self.m_stereoscopic then
				local tex2 = prosper.create_texture(
					self.m_outputImages[2],
					prosper.TextureCreateInfo(),
					prosper.ImageViewCreateInfo(),
					prosper.SamplerCreateInfo()
				)
				local texEqui2 = shader.cubemap_to_equirectangular_texture(tex2, width, height, horizontalRange)

				local createInfo = texEqui:GetImage():GetCreateInfo()
				createInfo.width = width
				createInfo.height = height * 2

				img = prosper.create_image(createInfo)

				local drawCmd = game.get_setup_command_buffer()
				local blitInfo = prosper.BlitInfo()
				blitInfo.srcSubresourceLayer.baseArrayLayer = 0
				blitInfo.srcSubresourceLayer.layerCount = 1
				blitInfo.dstSubresourceLayer.baseArrayLayer = (self.m_curFrame % 6)
				blitInfo.dstSubresourceLayer.layerCount = 1
				blitInfo.offsetSrc = Vector2i(0, 0)
				blitInfo.extentsSrc = Vector2i(width, height)
				blitInfo.offsetDst = Vector2i(0, 0)
				blitInfo.extentsDst = Vector2i(width, height)
				drawCmd:RecordBlitImage(texEqui:GetImage(), img, blitInfo)
				blitInfo.offsetDst = Vector2i(0, height)
				drawCmd:RecordBlitImage(texEqui2:GetImage(), img, blitInfo)
				game.flush_setup_command_buffer()
			end
			self.m_imageBuffer = img:ToImageBuffer(
				false,
				false,
				util.ImageBuffer.FORMAT_RGBA16,
				prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
			)
			local res = unirender.apply_color_transform(
				self.m_imageBuffer,
				nil,
				nil,
				self.m_renderSettings:GetColorTransform(),
				self.m_renderSettings:GetColorTransformLook()
			)
		end
	else
		local createInfo = imgOutput:GetCreateInfo()
		if
			self.m_imgOutputStagingImage == nil
			or self.m_imgOutputStagingImage:GetWidth() ~= createInfo.width
			or self.m_imgOutputStagingImage:GetHeight() ~= createInfo.height
		then
			createInfo.usageFlags = bit.bor(createInfo.usageFlags, prosper.IMAGE_USAGE_TRANSFER_DST_BIT)
			createInfo.postCreateLayout = prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
			createInfo.format = prosper.FORMAT_R16G16B16A16_SFLOAT

			self.m_imgOutputStagingImage = prosper.create_image(createInfo)
		end
		local imgBufInfo = prosper.Image.ToImageBufferInfo()
		imgBufInfo.includeLayers = false
		imgBufInfo.includeMipmaps = false
		imgBufInfo.targetFormat = util.ImageBuffer.FORMAT_RGBA16
		imgBufInfo.inputImageLayout = prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
		imgBufInfo.stagingImage = self.m_imgOutputStagingImage
		local imgBuf = imgOutput:ToImageBuffer(imgBufInfo)
		local res = unirender.apply_color_transform(
			imgBuf,
			nil,
			nil,
			self.m_renderSettings:GetColorTransform(),
			self.m_renderSettings:GetColorTransformLook()
		)

		if self.m_useTiledRendering then
			self.m_imageBuffer = self.m_tileCompositeImgBuf
			local x, y = self:GetTileOffsets()

			if pfm.util.init_opencv() then
				opencv.copy(imgBuf, self.m_tileCompositeImgBuf, x, y, imgBuf:GetWidth(), imgBuf:GetHeight())
			else
				self.m_tileCompositeImgBuf:Insert(imgBuf, x, y)
			end
		else
			self.m_imageBuffer = imgBuf
		end
	end

	return finalize()
end
function pfm.PragmaRenderJob:GetTileIndices()
	local numTilesX = self.m_tileCompositeImgBuf:GetWidth() / self.m_tileWidth
	local x = self.m_curTile % self.m_numTilesX
	local y = math.floor(self.m_curTile / self.m_numTilesX)
	return x, y
end
function pfm.PragmaRenderJob:GetTileOffsets(flipX, flipY)
	local x, y = self:GetTileIndices()
	if flipX then
		x = self.m_tileCompositeImgBuf:GetWidth() - (x + 1) * self.m_tileWidth
	else
		x = x * self.m_tileWidth
	end

	if flipY then
		y = self.m_tileCompositeImgBuf:GetHeight() - (y + 1) * self.m_tileHeight
	else
		y = y * self.m_tileHeight
	end

	return x, y
end
function pfm.PragmaRenderJob:GetTileSizes()
	return self.m_tileWidth, self.m_tileHeight
end
function pfm.PragmaRenderJob:Start()
	local cam = game.get_scene():GetActiveCamera()
	if cam == nil then
		return
	end

	self.m_renderPanorama = self.m_renderSettings:GetCamType() == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA
		and self.m_renderSettings:GetPanoramaType()
			== pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR
	self.m_stereoscopic = self.m_renderPanorama and self.m_renderSettings:IsStereoscopic()

	local width = self.m_renderSettings:GetWidth()
	local height = self.m_renderSettings:GetHeight()
	local ssFactor = self.m_renderSettings:GetSupersamplingFactor()
	if self.m_renderPanorama then
		-- TODO: This is somewhat arbitrary. How can we calculate an appropriate size for the individual cubemap faces?
		local size = self.m_renderSettings:GetHeight() * 2
		width = size
		height = size
		-- ssFactor = 1.0
	end

	local tileSize = self.m_renderSettings:GetTileSize()
	if self.m_renderPanorama or self.m_stereoscopic then
		tileSize = 0
	end -- Tiled rendering currently not supported for panorama and stereo renders
	local renderWidth = width
	local renderHeight = height
	self.m_renderWidth = renderWidth
	self.m_renderHeight = renderHeight
	if tileSize > 0 then
		pfm.log(
			"Initializing tiled rendering with tile size " .. tileSize,
			pfm.LOG_CATEGORY_PRAGMA_RENDERER,
			pfm.LOG_SEVERITY_DEBUG
		)
		self.m_useTiledRendering = true
		self.m_tileWidth = tileSize
		self.m_tileHeight = tileSize
		self.m_tileCompositeImgBuf = util.ImageBuffer.Create(width, height, util.ImageBuffer.FORMAT_RGBA16)
		renderWidth = self.m_tileWidth
		renderHeight = self.m_tileHeight

		self.m_numTilesX = math.ceil(width / self.m_tileWidth)
		self.m_numTilesY = math.ceil(height / self.m_tileHeight)
		self.m_numTiles = self.m_numTilesX * self.m_numTilesY
		self.m_curTile = 0

		pfm.log(
			"Number of tiles: " .. self.m_numTilesX .. "x" .. self.m_numTilesY,
			pfm.LOG_CATEGORY_PRAGMA_RENDERER,
			pfm.LOG_SEVERITY_DEBUG
		)
	else
		pfm.log(
			"Tile size is 0, tiled rendering will be disabled.",
			pfm.LOG_CATEGORY_PRAGMA_RENDERER,
			pfm.LOG_SEVERITY_DEBUG
		)
		self.m_useTiledRendering = false
	end

	pfm.log(
		"Using renderer resolution " .. renderWidth .. "x" .. renderHeight,
		pfm.LOG_CATEGORY_PRAGMA_RENDERER,
		pfm.LOG_SEVERITY_DEBUG
	)
	if pfm.g_pragmaRendererRenderScene == nil then
		pfm.g_pragmaRendererRenderScene = pfm.PragmaRenderScene(renderWidth, renderHeight, ssFactor)
	else
		pfm.g_pragmaRendererRenderScene:ChangeResolution(renderWidth, renderHeight, ssFactor)
	end

	self.m_scene = pfm.g_pragmaRendererRenderScene:GetScene()
	self.m_scene:SetActiveCamera(cam)

	self.m_renderer = pfm.g_pragmaRendererRenderScene:GetRenderer()

	-- Create temporary command buffer
	local drawCmd = prosper.create_primary_command_buffer()
	self.m_drawCommandBuffer = drawCmd

	self.m_baseCameraPose = cam:GetEntity():GetPose()

	self.m_numFrames = self.m_stereoscopic and 12 or (self.m_renderPanorama and 6 or 1)
	self.m_curFrame = 0

	local shouldRenderNextFrame = self:RenderNextFrame(true)
	while shouldRenderNextFrame do
		shouldRenderNextFrame = self:RenderNextFrame(true)
	end
end
function pfm.PragmaRenderJob:GetCommandBuffer()
	return self.m_drawCommandBuffer
end
function pfm.PragmaRenderJob:IsComplete()
	return self:GetProgress() == 1.0
end
function pfm.PragmaRenderJob:GetProgress()
	return self.m_progress
end
function pfm.PragmaRenderJob:IsSuccessful()
	return self:GetProgress() == 1.0
end
function pfm.PragmaRenderJob:GetResultCode()
	return -1
end
function pfm.PragmaRenderJob:GetImage()
	return self.m_imageBuffer
end
function pfm.PragmaRenderJob:Cancel()
	self:Clear()
end

--------------------

util.register_class("pfm.PragmaRenderer")
function pfm.PragmaRenderer:__init(pragmaRenderJob, rtJob)
	self.m_pragmaRenderJob = pragmaRenderJob
	self.m_rtJob = rtJob
end
function pfm.PragmaRenderer:BeginSceneEdit()
	return true
end
function pfm.PragmaRenderer:InitializeStagingImage()
	if self.m_stagingImg ~= nil then
		return
	end
	local result = self.m_rtJob:GetRenderResultTexture()
	local createInfo = result:GetImage():GetCreateInfo()
	createInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_TRANSFER_SRC_BIT)
	createInfo.tiling = prosper.IMAGE_TILING_LINEAR
	createInfo.postCreateLayout = prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
	createInfo.memoryFeatures = prosper.MEMORY_FEATURE_CPU_TO_GPU

	self.m_stagingImg = prosper.create_image(createInfo)
end
function pfm.PragmaRenderer:EndSceneEdit()
	self.m_pragmaRenderJob:RenderNextFrame(true)
	local result = self.m_rtJob:GetRenderResultTexture()
	local imgBuf = self.m_pragmaRenderJob:GetImage()
	-- TODO: Downscale the image if we're rendering at a really high resolution
	if result ~= nil and imgBuf ~= nil then
		self:InitializeStagingImage()

		-- TODO: We need some barriers here
		self.m_stagingImg:WriteMemory(0, 0, imgBuf)

		local imgResult = result:GetImage()

		local drawCmd = self.m_pragmaRenderJob:GetCommandBuffer()
		drawCmd:StartRecording(false, false)

		drawCmd:RecordImageBarrier(
			imgResult,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
		)
		drawCmd:RecordBlitImage(self.m_stagingImg, imgResult, prosper.BlitInfo())
		drawCmd:RecordImageBarrier(
			imgResult,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
		)

		drawCmd:Flush()
	end
end
function pfm.PragmaRenderer:SyncActor(ent) end
function pfm.PragmaRenderer:Restart() end

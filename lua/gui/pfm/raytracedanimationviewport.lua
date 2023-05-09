--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/raytracedviewport.lua")

util.register_class("gui.PFMRaytracedAnimationViewport", gui.RaytracedViewport)
function gui.PFMRaytracedAnimationViewport:__init()
	gui.RaytracedViewport.__init(self)
end
function gui.PFMRaytracedAnimationViewport:OnInitialize()
	gui.RaytracedViewport.OnInitialize(self)

	self:SetSaveAsHDR(false)
	local elImg = self:GetToneMappedImageElement()
	elImg:SetMouseInputEnabled(true)
	elImg:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local imgBuf = (self.m_rtJob ~= nil) and self.m_rtJob:GetRenderResult()
			if imgBuf ~= nil then
				local pContext = gui.open_context_menu()
				if util.is_valid(pContext) == false then
					return
				end
				pContext:SetPos(input.get_cursor_pos())

				local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("save_as"))
				local hdr = self.m_saveAsHdr
				for i = 0, (util.IMAGE_FORMAT_COUNT - 1) do
					if
						(
							hdr and (
								i == util.IMAGE_FORMAT_HDR--[[ or i == util.IMAGE_FORMAT_PNG]]
							)
						) or (not hdr and i ~= util.IMAGE_FORMAT_HDR)
					then
						pSubMenu:AddItem(util.get_image_format_file_extension(i), function(pItem)
							self:SaveAs(i, hdr)
						end)
					end
				end
				pSubMenu:Update()

				pContext:AddItem(locale.get_text("pfm_apply_render_settings"), function()
					local mat = self:LoadPreviewMaterial()
					if mat == nil then
						return
					end
					local db = mat:GetDataBlock()
					local dbRenderSettings = db:FindBlock("pfm_render_settings")
					if dbRenderSettings == nil then
						return
					end
					self:ApplyRenderSettings(dbRenderSettings)
				end)
				pContext:Update()
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	self:SetParticleSystemColorFactor(Vector4(1, 1, 1, 1))
	self:SetImageSaveFormat(util.IMAGE_FORMAT_HDR)
end
function gui.PFMRaytracedAnimationViewport:SetSaveAsHDR(saveAsHdr)
	self.m_saveAsHdr = saveAsHdr
end
function gui.PFMRaytracedAnimationViewport:SaveAs(format, hdr)
	format = format or self.m_imgSaveFormat
	local dialoge = gui.create_file_save_dialog(function(pDialoge)
		local fname = pDialoge:GetFilePath(true)
		file.create_path(file.get_file_path(fname))

		-- Make sure HDR image is loaded
		--if(self:LoadHighDefImage(true) == false) then return end
		self:SaveImage(fname, format, hdr)
	end)
	dialoge:SetExtensions({ util.get_image_format_file_extension(format) })
	dialoge:SetRootPath(util.get_addon_path())
	dialoge:Update()
end
function gui.PFMRaytracedAnimationViewport:SetImageSaveFormat(format)
	self.m_imgSaveFormat = format
end
function gui.PFMRaytracedAnimationViewport:GetImageSaveFormat()
	return self.m_imgSaveFormat
end
function gui.PFMRaytracedAnimationViewport:GetRTJob()
	return self.m_rtJob
end
function gui.PFMRaytracedAnimationViewport:LoadPreviewMaterial(reload)
	if self.m_curImagePath == nil then
		return
	end
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(self.m_curImagePath)
	local matPath = thumbnailLocation
	if asset.exists(matPath, asset.TYPE_MATERIAL) == false then
		return
	end
	return game.load_material(thumbnailLocation, reload or false, true)
end
function gui.PFMRaytracedAnimationViewport:LoadPreviewImage(filePath, reload, dontGenerate)
	if self.m_imgJob ~= nil then
		self.m_imgJob:Cancel()
	end
	self.m_imgJob = nil

	local displayTex = self:GetToneMappedImageElement()
	displayTex:SetTexture()

	self.m_curImagePath = filePath
	self.m_highDefImageLoaded = false

	local thumbnailLocation = "render_previews/" .. util.get_string_hash(filePath)
	local matPath = thumbnailLocation
	if asset.exists(matPath, asset.TYPE_MATERIAL) == false then
		if dontGenerate == true then
			return false
		end
		if self:GeneratePreviewImage(filePath) == false then
			return false
		end
	end
	local mat = self:LoadPreviewMaterial(reload)
	if mat == nil or mat:IsError() then
		return false
	end

	local luminance = util.Luminance.get_material_luminance(mat) or util.Luminance()
	displayTex:SetLuminance(luminance)

	local tex = mat:GetTextureInfo("albedo_map")
	tex = (tex ~= nil) and tex:GetTexture() or nil
	tex = (tex ~= nil) and tex:GetVkTexture() or nil
	if tex == nil then
		return false
	end
	displayTex:SetTexture(tex)

	self.m_tLoadHighDefImageDelay = time.real_time() + 0.2
	self:UpdateThinkState()
	return true
end
function gui.PFMRaytracedAnimationViewport:LoadHighDefImage(waitForCompletion, reload)
	if self.m_highDefImageLoaded == true and reload ~= true then
		return true
	end
	if self.m_imgJob ~= nil then
		if waitForCompletion then
			self.m_imgJob:Wait()
			self:InitializeHighDefImage()
			return true
		end
		return false
	end
	self.m_tLoadHighDefImageDelay = nil
	if self.m_curImagePath == nil then
		return false
	end
	local path = self.m_curImagePath
	if self.m_imgJob ~= nil then
		self.m_imgJob:Cancel()
	end
	-- Loading the image may take some time, so we'll do it on a separate thread in the background.
	-- Once loaded, the algorithm continues in :OnThink
	print(path .. ".hdr")
	self.m_imgJob = util.load_image(path .. ".hdr", true, util.ImageBuffer.FORMAT_RGBA_HDR)
	if self.m_imgJob == nil then
		return false
	end
	self.m_imgJob:Start()

	self:UpdateThinkState()
	if waitForCompletion then
		return self:LoadHighDefImage(true)
	end
	return false
end
function gui.PFMRaytracedAnimationViewport:InitializeHighDefImage()
	if true then
		return
	end -- TODO
	if self.m_imgJob:IsSuccessful() then
		-- HDR image has been loaded; Apply it instead of the preview image
		local imgBuf = self.m_imgJob:GetResult()
		local texHdr = self:InitializeSceneTexture(imgBuf:GetWidth(), imgBuf:GetHeight())
		if texHdr == nil then
			return
		end
		local buf = prosper.util.allocate_temporary_buffer(imgBuf:GetSize())
		buf:WriteMemory(0, imgBuf:GetData())

		local drawCmd = game.get_setup_command_buffer()
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.ACCESS_SHADER_READ_BIT,
			prosper.ACCESS_TRANSFER_WRITE_BIT
		)
		drawCmd:RecordBufferBarrier(
			buf,
			prosper.PIPELINE_STAGE_ALL_COMMANDS,
			prosper.PIPELINE_STAGE_ALL_COMMANDS,
			prosper.ACCESS_MEMORY_WRITE_BIT,
			prosper.ACCESS_SHADER_READ_BIT
		)
		drawCmd:RecordCopyBufferToImage(buf, texHdr:GetImage())
		drawCmd:RecordBufferBarrier(
			buf,
			prosper.PIPELINE_STAGE_ALL_COMMANDS,
			prosper.PIPELINE_STAGE_ALL_COMMANDS,
			prosper.ACCESS_SHADER_READ_BIT,
			prosper.ACCESS_MEMORY_WRITE_BIT
		)
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.ACCESS_TRANSFER_WRITE_BIT,
			prosper.ACCESS_SHADER_READ_BIT
		)
		game.flush_setup_command_buffer()
		self:GetToneMappedImageElement():SetTexture(texHdr)
		buf = nil
		collectgarbage()
	else
		-- Clear to black
		local drawCmd = game.get_setup_command_buffer()
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.ACCESS_SHADER_READ_BIT,
			prosper.ACCESS_TRANSFER_WRITE_BIT
		)
		drawCmd:RecordClearImage(texHdr:GetImage(), Color.Black)
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.ACCESS_TRANSFER_WRITE_BIT,
			prosper.ACCESS_SHADER_READ_BIT
		)
		game.flush_setup_command_buffer()
	end
	self.m_highDefImageLoaded = true
	self.m_imgJob = nil
	self:UpdateThinkState()
end
function gui.PFMRaytracedAnimationViewport:GeneratePreviewImage(path, renderSettings)
	local imgTonemapped = self:ApplyToneMapping(shader.TONE_MAPPING_GAMMA_CORRECTION)
	if imgTonemapped == nil then
		return false
	end

	-- Update luminance
	local drawCmd = game.get_setup_command_buffer()
	local buf = self:ComputeLuminance(drawCmd)
	game.flush_setup_command_buffer()
	self:SetLuminance(shader.PFMCalcImageLuminance.read_luminance(buf))

	-- TODO: Downscale image
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(path)
	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R16G16B16A16_FLOAT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_COLOR_MAP
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	result = util.save_image(imgTonemapped, "materials/" .. thumbnailLocation, texInfo)
	if result then
		local mat = game.create_material(thumbnailLocation, "wguitextured")
		mat:SetTexture("albedo_map", thumbnailLocation)

		local luminance = self:GetLuminance()
		util.Luminance.set_material_luminance(mat, luminance)
		local db = mat:GetDataBlock()

		if renderSettings ~= nil then
			local dbRenderSettings = db:AddBlock("pfm_render_settings")
			dbRenderSettings:SetValue("int", "render_mode", tostring(renderSettings:GetRenderMode()))
			dbRenderSettings:SetValue("int", "samples", tostring(renderSettings:GetSamples()))
			dbRenderSettings:SetValue("string", "sky", renderSettings:GetSky())
			dbRenderSettings:SetValue("float", "sky_strength", tostring(renderSettings:GetSkyStrength()))
			dbRenderSettings:SetValue("float", "sky_yaw", tostring(renderSettings:GetSkyYaw()))
			dbRenderSettings:SetValue("float", "emission_strength", tostring(renderSettings:GetEmissionStrength()))
			dbRenderSettings:SetValue(
				"int",
				"max_transparency_bounces",
				tostring(renderSettings:GetMaxTransparencyBounces())
			)
			dbRenderSettings:SetValue(
				"float",
				"light_intensity_factor",
				tostring(renderSettings:GetLightIntensityFactor())
			)
			dbRenderSettings:SetValue("bool", "denoise", renderSettings:GetDenoise() and "1" or "0")
			dbRenderSettings:SetValue("bool", "render_world", renderSettings:GetRenderWorld() and "1" or "0")
			dbRenderSettings:SetValue(
				"bool",
				"render_game_entities",
				renderSettings:GetRenderGameEntities() and "1" or "0"
			)
			dbRenderSettings:SetValue("int", "cam_type", tostring(renderSettings:GetCamType()))
			dbRenderSettings:SetValue("int", "panorama_type", tostring(renderSettings:GetPanoramaType()))
			dbRenderSettings:SetValue("int", "width", tostring(renderSettings:GetWidth()))
			dbRenderSettings:SetValue("int", "height", tostring(renderSettings:GetHeight()))
			dbRenderSettings:SetValue(
				"bool",
				"camera_frustum_culling_enabled",
				renderSettings:IsCameraFrustumCullingEnabled() and "1" or "0"
			)
			dbRenderSettings:SetValue(
				"bool",
				"pvs_culling_enabled",
				renderSettings:IsPVSCullingEnabled() and "1" or "0"
			)
		end

		mat:Save(thumbnailLocation)
	end
	self:LoadPreviewImage(path, true)
	return true
end
function gui.PFMRaytracedAnimationViewport:ApplyRenderSettings(renderSettings)
	local renderTab = tool.get_filmmaker():GetRenderTab()
	if renderSettings:HasValue("render_mode") then
		renderTab:GetControl("render_mode"):SelectOption(tostring(renderSettings:GetInt("render_mode")))
	end
	if renderSettings:HasValue("samples") then
		renderTab:GetControl("samples"):SetValue(renderSettings:GetInt("samples"))
	end
	if renderSettings:HasValue("sky") then
		renderTab:GetControl("sky"):SetValue(renderSettings:GetString("sky"))
	end
	if renderSettings:HasValue("sky_strength") then
		renderTab:GetControl("sky_strength"):SetValue(renderSettings:GetFloat("sky_strength"))
	end
	if renderSettings:HasValue("sky_yaw") then
		renderTab:GetControl("sky_yaw"):SetValue(renderSettings:GetFloat("sky_yaw"))
	end
	if renderSettings:HasValue("emission_strength") then
		renderTab:GetControl("emission_strength"):SetValue(renderSettings:GetFloat("emission_strength"))
	end
	if renderSettings:HasValue("max_transparency_bounces") then
		renderTab:GetControl("max_transparency_bounces"):SetValue(renderSettings:GetInt("max_transparency_bounces"))
	end
	if renderSettings:HasValue("light_intensity_factor") then
		renderTab:GetControl("light_intensity_factor"):SetValue(renderSettings:GetFloat("light_intensity_factor"))
	end
	if renderSettings:HasValue("denoise") then
		renderTab:GetControl("denoise"):SetChecked(renderSettings:GetBool("denoise"))
	end
	if renderSettings:HasValue("render_world") then
		renderTab:GetControl("render_world"):SetChecked(renderSettings:GetBool("render_world"))
	end
	if renderSettings:HasValue("render_game_entities") then
		renderTab:GetControl("render_game_entities"):SetChecked(renderSettings:GetBool("render_game_entities"))
	end
	if renderSettings:HasValue("cam_type") then
		renderTab:GetControl("cam_type"):SelectOption(tostring(renderSettings:GetInt("cam_type")))
	end
	if renderSettings:HasValue("panorama_type") then
		renderTab:GetControl("panorama_type"):SelectOption(tostring(renderSettings:GetInt("panorama_type")))
	end
	if renderSettings:HasValue("width") and renderSettings:HasValue("height") then
		renderTab:GetControl("resolution"):ClearSelectedOption()
		renderTab
			:GetControl("resolution")
			:SetText(renderSettings:GetInt("width") .. "x" .. renderSettings:GetInt("height"))
	end
	if renderSettings:HasValue("camera_frustum_culling_enabled") then
		renderTab:GetControl("frustum_culling"):SetChecked(renderSettings:GetBool("camera_frustum_culling_enabled"))
	end
	if renderSettings:HasValue("pvs_culling_enabled") then
		renderTab:GetControl("pvs_culling"):SetChecked(renderSettings:GetBool("pvs_culling_enabled"))
	end
end
function gui.PFMRaytracedAnimationViewport:ClearCachedPreview()
	if self.m_curImagePath == nil then
		return
	end
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(self.m_curImagePath)
	asset.delete(thumbnailLocation, asset.TYPE_MATERIAL)
	asset.delete(thumbnailLocation, asset.TYPE_TEXTURE)
end
function gui.PFMRaytracedAnimationViewport:ApplyPostProcessing(tex)
	-- TODO
	-- if(self:LoadHighDefImage(true,true) == false) then return end -- TODO: Avoid reloading image
	-- self:RenderPragmaParticleSystems(tex)

	local drawCmd = game.get_setup_command_buffer()
	self.m_tex:RenderDOF(drawCmd)
	game.flush_setup_command_buffer()

	-- TODO Apply texture with particles to tonemapped img element!
	-- Also applies DOF!
	return self:ApplyToneMapping()
end
function gui.PFMRaytracedAnimationViewport:SetParticleSystemColorFactor(colFactor)
	self.m_ptColFactor = colFactor
end
function gui.PFMRaytracedAnimationViewport:GetParticleSystemColorFactor()
	return self.m_ptColFactor
end
function gui.PFMRaytracedAnimationViewport:RenderPragmaParticleSystems(tex, drawCmd, rtOut)
	tex = tex or self:GetSceneTexture()

	if self.m_testRenderer == nil then
		local entRenderer = ents.create("rasterization_renderer")
		local renderer = entRenderer:GetComponent(ents.COMPONENT_RENDERER)
		local rasterizer = entRenderer:GetComponent(ents.COMPONENT_RASTERIZATION_RENDERER)
		renderer:InitializeRenderTarget(tex:GetWidth(), tex:GetHeight())
		self.m_testRenderer = renderer
	end

	-- Temporarily change the resolution of our scene to match the raytraced scene.
	-- It will be changed back afterwards.
	local w = tex:GetWidth()
	local h = tex:GetHeight()
	local gameScene = self:GetGameScene()
	local oldResolution = gameScene:GetSize()
	--gameScene:Resize(w,h)

	local renderer = gameScene:GetRenderer()
	local ptColorFactor = gameScene:GetParticleSystemColorFactor()
	gameScene:SetParticleSystemColorFactor(self:GetParticleSystemColorFactor())
	--gameScene:SetRenderer(self.m_testRenderer)
	local isDrawCmdSet = (drawCmd ~= nil)
	drawCmd = drawCmd or game.get_setup_command_buffer()

	local drawSceneInfo = game.DrawSceneInfo()
	drawSceneInfo.scene = gameScene
	drawSceneInfo.commandBuffer = drawCmd
	-- We want to apply tonemapping manually ourselves, so we just care about the HDR output for now
	drawSceneInfo.renderFlags = bit.bor(game.RENDER_FLAG_ALL, game.RENDER_FLAG_HDR_BIT)

	-- We want to render the whole scene in the depth pre-pass, but only particles
	-- in the lighting pass. This way the particles will get obstructed by objects
	-- properly.
	drawSceneInfo:SetEntityRenderFilter(function(ent)
		return ent:HasComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	end)

	local sceneTexHdr = self.m_testRenderer:GetRenderTarget():GetTexture()
	-- We'll blit the Cycles image into the current scene texture.
	-- Since we don't clear the scene, this will make it so the Cycles image
	-- is effectively our background.
	drawCmd:RecordImageBarrier(
		tex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,
		prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier( -- TODO: Confirm that this texture is in the transfer-src layout at this point in time
		sceneTexHdr:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,
		prosper.ACCESS_TRANSFER_WRITE_BIT
	)
	drawCmd:RecordBlitImage(tex:GetImage(), sceneTexHdr:GetImage(), prosper.BlitInfo())
	drawCmd:RecordImageBarrier(
		sceneTexHdr:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_TRANSFER_WRITE_BIT,
		prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		tex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,
		prosper.ACCESS_SHADER_READ_BIT
	)

	-- Render the scene
	-- Particles will be rendered regularly, everything else will only be rendered in the depth pass
	game.draw_scene(drawSceneInfo)

	-- Compose scene texture outputs into a single HDR texture
	local rtOutput = self:ComposeSceneTextures(drawCmd, w, h, self.m_testRenderer, rtOut)
	local bufLuminance = self:ComputeLuminance(drawCmd)

	-- Initiate rendering and wait for completion
	if isDrawCmdSet == false then
		game.flush_setup_command_buffer()
	end

	-- These should match closely! (Unless the image has a lot of bloom or glow effects)
	-- print("Compute shader values: ",avgLuminance,minLuminance,maxLuminance,avgIntensity,logAvgLuminance)
	-- print("Precise values: ",imgBuf:CalcLuminance())

	-- We'll need these for some tone-mapping algorithms
	self.m_tex:SetLuminance(shader.PFMCalcImageLuminance.read_luminance(bufLuminance))

	-- Resize back to the original resolution
	--gameScene:Resize(oldResolution.x,oldResolution.y)
	--gameScene:SetRenderer(renderer)
	gameScene:SetParticleSystemColorFactor(ptColorFactor)
	return rtOutput
end
function gui.PFMRaytracedAnimationViewport:UpdateThinkState()
	if self.m_imgJob ~= nil or self.m_tLoadHighDefImageDelay ~= nil then
		self:EnableThinking()
		self:SetAlwaysUpdate(true)
		return
	end
	gui.RaytracedViewport.UpdateThinkState(self)
end
function gui.PFMRaytracedAnimationViewport:OnThink()
	gui.RaytracedViewport.OnThink(self)

	if self.m_tLoadHighDefImageDelay ~= nil and time.real_time() >= self.m_tLoadHighDefImageDelay then
		self.m_tLoadHighDefImageDelay = nil
		self:LoadHighDefImage()
	end

	if self.m_imgJob == nil or self.m_imgJob:IsComplete() == false then
		return
	end
	self:InitializeHighDefImage()
end
function gui.PFMRaytracedAnimationViewport:InitializeStagingTexture(w, h)
	if
		self.m_stagingTexture ~= nil
		and self.m_stagingTexture:GetWidth() == w
		and self.m_stagingTexture:GetHeight() == h
	then
		return self.m_stagingTexture
	end
	self.m_stagingTexture = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = prosper.FORMAT_R32G32B32A32_UNORM
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT, prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local img = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local tex =
		prosper.create_texture(img, prosper.TextureCreateInfo(), prosper.ImageViewCreateInfo(), samplerCreateInfo)
	tex:SetDebugName("raytraced_animation_viewport_staging_tex")
	self.m_stagingTexture = tex

	self.m_stagingRenderTarget =
		prosper.create_render_target(prosper.RenderTargetCreateInfo(), { tex }, shader.Graphics.get_render_pass())
	return tex
end
gui.register("WIPFMRaytracedAnimationViewport", gui.PFMRaytracedAnimationViewport)

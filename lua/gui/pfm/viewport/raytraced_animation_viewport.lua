-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/viewport/raytraced_viewport.lua")
include("/gui/pfm/widgets/thumbnail_image.lua")

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
				local pContext = gui.open_context_menu(self)
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
					local db = mat:GetPropertyDataBlock()
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
function gui.PFMRaytracedAnimationViewport:ClearTexture()
	self.m_tex:ClearTexture()
end
function gui.PFMRaytracedAnimationViewport:SetPreviewImage(imgFilePath)
	if imgFilePath == nil then
		self.m_tex:ClearTexture()
	else
		self.m_tex:SetImage(imgFilePath)
	end
end
function gui.PFMRaytracedAnimationViewport:SetSaveAsHDR(saveAsHdr)
	self.m_saveAsHdr = saveAsHdr
end
function gui.PFMRaytracedAnimationViewport:SaveAs(format, hdr)
	format = format or self.m_imgSaveFormat
	local dialoge = pfm.create_file_save_dialog(function(pDialoge)
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
	gui.RaytracedViewport.UpdateThinkState(self)
end
function gui.PFMRaytracedAnimationViewport:OnThink()
	gui.RaytracedViewport.OnThink(self)
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
gui.register("pfm_raytraced_animation_viewport", gui.PFMRaytracedAnimationViewport)

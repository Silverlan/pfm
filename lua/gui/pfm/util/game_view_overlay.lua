--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_depth_of_field.lua")
include("/shaders/pfm/pfm_scene_composition.lua")

util.register_class("util.ImagePostProcessor")
function util.ImagePostProcessor:__init()
end

function util.ImagePostProcessor:Remove()

end
function util.ImagePostProcessor:InitializeSceneTexture(w,h)
	if(self.m_hdrTex ~= nil and self.m_hdrTex:GetWidth() == w and self.m_hdrTex:GetHeight() == h) then return self.m_hdrTex end
	self.m_hdrTex = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = shader.Scene3D.RENDER_PASS_COLOR_FORMAT
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local imgHdr = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local texHdr = prosper.create_texture(imgHdr,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	texHdr:SetDebugName("raytraced_viewport_scene_tex")
	self.m_hdrTex = texHdr

	self.m_tex:SetTexture(texHdr)

	local shaderComposition = shader.get("pfm_scene_composition")
	self.m_hdrRt = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{self.m_hdrTex},shaderComposition:GetRenderPass())

	self.m_dsSceneComposition = shaderComposition:CreateDescriptorSet(shader.PFMSceneComposition.DESCRIPTOR_SET_TEXTURE)
	return texHdr
end
function util.ImagePostProcessor:InitializeDepthTexture(w,h,nearZ,farZ)
	self.m_tex:SetDepthBounds(nearZ,farZ)
	if(self.m_depthTex ~= nil and self.m_depthTex:GetWidth() == w and self.m_depthTex:GetHeight() == h) then return end
	self.m_depthTex = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = shader.Scene3D.RENDER_PASS_DEPTH_FORMAT
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local imgDepth = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local texDepth = prosper.create_texture(imgDepth,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	texDepth:SetDebugName("raytraced_viewport_depth_tex")
	self.m_depthTex = texDepth
	self.m_tex:SetDepthTexture(texDepth)
end
function util.ImagePostProcessor:UpdateGameSceneTextures()
	local gameScene = self:GetGameScene()
	local cam = gameScene:GetActiveCamera()
	local renderer = self.m_testRenderer--gameScene:GetRenderer()
	if(renderer == nil or cam == nil) then return end
	self:InitializeDepthTexture(gameScene:GetWidth(),gameScene:GetHeight(),cam:GetNearZ(),cam:GetFarZ())

	local drawCmd = game.get_setup_command_buffer()
	local depthTex = renderer:GetPostPrepassDepthTexture()
	drawCmd:RecordImageBarrier(
		depthTex:GetImage(),
		prosper.PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		bit.bor(prosper.ACCESS_MEMORY_READ_BIT,prosper.ACCESS_MEMORY_WRITE_BIT),prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordBlitImage(depthTex:GetImage(),self.m_depthTex:GetImage(),prosper.BlitInfo())
	drawCmd:RecordImageBarrier(
		depthTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,bit.bor(prosper.ACCESS_MEMORY_READ_BIT,prosper.ACCESS_MEMORY_WRITE_BIT)
	)
	self:RenderParticleSystemDepth(drawCmd)
	game.flush_setup_command_buffer()
end
function util.ImagePostProcessor:RenderParticleSystemDepth(drawCmd)
	-- TODO: Skip this step if we're not using DOF
	-- Particle systems are usually not written to the depth buffer,
	-- however to properly calculate depth of field for particles, they
	-- need to be included. We'll add a render pass specifically for rendering
	-- particle depths here.
	drawCmd:RecordImageBarrier(
		self.m_depthTex:GetImage(),
		prosper.PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT,prosper.PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
		prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
		bit.bor(prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT,prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT),bit.bor(prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT,prosper.ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
	)
	local rtDepth = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{self.m_depthTex},shader.BaseParticle2D.get_depth_pipeline_render_pass())
	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(rtDepth))) then
		local gameScene = self:GetGameScene()
		local renderer = self.m_testRenderer--gameScene:GetRenderer()
		local particleSystems = renderer:GetRenderParticleSystems()
		for _,pts in ipairs(particleSystems) do
			pts:Render(drawCmd,renderer,ents.ParticleSystemComponent.RENDER_FLAG_BIT_DEPTH_ONLY)
		end
		drawCmd:RecordEndRenderPass()
	end
end
function util.ImagePostProcessor:ApplyDepthOfField()
	self:InitializeSceneTexture(w,h)
	local sceneHdrTex = renderer:GetHDRPresentationTexture()
	local sceneBloomTex = renderer:GetBloomTexture()
	local sceneGlowTex = renderer:GetGlowTexture()

	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR,sceneHdrTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM,sceneBloomTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_GLOW,sceneGlowTex)

	-- Scene HDR texture is in transfer-src layout
	-- Bloom texture is in shader-read-only layout
	-- Glow texture is in color-attachment layout
	-- Move them all to shader-read-only layout
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	--

	-- Move target image to color-attachment layout
	drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--

	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(self.m_hdrRt))) then
		local shaderComposition = shader.get("pfm_scene_composition")
		-- TODO
		local bloomScale = 1.0
		local glowScale = 1.0
		shaderComposition:Draw(drawCmd,self.m_dsSceneComposition,bloomScale,glowScale)
		drawCmd:RecordEndRenderPass()
	end
	-- (Render pass has already moved target image to shader-read layout)
	--[[drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)]]
	--

	-- Move scene textures back to original layouts
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
end
function util.ImagePostProcessor:ComposeSceneTextures(drawCmd,w,h,renderer,rtOut)
	self:InitializeSceneTexture(w,h)
	rtOut = rtOut or self.m_hdrRt
	local sceneHdrTex = renderer:GetHDRPresentationTexture()
	local sceneBloomTex = renderer:GetBloomTexture()
	local sceneGlowTex = renderer:GetGlowTexture()

	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_HDR_COLOR,sceneHdrTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_BLOOM,sceneBloomTex)
	self.m_dsSceneComposition:SetBindingTexture(shader.PFMSceneComposition.TEXTURE_BINDING_GLOW,sceneGlowTex)

	-- Scene HDR texture is in transfer-src layout
	-- Bloom texture is in shader-read-only layout
	-- Glow texture is in color-attachment layout
	-- Move them all to shader-read-only layout
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	--

	-- Move target image to color-attachment layout
	drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--

	if(drawCmd:RecordBeginRenderPass(prosper.RenderPassInfo(rtOut))) then
		local shaderComposition = shader.get("pfm_scene_composition")
		-- TODO
		local bloomScale = 1.0
		local glowScale = 1.0
		shaderComposition:Draw(drawCmd,self.m_dsSceneComposition,bloomScale,glowScale)
		drawCmd:RecordEndRenderPass()
	end
	-- (Render pass has already moved target image to shader-read layout)
	--[[drawCmd:RecordImageBarrier(
		self.m_hdrTex:GetImage(),
		prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
	)]]
	--

	-- Move scene textures back to original layouts
	drawCmd:RecordImageBarrier(
		sceneHdrTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneBloomTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	drawCmd:RecordImageBarrier(
		sceneGlowTex:GetImage(),
		prosper.PIPELINE_STAGE_FRAGMENT_SHADER_BIT,prosper.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT
	)
	--
	return rtOut
end

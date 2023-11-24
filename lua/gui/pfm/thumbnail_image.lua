--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.util.downscale_thumbnail_image(imgBuf, width)
	local w = imgBuf:GetWidth()
	local h = imgBuf:GetHeight()

	-- Maximum extent for preview image
	-- TODO: Make this dependent on the resolution
	local maxPreviewExtent = width or 1600
	if w > maxPreviewExtent then
		local f = maxPreviewExtent / w
		w = maxPreviewExtent
		h = math.round(h * f)
	end
	if h > maxPreviewExtent then
		local f = maxPreviewExtent / h
		h = maxPreviewExtent
		w = math.round(w * f)
	end

	local downscaled = imgBuf:Copy()
	if opencv ~= nil then
		downscaled = opencv.resize(imgBuf, w, h)
	end
	return downscaled
end
function pfm.util.generate_thumbnail_texture(imgBuf, imgCreateInfo)
	local downscaled = pfm.util.downscale_thumbnail_image(imgBuf)
	imgCreateInfo.usageFlags = bit.bor(
		imgCreateInfo.usageFlags,
		prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
		prosper.IMAGE_USAGE_TRANSFER_SRC_BIT,
		prosper.IMAGE_USAGE_TRANSFER_DST_BIT
	)

	imgCreateInfo.width = downscaled:GetWidth()
	imgCreateInfo.height = downscaled:GetHeight()
	local img = prosper.create_image(downscaled, imgCreateInfo)

	local imgViewCreateInfo = prosper.ImageViewCreateInfo()
	imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	return prosper.create_texture(img, prosper.TextureCreateInfo(), imgViewCreateInfo, samplerCreateInfo)
end

local Element = util.register_class("WIPFMThumbnailImage", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	local elTex = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_elTex = elTex
end
function Element:LoadImage(imgPath)
	self:Reset()

	if self:LoadPreviewImage(imgPath) == false then
		return
	end
	self.m_curImgPath = imgPath

	self:SetThinkingEnabled(true)
	self.m_tLoadHighDefImage = time.real_time() + 0.2
end
function Element:OnThink()
	if self.m_tLoadHighDefImage ~= nil then
		if time.real_time() < self.m_tLoadHighDefImage then
			return
		end
		self.m_tLoadHighDefImage = nil
		self:LoadHighResolutionImage()
	end
	if self.m_imgJob == nil then
		self:Reset()
		return
	end
	if self.m_imgJob:IsComplete() == false then
		return
	end
	if self.m_imgJob:IsSuccessful() then
		self:InitializeHighDefImage(self.m_imgJob:GetResult())
	else
		self:Reset()
	end
end

function Element:LoadHighResolutionImage()
	-- Loading the image may take some time, so we'll do it on a separate thread in the background.
	-- Once loaded, the algorithm continues in :OnThink
	self.m_imgJob = util.load_image(self.m_curImgPath, true, util.ImageBuffer.FORMAT_RGBA_LDR)
	if self.m_imgJob == nil then
		self:Reset()
		return
	end
	self.m_imgJob:Start()
end

function Element:Reset()
	if self.m_imgJob ~= nil then
		self.m_imgJob:Cancel()
		self.m_imgJob = nil
	end
	if util.is_valid(self.m_uiElement) then
		self.m_uiElement:SetVisible(false)
	end
	self.m_curImgPath = nil
	self.m_highDefImageLoaded = false
	self:SetThinkingEnabled(false)
end

function Element:LoadPreviewImage(filePath, reload, dontGenerate)
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

	self.m_curImagePath = filePath
	self.m_highDefImageLoaded = false

	local mat, matPath = self:LoadPreviewMaterial(reload)
	if mat == nil or mat:IsError() then
		self.m_elTex:SetVisible(false)
		return false
	end
	self.m_elTex:SetVisible(true)
	self.m_elTex:SetMaterial(matPath)
	return true
end
function Element:InitializeHighDefImage(imgBuf)
	pfm.log("Initializing high-definition thumbnail...", pfm.LOG_CATEGORY_PFM)
	local tex = pfm.util.generate_thumbnail_texture(imgBuf, prosper.create_image_create_info(imgBuf))
	self.m_elTex:SetTexture(tex)
	self.m_elTex:SetVisible(true)

	self:SetThinkingEnabled(false)
	self.m_imgJob = nil
end
function Element:GeneratePreviewImage(path)
	local imgBuf = util.load_image(path, false)
	if imgBuf == nil then
		return false
	end

	imgBuf = pfm.util.downscale_thumbnail_image(imgBuf, 512)

	-- Create texture
	local imgCreateInfo = prosper.create_image_create_info(imgBuf)
	local img = prosper.create_image(imgBuf, imgCreateInfo)
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(path)
	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R8G8B8A8_UINT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_COLOR_MAP
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	pfm.log("Saving thumbnail image as '" .. thumbnailLocation .. "'...", pfm.LOG_CATEGORY_PFM)
	local result = util.save_image(img, "materials/" .. thumbnailLocation, texInfo)
	if result then
		local mat = game.create_material(thumbnailLocation, "wguitextured")
		mat:SetTexture("albedo_map", thumbnailLocation)

		mat:Save(thumbnailLocation)
	end
	self:LoadPreviewImage(path, true)
	return true
end
function Element:LoadPreviewMaterial(reload)
	if self.m_curImagePath == nil then
		return
	end
	pfm.log("Loading preview thumbnail '" .. self.m_curImagePath .. "'...", pfm.LOG_CATEGORY_PFM)
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(self.m_curImagePath)
	local matPath = thumbnailLocation
	if asset.exists(matPath, asset.TYPE_MATERIAL) == false then
		return
	end
	return game.load_material(thumbnailLocation, reload or false, true), thumbnailLocation
end
gui.register("WIPFMThumbnailImage", Element)

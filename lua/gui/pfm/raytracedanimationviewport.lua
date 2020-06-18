--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/raytracedviewport.lua")

util.register_class("gui.PFMRaytracedAnimationViewport",gui.RaytracedViewport)
function gui.PFMRaytracedAnimationViewport:__init()
	gui.RaytracedViewport.__init(self)
end
function gui.PFMRaytracedAnimationViewport:OnInitialize()
	gui.RaytracedViewport.OnInitialize(self)

	local elImg = self:GetToneMappedImageElement()
	elImg:SetMouseInputEnabled(true)
	elImg:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local imgBuf = (self.m_rtJob ~= nil) and self.m_rtJob:GetRenderResult()
			if(imgBuf ~= nil) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext) == false) then return end
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem(locale.get_text("save_as"),function()
					self:SaveAs(false)
				end)
				pContext:AddItem(locale.get_text("pfm_save_as_hdr"),function()
					self:SaveAs(true)
				end)
				pContext:Update()
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.PFMRaytracedAnimationViewport:SaveAs(saveAsHDR)
	saveAsHDR = saveAsHDR or false
	local dialoge = gui.create_file_save_dialog(function(pDialoge)
		local fname = pDialoge:GetFilePath(true)
		file.create_path(file.get_file_path(fname))

		self:SaveImage(fname,saveAsHDR)
	end)
	dialoge:SetExtensions({saveAsHDR and "hdr" or "png"})
	dialoge:SetRootPath(util.get_addon_path())
	dialoge:Update()
end
function gui.PFMRaytracedAnimationViewport:GetRTJob() return self.m_rtJob end
function gui.PFMRaytracedAnimationViewport:LoadPreviewImage(filePath,reload,dontGenerate)
	if(self.m_imgJob ~= nil) then self.m_imgJob:Cancel() end
	self.m_imgJob = nil

	local displayTex = self:GetToneMappedImageElement()
	displayTex:SetTexture()

	self.m_curImagePath = filePath
	self.m_highDefImageLoaded = false

	local thumbnailLocation = "render_previews/" .. util.get_string_hash(filePath)
	local matPath = "materials/" .. thumbnailLocation .. ".wmi"
	if(file.exists(matPath) == false) then
		if(dontGenerate == true) then return false end
		if(self:GeneratePreviewImage(filePath) == false) then return false end
	end
	local mat = game.load_material(thumbnailLocation,reload or false,true)
	if(mat == nil or mat:IsError()) then return false end

	local luminance = shader.PFMTonemapping.Luminance()
	local db = mat:GetDataBlock()
	local lum = db:FindBlock("luminance")
	if(lum ~= nil) then
		luminance:SetAvgLuminance(lum:GetFloat("average"))
		luminance:SetMinLuminance(lum:GetFloat("minimum"))
		luminance:SetMaxLuminance(lum:GetFloat("maximum"))
		luminance:SetAvgIntensity(lum:GetVector("average_intensity"))
		luminance:SetAvgLuminanceLog(lum:GetFloat("average_log"))
	end
	displayTex:SetLuminance(luminance)
	local tex = mat:GetTextureInfo("albedo_map")
	tex = (tex ~= nil) and tex:GetTexture() or nil
	tex = (tex ~= nil) and tex:GetVkTexture() or nil
	if(tex == nil) then return false end
	displayTex:SetTexture(tex)

	self.m_tLoadHighDefImageDelay = time.real_time() +0.2
	self:UpdateThinkState()
	return true
end
function gui.PFMRaytracedAnimationViewport:LoadHighDefImage(waitForCompletion)
	if(self.m_highDefImageLoaded == true) then return true end
	if(self.m_imgJob ~= nil) then
		if(waitForCompletion) then
			self.m_imgJob:Wait()
			self:InitializeHighDefImage()
			return true
		end
		return false
	end
	self.m_tLoadHighDefImageDelay = nil
	if(self.m_curImagePath == nil) then return false end
	local path = self.m_curImagePath
	if(self.m_imgJob ~= nil) then self.m_imgJob:Cancel() end
	-- Loading the image may take some time, so we'll do it on a separate thread in the background.
	-- Once loaded, the algorithm continues in :OnThink
	self.m_imgJob = util.load_image(path .. ".hdr",true,util.ImageBuffer.FORMAT_RGBA_HDR)
	if(self.m_imgJob == nil) then return false end
	self.m_imgJob:Start()

	self:UpdateThinkState()
	if(waitForCompletion) then return self:LoadHighDefImage(true) end
	return false
end
function gui.PFMRaytracedAnimationViewport:InitializeHighDefImage()
	if(self.m_imgJob:IsSuccessful()) then
		-- HDR image has been loaded; Apply it instead of the preview image
		local imgBuf = self.m_imgJob:GetResult()
		local texHdr = self:InitializeSceneTexture(imgBuf:GetWidth(),imgBuf:GetHeight())
		if(texHdr == nil) then return end
		local buf = prosper.util.allocate_temporary_buffer(imgBuf:GetSize())
		buf:WriteMemory(0,imgBuf:GetData())

		local drawCmd = game.get_setup_command_buffer()
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_WRITE_BIT
		)
		drawCmd:RecordBufferBarrier(
			buf,
			prosper.SHADER_STAGE_ALL,prosper.SHADER_STAGE_ALL,
			prosper.ACCESS_MEMORY_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
		)
		drawCmd:RecordCopyBufferToImage(buf,texHdr:GetImage())
		drawCmd:RecordBufferBarrier(
			buf,
			prosper.SHADER_STAGE_ALL,prosper.SHADER_STAGE_ALL,
			prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_MEMORY_WRITE_BIT
		)
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.ACCESS_TRANSFER_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
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
			prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
			prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_WRITE_BIT
		)
		drawCmd:RecordClearImage(texHdr:GetImage(),Color.Black)
		drawCmd:RecordImageBarrier(
			texHdr:GetImage(),
			prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
			prosper.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			prosper.ACCESS_TRANSFER_WRITE_BIT,prosper.ACCESS_SHADER_READ_BIT
		)
		game.flush_setup_command_buffer()
	end
	self.m_highDefImageLoaded = true
	self.m_imgJob = nil
	self:UpdateThinkState()
end
function gui.PFMRaytracedAnimationViewport:GeneratePreviewImage(path)
	local imgTonemapped = self:ApplyToneMapping(shader.TONE_MAPPING_GAMMA_CORRECTION)
	if(imgTonemapped == nil) then return false end

	-- Update luminance
	local drawCmd = game.get_setup_command_buffer()
	local buf = self:ComputeLuminance(drawCmd)
	game.flush_setup_command_buffer()
	self:SetLuminance(self:ReadLuminance(buf))

	-- TODO: Downscale image
	local thumbnailLocation = "render_previews/" .. util.get_string_hash(path)
	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R16G16B16A16_FLOAT
	texInfo.outputFormat = util.TextureInfo.OUTPUT_FORMAT_COLOR_MAP
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	result = util.save_image(imgTonemapped,"materials/" .. thumbnailLocation,texInfo)
	if(result) then
		local mat = game.create_material(thumbnailLocation,"wguitextured")
		mat:SetTexture("albedo_map",thumbnailLocation)

		local luminance = self:GetLuminance()
		local db = mat:GetDataBlock()
		local lum = db:AddBlock("luminance")
		lum:SetValue("float","average",tostring(luminance:GetAvgLuminance()))
		lum:SetValue("float","average_log",tostring(luminance:GetAvgLuminanceLog()))
		lum:SetValue("float","minimum",tostring(luminance:GetMinLuminance()))
		lum:SetValue("float","maximum",tostring(luminance:GetMaxLuminance()))
		lum:SetValue("vector","average_intensity",tostring(luminance:GetAvgIntensity()))
		mat:Save(thumbnailLocation)
	end

	self:LoadPreviewImage(path,true)
	return true
end
function gui.PFMRaytracedAnimationViewport:SaveImage(path,saveAsHDR)
	saveAsHDR = saveAsHDR or false

	-- We need the high-quality HDR image
	if(self:LoadHighDefImage(true) == false) then return false end
	local img
	local imgFormat
	local imgBufFormat
	if(saveAsHDR) then
		-- Image is not tonemapped, we'll save it with the original HDR colors
		img = self:GetSceneTexture():GetImage()
		imgFormat = util.IMAGE_FORMAT_HDR
		imgBufFormat = util.ImageBuffer.FORMAT_RGBA_HDR
	else
		img = self:ApplyToneMapping()
		if(img == nil) then return false end
		imgFormat = util.IMAGE_FORMAT_PNG
		imgBufFormat = util.ImageBuffer.FORMAT_RGBA_LDR
	end

	local buf = prosper.util.allocate_temporary_buffer(img:GetWidth() *img:GetHeight() *prosper.get_byte_size(img:GetFormat()))
	local drawCmd = game.get_setup_command_buffer()
	drawCmd:RecordImageBarrier(
		img,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,prosper.ACCESS_TRANSFER_READ_BIT
	)
	drawCmd:RecordCopyImageToBuffer(img,prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,buf,prosper.BufferImageCopyInfo())
	drawCmd:RecordImageBarrier(
		img,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		prosper.ACCESS_TRANSFER_READ_BIT,prosper.ACCESS_SHADER_READ_BIT
	)
	game.flush_setup_command_buffer()
	local imgData = buf:ReadMemory()
	local imgBuf = util.ImageBuffer.Create(img:GetWidth(),img:GetHeight(),imgBufFormat,imgData)

	local result = util.save_image(imgBuf,path,imgFormat)
	if(result == false) then
		pfm.log("Unable to save image as '" .. path .. "'!",pfm.LOG_CATEGORY_PFM_INTERFACE,pfm.LOG_SEVERITY_WARNING)
	end
	buf = nil
	collectgarbage()
	return result
end
function gui.PFMRaytracedAnimationViewport:UpdateThinkState()
	if(self.m_imgJob ~= nil or self.m_tLoadHighDefImageDelay ~= nil) then
		self:EnableThinking()
		self:SetAlwaysUpdate(true)
		return
	end
	gui.RaytracedViewport.UpdateThinkState(self)
end
function gui.PFMRaytracedAnimationViewport:ApplyToneMapping(toneMapping)
	toneMapping = toneMapping or self:GetToneMapping()
	if(self:LoadHighDefImage(true) == false) then return end
	local hdrTex = self:GetSceneTexture()
	if(hdrTex == nil) then return end
	local w = hdrTex:GetWidth()
	local h = hdrTex:GetHeight()
	self:InitializeExportTexture(w,h)
	local drawCmd = game.get_setup_command_buffer()
	local exportImg = self.m_exportTexture:GetImage()
	drawCmd:RecordImageBarrier(
		exportImg,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		prosper.ACCESS_SHADER_READ_BIT,bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
	)

	local rpInfo = prosper.RenderPassInfo(self.m_exportRenderTarget)
	if(drawCmd:RecordBeginRenderPass(rpInfo)) then
		self:GetToneMappedImageElement():Render(drawCmd,Mat4(1.0),toneMapping)
		drawCmd:RecordEndRenderPass()
	end

	drawCmd:RecordImageBarrier(
		exportImg,
		prosper.SHADER_STAGE_FRAGMENT_BIT,prosper.SHADER_STAGE_FRAGMENT_BIT,
		prosper.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		bit.bor(prosper.ACCESS_COLOR_ATTACHMENT_READ_BIT,prosper.ACCESS_COLOR_ATTACHMENT_WRITE_BIT),prosper.ACCESS_SHADER_READ_BIT
	)
	game.flush_setup_command_buffer()
	return exportImg
end
function gui.PFMRaytracedAnimationViewport:OnThink()
	gui.RaytracedViewport.OnThink(self)

	if(self.m_tLoadHighDefImageDelay ~= nil and time.real_time() >= self.m_tLoadHighDefImageDelay) then
		self.m_tLoadHighDefImageDelay = nil
		self:LoadHighDefImage()
	end

	if(self.m_imgJob == nil or self.m_imgJob:IsComplete() == false) then return end
	self:InitializeHighDefImage()
end
function gui.PFMRaytracedAnimationViewport:InitializeExportTexture(w,h)
	if(self.m_exportTexture ~= nil and self.m_exportTexture:GetWidth() == w and self.m_exportTexture:GetHeight() == h) then return self.m_exportTexture end
	self.m_exportTexture = nil
	collectgarbage() -- Make sure the old texture is cleared from cache

	local imgCreateInfo = prosper.ImageCreateInfo()
	imgCreateInfo.width = w
	imgCreateInfo.height = h
	imgCreateInfo.format = prosper.FORMAT_R8G8B8A8_UNORM
	imgCreateInfo.usageFlags = bit.bor(prosper.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,prosper.IMAGE_USAGE_SAMPLED_BIT)
	imgCreateInfo.tiling = prosper.IMAGE_TILING_OPTIMAL
	imgCreateInfo.memoryFeatures = prosper.MEMORY_FEATURE_GPU_BULK_BIT
	imgCreateInfo.postCreateLayout = prosper.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	local img = prosper.create_image(imgCreateInfo)
	local samplerCreateInfo = prosper.SamplerCreateInfo()
	samplerCreateInfo.addressModeU = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE -- TODO: This should be the default for the SamplerCreateInfo struct; TODO: Add additional constructors
	samplerCreateInfo.addressModeV = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	samplerCreateInfo.addressModeW = prosper.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
	local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),prosper.ImageViewCreateInfo(),samplerCreateInfo)
	self.m_exportTexture = tex

	self.m_exportRenderTarget = prosper.create_render_target(prosper.RenderTargetCreateInfo(),{tex},shader.Graphics.get_render_pass())
	return tex
end
gui.register("WIPFMRaytracedAnimationViewport",gui.PFMRaytracedAnimationViewport)

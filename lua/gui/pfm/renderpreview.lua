--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/aspectratio.lua")

util.register_class("gui.PFMRenderPreview",gui.Base)

function gui.PFMRenderPreview:__init()
	gui.Base.__init(self)
end
function gui.PFMRenderPreview:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128,hViewport +hBottom)

	self.m_vpBg = gui.create("WIRect",self,0,0,self:GetWidth(),hViewport,0,0,1,1)
	self.m_vpBg:SetColor(Color.Black)
	self.m_vpBg:SetMouseInputEnabled(true)
	self.m_vpBg:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem("Save As...",function()
				local dialoge = gui.create_file_save_dialog(function(pDialoge,file)
					--self:SaveModel(file:sub(8)) -- Strip "models/"-prefix
					print("TODO: Save image")
					--[[local writeInfo = util.ImageSaveInfo()
					writeInfo.outputFormat = 
					util.save_image(fileName,)]]
				end)
				dialoge:SetRootPath("models")
				dialoge:SetExtensions({"png"})
				dialoge:Update()
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	self.m_aspectRatioWrapper = gui.create("WIAspectRatio",self.m_vpBg,0,0,self.m_vpBg:GetWidth(),self.m_vpBg:GetHeight(),0,0,1,1)

	self.m_preview = gui.create("WITexturedRect",self.m_aspectRatioWrapper)
	self:InitializeControls()
	
	self:EnableThinking()
end
function gui.PFMRenderPreview:InitializeControls()
	local controls = gui.create("WIHBox",self,0,self.m_vpBg:GetBottom() +4)
	self.m_btRefreshPreview = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_rotate","gui/pfm/icon_manipulator_rotate_activated",function()
		self:Refresh(512,512,4)
	end)
	self.m_btRefresh = gui.PFMButton.create(controls,"gui/pfm/icon_manipulator_rotate","gui/pfm/icon_manipulator_rotate_activated",function()
		self:Refresh(1024,1024,512)
	end)

	self.m_toneMapping = gui.create("WIDropDownMenu",controls)
	self.m_toneMapping:SetText("Tonemapping")
	local toneMappingOptions = {
		"Gamma Correction",
		"Reinhard",
		"Hejil-Richard",
		"Uncharted",
		"Aces",
		"Gran Turismo"
	}
	local toneMappingEnums = {
		util.ImageBuffer.TONE_MAPPING_GAMMA_CORRECTION,
		util.ImageBuffer.TONE_MAPPING_REINHARD,
		util.ImageBuffer.TONE_MAPPING_HEJIL_RICHARD,
		util.ImageBuffer.TONE_MAPPING_UNCHARTED,
		util.ImageBuffer.TONE_MAPPING_ACES,
		util.ImageBuffer.TONE_MAPPING_GRAN_TURISMO
	}
	for _,option in ipairs(toneMappingOptions) do
		self.m_toneMapping:AddOption(option)
	end
	self.m_toneMapping:AddCallback("OnOptionSelected",function(el,idx)
		print("A")
		if(self.m_imageResultBuffer == nil) then return end
		print("B")
		local imgBuffer = self.m_imageResultBuffer:ApplyToneMapping(toneMappingEnums[idx +1])

		-- TODO: Update image data instead of creating new one!
		local img = vulkan.create_image(imgBuffer)
		local imgViewCreateInfo = vulkan.ImageViewCreateInfo()
		imgViewCreateInfo.swizzleAlpha = vulkan.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
		local tex = vulkan.create_texture(img,vulkan.TextureCreateInfo(),imgViewCreateInfo,vulkan.SamplerCreateInfo())
		
		if(util.is_valid(self.m_preview)) then self.m_preview:SetTexture(tex) end
	end)
	self.m_toneMapping:SetSize(128,25)

	controls:SetHeight(self.m_btRefreshPreview:GetHeight())
	controls:Update()
	controls:SetAnchor(0,1,0,1)
end
function gui.PFMRenderPreview:OnRemove()
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
end
function gui.PFMRenderPreview:OnThink()
	if(self.m_raytracingJob == nil) then return end
	local progress = self.m_raytracingJob:GetProgress()
	if(progress ~= self.m_lastProgress) then
		self.m_lastProgress = progress
		self:CallCallbacks("OnProgressChanged",self.m_lastProgress)
	end
	if(self:IsComplete() == false) then return end
	if(self.m_raytracingJob:IsSuccessful()) then
		local imgBuffer = self.m_raytracingJob:GetResult()
		self.m_imageResultBuffer = imgBuffer
		local img = vulkan.create_image(imgBuffer)
		local imgViewCreateInfo = vulkan.ImageViewCreateInfo()
		imgViewCreateInfo.swizzleAlpha = vulkan.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
		local tex = vulkan.create_texture(img,vulkan.TextureCreateInfo(),imgViewCreateInfo,vulkan.SamplerCreateInfo())
		
		if(util.is_valid(self.m_preview)) then self.m_preview:SetTexture(tex) end
	end
	self.m_raytracingJob = nil
end
function gui.PFMRenderPreview:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function gui.PFMRenderPreview:GetProgress()
	if(self.m_raytracingJob == nil) then return 1.0 end
	return self.m_raytracingJob:GetProgress()
end
function gui.PFMRenderPreview:Refresh(width,height,samples)
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	local job = util.capture_raytraced_screenshot(width,height,samples)
	job:Start()
	self.m_raytracingJob = job

	self.m_lastProgress = 0.0
end
gui.register("WIPFMRenderPreview",gui.PFMRenderPreview)

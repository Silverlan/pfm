--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMRenderPreviewWindow")
function gui.PFMRenderPreviewWindow:__init(parent)
	local frame = gui.create("WIFrame",parent)
	frame:SetTitle(locale.get_text("pfm_render_preview"))

	local margin = 10
	local tex = gui.create("WITexturedRect",frame)
	tex:SetSize(256,256)
	tex:SetPos(margin,24)
	self.m_preview = tex

	frame:SetWidth(tex:GetRight() +margin)
	frame:SetHeight(tex:GetBottom() +margin *2)
	frame:SetResizeRatioLocked(true)
	frame:SetCloseButtonEnabled(false)
	frame:SetMinSize(128,128)
	frame:SetMaxSize(1024,1024)
	tex:SetAnchor(0,0,1,1)
	self.m_previewFrame = frame
	frame:AddCallback("Think",function()
		self:OnThink()
	end)

	local raytracingProgressBar = gui.create("WIProgressBar",frame)
	raytracingProgressBar:SetSize(tex:GetWidth(),10)
	raytracingProgressBar:SetPos(tex:GetLeft(),tex:GetBottom())
	raytracingProgressBar:SetColor(Color.Lime)
	raytracingProgressBar:SetVisible(false)
	raytracingProgressBar:SetAnchor(0,1,1,1)
	self.m_raytracingProgressBar = raytracingProgressBar

	local btRefresh = gui.create("WITexturedRect",frame)
	btRefresh:SetMaterial("gui/pfm/refresh")
	btRefresh:SetSize(12,12)
	btRefresh:SetTop(5)
	local elTitle = frame:FindDescendantByName("frame_title")
	if(elTitle ~= nil) then btRefresh:SetLeft(elTitle:GetRight() +5) end
	btRefresh:SetMouseInputEnabled(true)
	btRefresh:AddCallback("OnMousePressed",function()
		self:Refresh()
	end)
end
function gui.PFMRenderPreviewWindow:OnInitialize()
	gui.Base.OnInitialize(self)
	self:EnableThinking()
end
function gui.PFMRenderPreviewWindow:OnThink()
	if(self.m_raytracingJob == nil) then return end
	local progress = self.m_raytracingJob:GetProgress()
	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetProgress(progress) end
	if(self.m_raytracingJob:IsComplete() == false) then return end
	if(self.m_raytracingJob:IsSuccessful()) then
		local imgBuffer = self.m_raytracingJob:GetResult()
		local img = prosper.create_image(imgBuffer)
		local imgViewCreateInfo = prosper.ImageViewCreateInfo()
		imgViewCreateInfo.swizzleAlpha = prosper.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
		local tex = prosper.create_texture(img,prosper.TextureCreateInfo(),imgViewCreateInfo,prosper.SamplerCreateInfo())
		tex:SetDebugName("render_preview_window_tex")
		
		if(util.is_valid(self.m_preview)) then self.m_preview:SetTexture(tex) end
		if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetVisible(false) end
	end
	self.m_raytracingJob = nil
end
function gui.PFMRenderPreviewWindow:Refresh()
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	local job = util.capture_raytraced_screenshot(512,512,4)
	job:Start()
	self.m_raytracingJob = job

	if(util.is_valid(self.m_raytracingProgressBar)) then self.m_raytracingProgressBar:SetVisible(true) end
end
function gui.PFMRenderPreviewWindow:GetFrame() return self.m_previewFrame end
function gui.PFMRenderPreviewWindow:Remove()
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	if(util.is_valid(self.m_previewFrame)) then self.m_previewFrame:Remove() end
end
function gui.PFMRenderPreviewWindow:IsValid()
	return util.is_valid(self.m_previewFrame)
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")

util.register_class("gui.RaytracedViewport",gui.Base)
function gui.RaytracedViewport:__init()
	gui.Base.__init(self)
end
function gui.RaytracedViewport:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(128,128)

	self.m_tex = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_tex:SetMouseInputEnabled(true)
	self.m_tex:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local imgBuf = (self.m_rtJob ~= nil) and self.m_rtJob:GetRenderResult()
			if(imgBuf ~= nil) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext) == false) then return end
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem(locale.get_text("save_as"),function()
					local dialoge = gui.create_file_save_dialog(function(pDialoge)
						local fname = pDialoge:GetFilePath(true)
						file.create_path(file.get_file_path(fname))
						local result = util.save_image(imgBuf,fname,util.IMAGE_FORMAT_PNG)
						if(result == false) then
							pfm.log("Unable to save image as '" .. fname .. "'!",pfm.LOG_CATEGORY_PFM_INTERFACE,pfm.LOG_SEVERITY_WARNING)
						end
					end)
					dialoge:SetExtensions({"png"})
					dialoge:SetRootPath(util.get_addon_path())
					dialoge:Update()
				end)
				pContext:Update()
			end
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	self.m_renderSettings = pfm.RaytracingRenderJob.Settings()
	self.m_renderSettings:SetRenderMode(pfm.RaytracingRenderJob.Settings.RENDER_MODE_COMBINED)
	self.m_renderSettings:SetSamples(40)
	self.m_renderSettings:SetSkyStrength(30)
	self.m_renderSettings:SetSkyYaw(0.0)
	self.m_renderSettings:SetEmissionStrength(1.0)
	self.m_renderSettings:SetMaxTransparencyBounces(128)
	self.m_renderSettings:SetDenoise(true)
	self.m_renderSettings:SetDeviceType(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_CPU)
	self.m_renderSettings:SetCamType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE)
	self.m_renderSettings:SetPanoramaType(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA)
end
function gui.RaytracedViewport:SetUseElementSizeAsRenderResolution(b) self.m_useElementSizeAsRenderResolution = b end
function gui.RaytracedViewport:GetRenderSettings() return self.m_renderSettings end
function gui.RaytracedViewport:SetGameScene(gameScene) self.m_gameScene = gameScene end
function gui.RaytracedViewport:OnRemove()
	self:CancelRendering()
end
function gui.RaytracedViewport:CancelRendering()
	if(self.m_rtJob == nil) then return end
	self.m_rtJob:CancelRendering()
end
function gui.RaytracedViewport:IsRendering()
	return (self.m_rtJob ~= nil) and self.m_rtJob:IsRendering() or false
end
function gui.RaytracedViewport:OnThink()
	if(self.m_rtJob == nil) then return end
	local progress = self.m_rtJob:GetProgress()
	local state = self.m_rtJob:Update()
	local newProgress = self.m_rtJob:GetProgress()
	if(newProgress ~= progress) then
		self:CallCallbacks("OnProgressChanged",newProgress)
	end
	if((state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FRAME_COMPLETE)) then
		local tex = self.m_rtJob:GetRenderResultTexture()
		if(tex ~= nil) then self.m_tex:SetTexture(tex) end

		self:CallCallbacks("OnFrameComplete",state,self.m_rtJob)
	end
	if(state == pfm.RaytracingRenderJob.STATE_COMPLETE or state == pfm.RaytracingRenderJob.STATE_FAILED) then
		self:DisableThinking()
		self:SetAlwaysUpdate(false)

		self:CallCallbacks("OnComplete",state,self.m_rtJob)
	end
end
function gui.RaytracedViewport:Refresh(preview)
	self:CancelRendering()
	local r = engine.load_library("cycles/pr_cycles")
	if(r ~= true) then
		print("WARNING: An error occured trying to load the 'pr_cycles' module: ",r)
		return
	end

	local settings = self.m_renderSettings
	if(self.m_useElementSizeAsRenderResolution) then
		settings:SetWidth(self:GetWidth())
		settings:SetHeight(self:GetHeight())
	end

	settings:SetRenderPreview(preview)
	self.m_rtJob = pfm.RaytracingRenderJob(settings)
	if(self.m_gameScene ~= nil) then self.m_rtJob:SetGameScene(self.m_gameScene) end

	pfm.log("Rendering image with resolution " .. settings:GetWidth() .. "x" .. settings:GetHeight() .. " and " .. settings:GetSamples() .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self.m_rtJob:Start()

	self:EnableThinking()
	self:SetAlwaysUpdate(true)
end
gui.register("WIRaytracedViewport",gui.RaytracedViewport)

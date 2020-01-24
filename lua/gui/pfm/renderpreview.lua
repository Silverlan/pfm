--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/aspectratio.lua")
include("/gui/hbox.lua")
include("/gui/resizer.lua")
include("/gui/pfm/slider.lua")
include("/gui/pfm/button.lua")
include("/gui/editableentry.lua")
include("/gui/wifiledialog.lua")
include("/gui/toggleoption.lua")

util.register_class("gui.PFMRenderPreview",gui.Base)

function gui.PFMRenderPreview:__init()
	gui.Base.__init(self)
end
function gui.PFMRenderPreview:OnInitialize()
	gui.Base.OnInitialize(self)

	local hBottom = 42
	local hViewport = 221
	self:SetSize(128,hViewport +hBottom)

	self.m_contents = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	self.vpContents = gui.create("WIHBox",self.m_contents,0,0,self:GetWidth(),hViewport,0,0,1,1)
	self.vpContents:SetAutoFillContents(true)

	self.m_vpBg = gui.create("WIRect",self.vpContents)
	self.m_vpBg:SetColor(Color.Black)
	self.m_vpBg:SetMouseInputEnabled(true)
	self.m_vpBg:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			if(self.m_renderSettings ~= nil and self.m_renderSettings.currentImageBuffer ~= nil) then
				local pContext = gui.open_context_menu()
				if(util.is_valid(pContext) == false) then return end
				pContext:SetPos(input.get_cursor_pos())
				pContext:AddItem(locale.get_text("save_as"),function()
					local dialoge = gui.create_file_save_dialog(function(pDialoge)
						local fname = pDialoge:GetFilePath(true)
						file.create_path(file.get_file_path(fname))
						local result = util.save_image(self.m_renderSettings.currentImageBuffer,fname,util.IMAGE_FORMAT_PNG)
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

	self.m_aspectRatioWrapper = gui.create("WIAspectRatio",self.m_vpBg,0,0,self.m_vpBg:GetWidth(),self.m_vpBg:GetHeight(),0,0,1,1)

	gui.create("WIResizer",self.vpContents)

	self:InitializeSettings(self.vpContents)

	self.m_preview = gui.create("WITexturedRect",self.m_aspectRatioWrapper)

	self:InitializeControls()
end
function gui.PFMRenderPreview:InitializeSettings(parent)
	local p = gui.create("WIVBox",parent)
	p:SetAutoFillContentsToWidth(true)
	
	local renderMode = gui.create("WIDropDownMenu",p)
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_combined"),"combined")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_albedo"),"albedo")
	renderMode:AddOption(locale.get_text("pfm_cycles_bake_type_normals"),"normals")
	renderMode:SelectOption(0)
	-- renderMode:SetTooltip(locale.get_text("pfm_cycles_bake_type_desc"))
	self.m_ctrlRenderMode = renderMode

	renderMode:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_render_mode"))

	-- Sample count
	local samplesPerPixel = gui.create("WIPFMSlider",p)
	samplesPerPixel:SetText(locale.get_text("pfm_samples_per_pixel"))
	samplesPerPixel:SetInteger(true)
	samplesPerPixel:SetRange(1,500)
	samplesPerPixel:SetDefault(40)
	samplesPerPixel:SetTooltip(locale.get_text("pfm_samples_per_pixel_desc"))
	samplesPerPixel:SetStepSize(1.0)
	self.m_ctrlSamplesPerPixel = samplesPerPixel

	-- Resolution Width
	local resolution = engine.get_render_resolution()

	local resolutionWidth = gui.create("WIPFMSlider",p)
	resolutionWidth:SetText(locale.get_text("pfm_resolution_width"))
	resolutionWidth:SetInteger(true)
	resolutionWidth:SetRange(64,4096)
	resolutionWidth:SetDefault(resolution.x)
	resolutionWidth:SetStepSize(1.0)
	self.m_ctrlResolutionWidth = resolutionWidth

	local resolutionHeight = gui.create("WIPFMSlider",p)
	resolutionHeight:SetText(locale.get_text("pfm_resolution_height"))
	resolutionHeight:SetInteger(true)
	resolutionHeight:SetRange(64,4096)
	resolutionHeight:SetDefault(resolution.y)
	resolutionHeight:SetStepSize(1.0)
	self.m_ctrlResolutionHeight = resolutionHeight

	-- Sky override
	local skyOverride = gui.create("WIFileEntry",p)
	skyOverride:SetBrowseHandler(function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(el:GetFilePath(true))
		end)
		pFileDialog:SetRootPath("materials")
		local path = file.get_file_path(skyOverride:GetValue())
		if(#path == 0) then path = "skies" end
		pFileDialog:SetPath(path)
		pFileDialog:SetExtensions({"hdr"})
		pFileDialog:Update()
	end)
	skyOverride:SetTooltip(locale.get_text("pfm_sky_override_desc"))
	self.m_ctrlSkyOverride = skyOverride

	skyOverride:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_sky_override"))

	-- Sky strength
	local skyStrength = gui.create("WIPFMSlider",p)
	skyStrength:SetText(locale.get_text("pfm_sky_strength"))
	skyStrength:SetRange(0,100)
	skyStrength:SetDefault(1)
	skyStrength:SetTooltip(locale.get_text("pfm_sky_strength_desc"))
	self.m_ctrlSkyStrength = skyStrength

	-- Sky yaw
	local skyYaw = gui.create("WIPFMSlider",p)
	skyYaw:SetText(locale.get_text("pfm_sky_yaw_angle"))
	skyYaw:SetRange(0,360)
	skyYaw:SetDefault(0)
	skyYaw:SetTooltip(locale.get_text("pfm_sky_yaw_angle_desc"))
	self.m_ctrlSkyYaw = skyYaw

	-- Number of frames
	local frameCount = gui.create("WIPFMSlider",p)
	frameCount:SetText(locale.get_text("pfm_number_of_frames_to_render"))
	frameCount:SetInteger(true)
	frameCount:SetRange(1,100)
	frameCount:SetDefault(1)
	frameCount:SetTooltip(locale.get_text("pfm_number_of_frames_to_render_desc"))
	frameCount:SetStepSize(1.0)
	self.m_ctrlFrameCount = frameCount

	-- Output directory
	local outputDir = gui.create("WIFileEntry",p)
	outputDir:SetBrowseHandler(function(resultHandler)
		local pFileDialog = gui.create_file_open_dialog(function(el,fileName)
			if(fileName == nil) then return end
			resultHandler(fileName)
		end)
		pFileDialog:MakeDirectoryExplorer()
		pFileDialog:SetRootPath(util.get_addon_path())
		pFileDialog:SetPath(outputDir:GetValue())
		pFileDialog:Update()
	end)
	outputDir:SetValue("render/")
	outputDir:SetTooltip(locale.get_text("pfm_output_directory_desc"))
	self.m_ctrlOutputDir = outputDir

	outputDir:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_output_directory"))

	local denoise = gui.create("WIToggleOption",p)
	denoise:SetText(locale.get_text("pfm_denoise_image"))
	denoise:SetChecked(true)
	denoise:SetTooltip(locale.get_text("pfm_denoise_image_desc"))
	self.m_ctrlDenoise = denoise

	local renderWorld = gui.create("WIToggleOption",p)
	renderWorld:SetText(locale.get_text("pfm_render_world"))
	renderWorld:SetChecked(true)
	renderWorld:SetTooltip(locale.get_text("pfm_render_world_desc"))
	self.m_ctrlRenderWorld = renderWorld

	local renderGameEntities = gui.create("WIToggleOption",p)
	renderGameEntities:SetText(locale.get_text("pfm_render_game_objects"))
	renderGameEntities:SetChecked(true)
	renderGameEntities:SetTooltip(locale.get_text("pfm_render_game_objects_desc"))
	self.m_ctrlRenderGameEntities = renderGameEntities

	local renderPlayer = gui.create("WIToggleOption",p)
	renderPlayer:SetText(locale.get_text("pfm_render_player"))
	renderPlayer:SetChecked(false)
	renderPlayer:SetTooltip(locale.get_text("pfm_render_player_desc"))
	self.m_ctrlRenderPlayer = renderPlayer

	local sceneLights = gui.create("WIToggleOption",p)
	sceneLights:SetText(locale.get_text("pfm_render_scene_lights"))
	sceneLights:SetChecked(false)
	sceneLights:SetTooltip(locale.get_text("pfm_render_scene_lights_desc"))
	self.m_ctrlSceneLights = sceneLights
end
function gui.PFMRenderPreview:InitializeControls()
	local controls = gui.create("WIHBox",self.m_contents)
	controls:SetHeight(self:GetHeight() -self.m_vpBg:GetBottom())

	self.m_btRefreshPreview = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		self:Refresh(true)
	end)
	self.m_btRefreshPreview:SetText(locale.get_text("pfm_render_preview"))
	self.m_btRefreshPreview:SetTooltip(locale.get_text("pfm_refresh_preview"))

	gui.create("WIBase",controls,0,0,5,1) -- Gap

	self.m_btRefresh = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		self:Refresh()
	end)
	self.m_btRefresh:SetText(locale.get_text("pfm_render_image"))
	self.m_btRefresh:SetTooltip(locale.get_text("pfm_render_frame"))

	gui.create("WIBase",controls,0,0,5,1) -- Gap

	self.m_btOpenOutputDir = gui.PFMButton.create(controls,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		local path = self.m_ctrlOutputDir:GetValue()
		if(#path == 0) then return end
		util.open_path_in_explorer(util.get_addon_path() .. path)
	end)
	self.m_btOpenOutputDir:SetText(locale.get_text("pfm_open_output_dir"))

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
	local successful = self.m_raytracingJob:IsSuccessful()
	if(successful) then
		local imgBuffer = self.m_raytracingJob:GetResult()
		self.m_imageResultBuffer = imgBuffer
		local img = vulkan.create_image(imgBuffer)
		local imgViewCreateInfo = vulkan.ImageViewCreateInfo()
		imgViewCreateInfo.swizzleAlpha = vulkan.COMPONENT_SWIZZLE_ONE -- We'll ignore the alpha value
		local tex = vulkan.create_texture(img,vulkan.TextureCreateInfo(),imgViewCreateInfo,vulkan.SamplerCreateInfo())
		
		if(util.is_valid(self.m_preview)) then self.m_preview:SetTexture(tex) end

		local renderSettings = self.m_renderSettings
		renderSettings.currentImageBuffer = imgBuffer
		if(#renderSettings.outputDir > 0 and renderSettings.preview == false) then
			file.create_path(renderSettings.outputDir)
			local path = renderSettings.outputDir
			if(path:sub(-1) ~= "/") then path = path .. "/" end
			path = path .. "frame" .. renderSettings.currentFrame
			local result = util.save_image(imgBuffer,path,util.IMAGE_FORMAT_PNG)
			if(result == false) then
				pfm.log("Unable to save image as '" .. path .. "'!",pfm.LOG_CATEGORY_PFM_INTERFACE,pfm.LOG_SEVERITY_WARNING)
			end
		end
	end
	self.m_raytracingJob = nil

	if(util.is_valid(self.m_btRefreshPreview)) then self.m_btRefreshPreview:SetEnabled(true) end
	if(util.is_valid(self.m_btRefresh)) then self.m_btRefresh:SetEnabled(true) end

	self:DisableThinking()
	self:SetAlwaysUpdate(false)

	if(successful) then self:RenderNextFrame() end
end
function gui.PFMRenderPreview:IsComplete()
	if(self.m_raytracingJob == nil) then return true end
	return self.m_raytracingJob:IsComplete()
end
function gui.PFMRenderPreview:GetProgress()
	if(self.m_raytracingJob == nil) then return 1.0 end
	return self.m_raytracingJob:GetProgress()
end
function gui.PFMRenderPreview:RenderNextFrame()
	local renderSettings = self.m_renderSettings
	if(renderSettings == nil) then return end
	renderSettings.currentFrame = renderSettings.currentFrame +1
	if(renderSettings.currentFrame == renderSettings.frameCount) then
		local msg
		if(renderSettings.preview) then msg = "Preview rendering complete!"
		else msg = "Rendering complete! " .. renderSettings.frameCount .. " frames have been rendered and stored in \"" .. renderSettings.outputDir .. "\"!" end
		pfm.log(msg,pfm.LOG_CATEGORY_PFM_INTERFACE)
		return
	end

	local cam = game.get_render_scene_camera()
	if(cam == nil) then return end

	local scene = cycles.create_scene(renderSettings.renderMode,renderSettings.samples,false,renderSettings.denoise)
	local pos = cam:GetEntity():GetPos()
	local rot = cam:GetEntity():GetRotation()
	local nearZ = cam:GetNearZ()
	local farZ = cam:GetFarZ()
	local fov = cam:GetFOV()
	scene:InitializeFromGameScene(pos,rot,nearZ,farZ,fov,function(ent)
		if(ent:IsWorld()) then return renderSettings.renderWorld end
		if(ent:IsPlayer()) then return renderSettings.renderPlayer end
		return renderSettings.renderGameEntities or ent:HasComponent(ents.COMPONENT_PFM_ACTOR)
	end,function(ent)
		return renderSettings.renderSceneLights
	end)
	if(#renderSettings.sky > 0) then scene:SetSky(renderSettings.sky) end
	
	scene:SetSkyAngles(EulerAngles(0,renderSettings.skyYaw,0))
	scene:SetSkyStrength(renderSettings.skyStrength)
	scene:SetResolution(renderSettings.width,renderSettings.height)
	
	pfm.log("Starting render job for frame " .. renderSettings.currentFrame .. "...",pfm.LOG_CATEGORY_PFM_INTERFACE)

	local job = scene:CreateRenderJob()
	job:Start()

	self.m_raytracingJob = job

	self.m_lastProgress = 0.0
	self:EnableThinking()
	self:SetAlwaysUpdate(true)

	-- Move to next frame in case we're rendering an image sequence
	if(renderSettings.currentFrame < (renderSettings.frameCount -1)) then
		local filmmaker = tool.get_filmmaker()
		if(util.is_valid(filmmaker)) then filmmaker:GoToNextFrame() end
	end
end
function gui.PFMRenderPreview:Refresh(preview)
	if(self.m_raytracingJob ~= nil) then self.m_raytracingJob:Cancel() end
	if(util.is_valid(self.m_btRefreshPreview)) then self.m_btRefreshPreview:SetEnabled(false) end
	if(util.is_valid(self.m_btRefresh)) then self.m_btRefresh:SetEnabled(false) end

	local r = engine.load_library("cycles/pr_cycles")
	if(r ~= true) then
		print("WARNING: An error occured trying to load the 'pr_cycles' module: ",r)
		return
	end

	local renderMode = cycles.Scene.RENDER_MODE_COMBINED

	local selectedRenderMode = self.m_ctrlRenderMode:GetValue()
	if(selectedRenderMode == "combined") then renderMode = cycles.Scene.RENDER_MODE_COMBINED
	elseif(selectedRenderMode == "albedo") then renderMode = cycles.Scene.RENDER_MODE_ALBEDO
	elseif(selectedRenderMode == "normals") then renderMode = cycles.Scene.RENDER_MODE_NORMALS end

	preview = preview or false
	local samples = preview and 4 or nil

	self.m_renderSettings = {
		renderMode = renderMode,
		samples = samples or self.m_ctrlSamplesPerPixel:GetValue(),
		sky = self.m_ctrlSkyOverride:GetValue(),
		skyStrength = self.m_ctrlSkyStrength:GetValue(),
		skyYaw = self.m_ctrlSkyYaw:GetValue(),
		frameCount = preview and 1 or self.m_ctrlFrameCount:GetValue(),
		outputDir = self.m_ctrlOutputDir:GetValue(),
		denoise = self.m_ctrlDenoise:IsChecked(),
		renderWorld = self.m_ctrlRenderWorld:IsChecked(),
		renderGameEntities = self.m_ctrlRenderGameEntities:IsChecked(),
		renderPlayer = self.m_ctrlRenderPlayer:IsChecked(),
		renderSceneLights = self.m_ctrlSceneLights:IsChecked(),
		currentFrame = -1,
		width = preview and 512 or self.m_ctrlResolutionWidth:GetValue(),
		height = preview and 512 or self.m_ctrlResolutionHeight:GetValue(),
		preview = preview
	}
	pfm.log("Rendering image with resolution " .. self.m_renderSettings.width .. "x" .. self.m_renderSettings.height .. " and " .. self.m_renderSettings.samples .. " samples...",pfm.LOG_CATEGORY_PFM_INTERFACE)
	self:RenderNextFrame()
end
gui.register("WIPFMRenderPreview",gui.PFMRenderPreview)

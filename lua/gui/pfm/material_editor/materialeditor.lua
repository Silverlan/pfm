--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiviewport.lua")
include("/gui/raytracedviewport.lua")
include("/gui/pfm/colorentry.lua")
include("/gui/pfm/colorslider.lua")
include("rmacomposerdialog.lua")
include("../controls_menu.lua")

locale.load("pfm_material_editor.txt")

util.register_class("gui.PFMMaterialEditor",gui.Base)

include("cycles.lua")
include("shaders")

gui.PFMMaterialEditor.RENDERER_REALTIME = 0
gui.PFMMaterialEditor.RENDERER_RAYTRACING = 1

function gui.PFMMaterialEditor:__init()
	gui.Base.__init(self)
end
function gui.PFMMaterialEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_linkedMaterialParameterElements = {}
	self.m_texSlots = {}
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIHBox",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	self.m_controlBox = gui.create("WIVBox",self.m_contents)
	self.m_controlBox:SetAutoFillContents(true)

	self:InitializeControls()
	gui.create("WIResizer",self.m_contents):SetFraction(0.5)

	-- Viewport
	local vpContents = gui.create("WIBase",self.m_contents,0,0,self:GetWidth(),self:GetHeight())

	self.m_contents:Update()

	self.m_vpBox = gui.create("WIVBox",vpContents,0,0,vpContents:GetWidth(),vpContents:GetHeight(),0,0,1,1)
	self.m_vpBox:SetAutoFillContents(true)
	self:InitializeViewport()
	self.m_vpBox:AddCallback("SetSize",function() self:ScheduleRTPreviewUpdate() end)

	gui.create("WIResizer",self.m_vpBox):SetFraction(0.75)

	self.m_renderControlsWrapper = gui.create("WIBase",self.m_vpBox,0,0,100,100)
	self.m_renderControlsVbox = gui.create("WIVBox",self.m_renderControlsWrapper,0,0,self.m_renderControlsWrapper:GetWidth(),self.m_renderControlsWrapper:GetHeight(),0,0,1,1)
	self.m_renderControlsVbox:SetAutoFillContents(true)
	self:InitializePreviewControls()

	self.m_contents:Update()
	self:ResetOptions()
	self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
end
function gui.PFMMaterialEditor:ApplyTexture(texIdentifier,texPath,updateTextureSlot)
	if(util.is_valid(self.m_material) == false) then return end
	self.m_material:SetTexture(texIdentifier,texPath)
	self.m_material:UpdateTextures()
	self:ReloadMaterialDescriptor()
	self.m_viewport:Render()

	if(updateTextureSlot) then
		local texSlot = self.m_texSlots[texIdentifier].textureSlot
		if(texSlot:IsValid()) then texSlot:SetTexture(texPath) end
	end
	local te = self.m_texSlots[texIdentifier].textEntry
	if(te:IsValid()) then te:SetText(texPath) end

	self:ScheduleRTPreviewUpdate(true)
end
function gui.PFMMaterialEditor:AddTextureSlot(parent,text,texIdentifier,normalMap,enableTransparency)
	local box = gui.create("WIBase",parent,0,0,256,128)

	local te
	local hBoxTexSlots = gui.create("WIHBox",box)
	local texSlot = gui.create("WIPFMTextureSlot",hBoxTexSlots,box:GetWidth() /2 -64,0,128 -24,128 -24)
	texSlot:SetMouseInputEnabled(true)
	texSlot:SetNormalMap(normalMap or false)
	texSlot:SetTransparencyEnabled(enableTransparency or false)
	texSlot:AddCallback("OnTextureCleared",function(texSlot)
		if(util.is_valid(self.m_material)) then
			local data = self.m_material:GetDataBlock()
			data:RemoveValue(texIdentifier)
			self.m_material:UpdateTextures()
			self:ReloadMaterialDescriptor()
		end
		self.m_viewport:Render()

		te:SetText("")
	end)
	texSlot:AddCallback("OnTextureImported",function() self:ApplyTexture(texIdentifier,texSlot:GetTexture()) end)
	box:AddCallback("SetSize",function()
		local sz = math.min(box:GetHeight() -24,box:GetWidth())
		texSlot:SetSize(sz,sz)

		hBoxTexSlots:Update()
		hBoxTexSlots:SetPos(box:GetWidth() /2.0 -hBoxTexSlots:GetWidth() /2.0,box:GetHeight() -24 -sz)
	end)

	te = gui.create("WITextEntry",box,0,box:GetHeight() -24,box:GetWidth(),24,0,1,1,1)
	te:AddCallback("OnTextEntered",function(pEntry)
		local texPath = pEntry:GetText()
		texSlot:SetTexture(texPath)
		self:ApplyTexture(texIdentifier,texPath)
	end)
	te:Wrap("WIEditableEntry"):SetText(text)
	self.m_texSlots[texIdentifier] = {
		textureSlot = texSlot,
		textEntry = te
	}
	return te,texSlot
end
function gui.PFMMaterialEditor:InitializeControls()
	self:InitializePBRControls()
	--self:InitializeEyeControls()
	--self:InitializeNodrawControls()
end
function gui.PFMMaterialEditor:LinkControlToMaterialParameter(parameter,element,subBlocks,load)
	table.insert(self.m_linkedMaterialParameterElements,{
		parameter = parameter,
		element = element,
		subBlocks = subBlocks,
		load = load
	})
end
function gui.PFMMaterialEditor:GetMaterialDataBlock()
	if(util.is_valid(self.m_material) == false or self.m_material:IsError()) then return end
	return self.m_material:GetDataBlock()
end
function gui.PFMMaterialEditor:SetMaterialParameter(type,key,val,subBlocks)
	local data = self:GetMaterialDataBlock()
	if(data == nil) then return end
	if(subBlocks ~= nil) then
		for _,id in ipairs(subBlocks) do
			data = data:AddBlock(id)
		end
	end
	data:SetValue(type,key,tostring(val))
	self:ReloadMaterialDescriptor()

	self:ScheduleRTPreviewUpdate()
end
function gui.PFMMaterialEditor:ReloadMaterialDescriptor()
	self.m_material:InitializeShaderDescriptorSet(true)
	self.m_viewport:Render()
end
function gui.PFMMaterialEditor:ResetOptions()
	self.m_ctrlVBox:ResetControls()

	for texIdentifier,texSlotData in pairs(self.m_texSlots) do
		if(texSlotData.textureSlot:IsValid()) then
			texSlotData.textureSlot:ClearTexture()
		end
	end
end
function gui.PFMMaterialEditor:SetMaterial(mat,mdl)
	self.m_viewport:SetModel(mdl or "pfm/texture_sphere")
	self.m_viewport:ScheduleUpdate()

	self.m_material = nil
	self.m_model = nil

	local matPath = util.Path(mat)
	matPath:PopBack()
	for identifier,texSlotData in pairs(self.m_texSlots) do
		if(texSlotData.textureSlot:IsValid()) then
			texSlotData.textureSlot:SetImportPath(matPath:GetString())
		end
	end

	local ent = self.m_viewport:GetEntity()
	local mdlC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_MODEL) or nil
	if(mdl ~= nil) then self.m_model = mdlC:GetModel() end
	-- mdlC:SetMaterialOverride(0,mat)
	self.m_viewport:Render()

	local material = game.load_material(mat)
	local data = material:GetDataBlock()

	self:ResetOptions()

	for _,pdata in ipairs(self.m_linkedMaterialParameterElements) do
		local identifier = pdata.parameter
		local block = data
		if(pdata.subBlocks ~= nil) then
			for _,name in ipairs(pdata.subBlocks) do
				block = block:FindBlock(name)
				if(block == nil) then break end
			end
		end
		if(block ~= nil and block:HasValue(identifier) and util.is_valid(pdata.element)) then
			if(pdata.load ~= nil) then
				pdata.load(block)
			else
				local value = block:GetFloat(identifier)
				pdata.element:SetValue(value)
				pdata.element:SetDefault(value)
			end
		end
	end

	-- We have to set the material AFTER the non-texture settings have been initialized, otherwise changing the settings may inadvertently affect the material as well
	self.m_material = material

	if(data:HasValue("albedo_map")) then
		local albedoMap = data:GetString("albedo_map")
		self:ApplyTexture("albedo_map",albedoMap,true)
	end

	if(data:HasValue("normal_map")) then
		local normalMap = data:GetString("normal_map")
		self:ApplyTexture("normal_map",normalMap,true)
	end

	if(data:HasValue("rma_map")) then
		local rmaMap = data:GetString("rma_map")
		self:ApplyTexture("rma_map",rmaMap,true)
	end

	if(data:HasValue("emission_map")) then
		local emissionMap = data:GetString("emission_map")
		self:ApplyTexture("emission_map",emissionMap,true)
	end

	if(data:HasValue("wrinkle_compress_map")) then
		local wrinkleCompressMap = data:GetString("wrinkle_compress_map")
		self:ApplyTexture("wrinkle_compress_map",wrinkleCompressMap,true)
	end

	if(data:HasValue("wrinkle_stretch_map")) then
		local wrinkleStretchMap = data:GetString("wrinkle_stretch_map")
		self:ApplyTexture("wrinkle_stretch_map",wrinkleStretchMap,true)
	end
	self:UpdateAlphaMode()
end
function gui.PFMMaterialEditor:ScheduleRTPreviewUpdate(fullUpdateRequired)
	self.m_rtPreviewUpdateRequired = fullUpdateRequired and 2 or 1
	self:EnableThinking()
end
function gui.PFMMaterialEditor:UpdateRTPreview()
	if(self.m_rtPreviewUpdateRequired == nil) then return end
	if(tonumber(self.m_renderMode:GetOptionValue(self.m_renderMode:GetSelectedOption())) ~= -1) then return end
	local scene = self.m_rtViewport:GetRenderScene()
	if(scene ~= nil and scene:HasRenderedSamplesForAllTiles() == false) then return end -- Wait for previous render to at least render 1 sample
	local fullUpdate = (self.m_rtPreviewUpdateRequired == 2)
	self.m_rtPreviewUpdateRequired = nil

	self.m_tLastRenderUpdate = time.real_time()
	local scene = self.m_rtViewport:GetRenderScene()
	if(fullUpdate or scene == nil) then
		self.m_btRaytracying:SetEnabled(false)

		local settings = self.m_rtViewport:GetRenderSettings()
		local samples = 40
		-- Use a higher sample count if SSS is enabled
		if(self.m_ctrlSSSMethod:GetSelectedOption() ~= 0) then samples = 200 end
		settings:SetSamples(samples)

		self.m_rtViewport:Refresh()
		return
	end
	self:Test()
	--scene:Reset()
	-- TODO
	--[[local cam = scene:GetCamera()
	cam:SetPos(cam:GetPos() +Vector(0,1,0))
	cam:Finalize()]]
	--scene:Restart()
end
function gui.PFMMaterialEditor:Test()
	--local dt = time.real_time() -self.m_tLastRenderUpdate
	--if(dt < 1.0) then return end

	local scene = self.m_rtViewport:GetRenderScene()
	if(scene == nil) then return end
	local vpCam = self.m_viewport:GetCamera()
	if(util.is_valid(vpCam) == false) then return end
	local vcC = vpCam:GetEntity():GetComponent(ents.COMPONENT_VIEWER_CAMERA)
	if(vcC == nil) then return end
	-- We have to reset the scene before we can make any changes to it (this will cancel the rendering)
	scene:Reset()

	local t = vcC:GetLastUpdateTime()
	--if(self.m_lastRtVpUpdate ~= nil and t <= self.m_lastRtVpUpdate) then return end
	--self.m_lastRtVpUpdate = t
	local sceneCam = scene:GetCamera()
	local entCam = vpCam:GetEntity()
	sceneCam:SetPos(entCam:GetPos())
	sceneCam:SetRotation(entCam:GetRotation())
	-- sceneCam:SetFarZ()
	-- sceneCam:SetNearZ()
	-- sceneCam:SetFOV()
	-- TODO: FOV, etc.

	sceneCam:Finalize(scene)
	scene:ReloadShaders()
	local tt = time.time_since_epoch()
	scene:Restart()
	-- print((time.time_since_epoch() -tt) /1000000000.0)

	self.m_tLastRenderUpdate = time.real_time()
end
function gui.PFMMaterialEditor:InitializePreviewControls()
	local btRaytracying = gui.create("WIPFMButton",self.m_renderControlsVbox)
	btRaytracying:SetText(locale.get_text("pfm_render_preview"))
	btRaytracying:AddCallback("OnPressed",function(btRaytracying)
		self.m_renderMode:SelectOption("-1")
		self:ScheduleRTPreviewUpdate()
	end)
	self.m_btRaytracying = btRaytracying

	-- Render mode
	local renderMode = gui.create("WIDropDownMenu",self.m_renderControlsVbox)
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_pbr"),tostring(game.Scene.DEBUG_MODE_NONE))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_raytracing"),tostring(-1))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_albedo"),tostring(game.Scene.DEBUG_MODE_ALBEDO))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_normals"),tostring(game.Scene.DEBUG_MODE_NORMAL))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_metalness"),tostring(game.Scene.DEBUG_MODE_METALNESS))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_roughness"),tostring(game.Scene.DEBUG_MODE_ROUGHNESS))
	renderMode:AddOption(locale.get_text("ambient_occlusion"),tostring(game.Scene.DEBUG_MODE_AMBIENT_OCCLUSION))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_diffuse_lighting"),tostring(game.Scene.DEBUG_MODE_DIFFUSE_LIGHTING))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_reflectance"),tostring(game.Scene.DEBUG_MODE_REFLECTANCE))
	renderMode:AddOption(locale.get_text("pfm_mated_render_mode_emission"),tostring(game.Scene.DEBUG_MODE_EMISSION))
	renderMode:SelectOption(0)
	renderMode:AddCallback("OnOptionSelected",function(renderMode,idx)
		local scene = self.m_viewport:GetScene()
		if(scene == nil) then return end
		local val = tonumber(renderMode:GetOptionValue(idx))
		if(val == -1) then self:SetRenderer(gui.PFMMaterialEditor.RENDERER_RAYTRACING)
		else
			self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
			scene:SetDebugMode(val)
			self.m_viewport:Render()
		end
	end)
	self.m_renderMode = renderMode

	renderMode:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_mated_render_mode"))

	-- Light intensity
	local lightIntensity = gui.create("WIPFMSlider",self.m_renderControlsVbox)
	lightIntensity:SetText(locale.get_text("pfm_mated_light_intensity"))
	lightIntensity:SetRange(0,100)
	lightIntensity:SetDefault(4)
	lightIntensity:SetStepSize(0.1)
	lightIntensity:AddCallback("OnLeftValueChanged",function(el,val)
		local ls = self.m_viewport:GetLightSource()
		local lightC = util.is_valid(ls) and ls:GetComponent(ents.COMPONENT_LIGHT) or nil
		if(lightC == nil) then return end
		lightC:SetLightIntensity(val)
		self.m_viewport:Render()

		local settings = self.m_rtViewport:GetRenderSettings()
		settings:SetLightIntensityFactor(val *0.5)

		-- self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
	end)
	self.m_rtViewport:GetRenderSettings():SetLightIntensityFactor(4 *0.5)
	self.m_ctrlLightIntensity = lightIntensity

	-- Light color
	local lightColor = gui.create("WIPFMColorSlider",self.m_renderControlsVbox)
	lightColor:SetText(locale.get_text("pfm_mated_light_color"))
	lightColor:AddCallback("OnValueChanged",function(el,hsv)
		local ls = self.m_viewport:GetLightSource()
		local colC = util.is_valid(ls) and ls:GetComponent(ents.COMPONENT_COLOR) or nil
		if(colC == nil) then return end
		local col = hsv:ToRGBColor()
		colC:SetColor(col)
		self.m_viewport:Render()

		-- self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
	end)
	lightColor:SetDefault(182)
	self.m_ctrlLightColor = lightColor

	-- Light angle
	local ls = self.m_viewport:GetLightSource()
	local lightAngle = gui.create("WIPFMSlider",self.m_renderControlsVbox)
	lightAngle:SetText(locale.get_text("pfm_mated_light_angle"))
	lightAngle:SetRange(0.0,360.0)
	lightAngle:SetDefault(util.is_valid(ls) and math.normalize_angle(ls:GetAngles().y,0.0) or 210.0)
	lightAngle:SetStepSize(0.1)
	lightAngle:AddCallback("OnLeftValueChanged",function(el,val)
		local ls = self.m_viewport:GetLightSource()
		if(util.is_valid(ls) == false) then return end
		local ang = ls:GetAngles()
		ang.y = val
		ls:SetAngles(ang)
		self.m_viewport:Render()

		-- self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
	end)
	self.m_ctrlLightAngle = lightAngle

	-- IBL Strength
	local rp = self.m_viewport:GetReflectionProbe()
	local rpC = util.is_valid(rp) and rp:GetComponent(ents.COMPONENT_REFLECTION_PROBE) or nil
	local iblStrength = gui.create("WIPFMSlider",self.m_renderControlsVbox)
	iblStrength:SetText(locale.get_text("pfm_mated_ibl_strength"))
	iblStrength:SetRange(0.0,4.0)
	iblStrength:SetDefault(util.is_valid(rpC) and rpC:GetIBLStrength() or 1.0)
	iblStrength:SetStepSize(0.01)
	iblStrength:AddCallback("OnLeftValueChanged",function(el,val)
		local rp = self.m_viewport:GetReflectionProbe()
		local rpC = util.is_valid(rp) and rp:GetComponent(ents.COMPONENT_REFLECTION_PROBE) or nil
		if(rpC == nil) then return end
		rpC:SetIBLStrength(val)
		self.m_viewport:Render()

		local settings = self.m_rtViewport:GetRenderSettings()
		settings:SetSkyStrength(val)

		-- self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
	end)
	self.m_rtViewport:GetRenderSettings():SetLightIntensityFactor(util.is_valid(rpC) and rpC:GetIBLStrength() or 1.0)
	self.m_ctrlIblStrength = iblStrength

	gui.create("WIBase",self.m_renderControlsVbox)
end
function gui.PFMMaterialEditor:SetRenderer(renderer)
	self.m_vpType = renderer
	local realtime = (renderer == gui.PFMMaterialEditor.RENDERER_REALTIME)
	-- self.m_viewport:SetVisible(realtime)
	-- self.m_viewport:SetAlpha(realtime and 255 or 0)
	self.m_rtViewport:SetVisible(not realtime)
	self:SetThinkingEnabled(not realtime)
end
function gui.PFMMaterialEditor:GetRenderer() return self.m_vpType end
function gui.PFMMaterialEditor:OnThink()
	if(self.m_updateRTPreviewContinuously) then self:ScheduleRTPreviewUpdate() end
	if(self.m_rtPreviewUpdateRequired) then self:UpdateRTPreview() end
end
function gui.PFMMaterialEditor:InitializeViewport()
	local width = 1024
	local height = 1024
	local vpContainer = gui.create("WIBase",self.m_vpBox,0,0,width,height)
	self.m_viewport = gui.create("WIModelView",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_viewport:SetClearColor(Color.Clear)
	self.m_viewport:InitializeViewport(width,height)
	self.m_viewport:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
	local cam = self.m_viewport:GetViewerCamera()
	if(util.is_valid(cam)) then
		cam:AddEventCallback(ents.ViewerCamera.EVENT_ON_CAMERA_UPDATED,function()
			self:ScheduleRTPreviewUpdate()
		end)
	end

	self.m_rtViewport = gui.create("WIRaytracedViewport",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_rtViewport:SetGameScene(self.m_viewport:GetScene())
	self.m_rtViewport:SetVisible(false)
	self.m_rtViewport:SetUseElementSizeAsRenderResolution(true)
	self.m_rtViewport:AddCallback("OnComplete",function()
		self.m_btRaytracying:SetEnabled(true)
		-- self:SetRenderer(gui.PFMMaterialEditor.RENDERER_RAYTRACING)
	end)

	self.m_vpMouseCapture = gui.create("WIBase",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_vpMouseCapture:SetMouseInputEnabled(true)
	self.m_vpMouseCapture:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT) then
			if(state == input.STATE_PRESS) then
				if(self:GetRenderer() == gui.PFMMaterialEditor.RENDERER_RAYTRACING) then
					--self:SetRenderer(gui.PFMMaterialEditor.RENDERER_REALTIME)
					self.m_updateRTPreviewContinuously = true
				end
			elseif(state == input.STATE_RELEASE and self.m_updateRTPreviewContinuously == true) then
				self.m_updateRTPreviewContinuously = nil
				self:SetRenderer(gui.PFMMaterialEditor.RENDERER_RAYTRACING)
			end
		end
		return self.m_viewport:InjectMouseInput(self.m_viewport:GetCursorPos(),button,state,mods)
	end)

	local settings = self.m_rtViewport:GetRenderSettings()
	settings:SetSky("skies/dusk379.hdr")
	settings:SetWidth(width)
	settings:SetHeight(height)
	settings:SetProgressive(true)
	settings:SetDeviceType(pfm.RaytracingRenderJob.Settings.DEVICE_TYPE_GPU)
	settings:SetDenoiseMode(pfm.RaytracingRenderJob.Settings.DENOISE_MODE_FAST)
end
gui.register("WIPFMMaterialEditor",gui.PFMMaterialEditor)

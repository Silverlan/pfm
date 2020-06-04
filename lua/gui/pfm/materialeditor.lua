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
include("textureslot.lua")
include("rmacomposerdialog.lua")

locale.load("pfm_material_editor.txt")

util.register_class("gui.PFMMaterialEditor",gui.Base)
gui.PFMMaterialEditor.RENDERER_REALTIME = 0
gui.PFMMaterialEditor.RENDERER_RAYTRACING = 1
function gui.PFMMaterialEditor:__init()
	gui.Base.__init(self)
end
function gui.PFMMaterialEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

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

	gui.create("WIResizer",self.m_vpBox):SetFraction(0.75)

	self.m_renderControlsWrapper = gui.create("WIBase",self.m_vpBox,0,0,100,100)
	self.m_renderControlsVbox = gui.create("WIVBox",self.m_renderControlsWrapper,0,0,self.m_renderControlsWrapper:GetWidth(),self.m_renderControlsWrapper:GetHeight(),0,0,1,1)
	self.m_renderControlsVbox:SetAutoFillContents(true)
	self:InitializePreviewControls()

	self.m_contents:Update()
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
		if(util.is_valid(self.m_material) == false) then return end
		local data = self.m_material:GetDataBlock()
		data:RemoveValue(texIdentifier)
		self.m_material:UpdateTextures()
		self:ReloadMaterialDescriptor()
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
	local mapVbox = gui.create("WIVBox",self.m_controlBox)
	mapVbox:SetAutoFillContents(true)
	-- Albedo map
	local numMaps = 6
	local fractionPerMap = 1.0 /numMaps
	self.m_teAlbedoMap = self:AddTextureSlot(mapVbox,locale.get_text("albedo_map"),"albedo_map",false,true)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap)

	-- Normal map
	self.m_teNormalMap = self:AddTextureSlot(mapVbox,locale.get_text("normal_map"),"normal_map",true,false)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *2)

	-- RMA map
	local teRMAMap,texSlotRMA = self:AddTextureSlot(mapVbox,locale.get_text("rma_map"),"rma_map",false,false)
	self.m_teRMAMap = teRMAMap
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *3)

	texSlotRMA:AddCallback("PopulateContextMenu",function(texSlotRMA,pContext)
		local matIdx
		if(util.is_valid(self.m_model)) then
			for i,mat in ipairs(self.m_model:GetMaterials()) do
				if(mat:GetName() == self.m_material:GetName()) then
					matIdx = i -1
					break
				end
			end
		end
		pContext:AddItem(locale.get_text("pfm_mated_compose_rma"),function()
			local dialog,frame,fileDialog = gui.create_dialog(function()
				local el = gui.create("WIRMAComposerDialog")
				if(matIdx ~= nil) then el:SetModel(self.m_model,matIdx) end
				local rmaTex = texSlotRMA:GetTexture()
				if(rmaTex ~= nil) then el:SetRMAMap(rmaTex) end
				el:AddCallback("OnRMAComposed",function(el,rmaMap)
					if(util.is_valid(self.m_model) == false) then return end
					local matPath = self.m_model:GetMaterialPaths()[1]
					if(matPath == nil) then return end
					local mdlName = file.remove_file_extension(file.get_file_name(self.m_model:GetName()))
					matPath = util.Path(matPath) +(mdlName .. "_rma")
					asset.lock_asset_watchers()

					local texInfo = util.TextureInfo()
					texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
					local result = util.save_image(rmaMap,"materials/" .. matPath:GetString(),texInfo)
					-- TODO: Doesn't work properly?
					-- local result,errMsg = asset.import_texture(rmaMap,asset.TextureImportInfo(),matPath:GetString())

					asset.unlock_asset_watchers()
					if(result == false) then
						console.print_warning("Unable to save RMA texture: ",errMsg)
						return
					end
					-- Force texture reload
					local texLoadFlags = bit.bor(game.TEXTURE_LOAD_FLAG_BIT_LOAD_INSTANTLY,game.TEXTURE_LOAD_FLAG_BIT_RELOAD)
					game.load_texture(matPath:GetString(),texLoadFlags)

					texSlotRMA:SetTexture(matPath:GetString())

					if(util.is_valid(self.m_material) == false) then return end
					self.m_material:SetTexture("rma_map",matPath:GetString())
					self.m_material:UpdateTextures()
					self:ReloadMaterialDescriptor()
					self.m_viewport:Render()

					teRMAMap:SetText(texPath)
				end)
				return el
			end)
			dialog:SetParent(tool.get_filmmaker())
		end)
	end)

	-- Emission map
	self.m_teEmissionMap = self:AddTextureSlot(mapVbox,locale.get_text("emission_map"),"emission_map",false,false)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *4)

	-- Wrinkles
	self.m_teWrinkleCompressMap = self:AddTextureSlot(mapVbox,locale.get_text("wrinkle_compress_map"),"wrinkle_compress_map",false,false)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *5)

	self.m_teWrinkleStretchMap = self:AddTextureSlot(mapVbox,locale.get_text("wrinkle_stretch_map"),"wrinkle_stretch_map",false,false)

	mapVbox:Update()
	
	gui.create("WIResizer",self.m_controlBox):SetFraction(0.6)

	local ctrlVbox = gui.create("WIVBox",self.m_controlBox)
	ctrlVbox:SetAutoFillContents(true)

	-- Presets
	local preset = gui.create("WIDropDownMenu",ctrlVbox)
	preset:AddOption("-","-")
	local genericSurfMat = phys.get_surface_material("generic")
	local surfMats = phys.get_surface_materials()
	for _,surfMat in ipairs(surfMats) do
		local metalness = surfMat:GetPBRMetalness()
		local roughness = surfMat:GetPBRRoughness()
		if(util.is_same_object(genericSurfMat,surfMat) or genericSurfMat:GetPBRMetalness() ~= metalness or genericSurfMat:GetPBRRoughness() ~= roughness) then
			preset:AddOption(surfMat:GetName(),surfMat:GetName())
		end
	end
	preset:Wrap("WIEditableEntry"):SetText(locale.get_text("preset"))
	preset:AddCallback("OnOptionSelected",function(el,option)
		local surfMat = phys.get_surface_material(el:GetOptionValue(option))
		if(surfMat == nil) then return end
		self.m_ctrlMetalness:SetValue(surfMat:GetPBRMetalness())
		self.m_ctrlRoughness:SetValue(surfMat:GetPBRRoughness())
		--[[local preset = presets[option +1]
		if(preset == nil) then return end
		if(preset.samples ~= nil) then samplesPerPixel:SetValue(preset.samples) end
		if(preset.max_transparency_bounces ~= nil) then maxTransparencyBounces:SetValue(preset.max_transparency_bounces) end
		if(preset.emission_strength ~= nil) then emissionStrength:SetValue(preset.emission_strength) end]]
	end)
	preset:SelectOption(0)

	-- Metalness
	local metalness = gui.create("WIPFMSlider",ctrlVbox)
	metalness:SetText(locale.get_text("metalness"))
	metalness:SetRange(0.0,1.0)
	metalness:SetDefault(0.0)
	metalness:SetTooltip(locale.get_text("pfm_metalness_desc"))
	metalness:SetStepSize(0.01)
	metalness:AddCallback("OnLeftValueChanged",function(el,value)
		self:ApplyMetalnessFactor(value)
	end)
	self.m_ctrlMetalness = metalness

	-- Roughness
	local roughness = gui.create("WIPFMSlider",ctrlVbox)
	roughness:SetText(locale.get_text("roughness"))
	roughness:SetRange(0.0,1.0)
	roughness:SetDefault(0.5)
	roughness:SetTooltip(locale.get_text("pfm_roughness_desc"))
	roughness:SetStepSize(0.01)
	roughness:AddCallback("OnLeftValueChanged",function(el,value)
		self:ApplyRoughnessFactor(value)
	end)
	self.m_ctrlRoughness = roughness

	-- Emission factor
	-- TODO: RGB!
	-- RGB Sliders?
	local emissionFactor = gui.create("WIPFMSlider",ctrlVbox)
	emissionFactor:SetText(locale.get_text("emission_factor"))
	emissionFactor:SetRange(0.0,1.0)
	emissionFactor:SetDefault(0.0)
	emissionFactor:SetTooltip(locale.get_text("pfm_emission_factor_desc"))
	emissionFactor:SetStepSize(0.01)
	emissionFactor:AddCallback("OnLeftValueChanged",function(el,value)
		self:ApplyEmissionFactor(value)
	end)
	self.m_ctrlEmissionFactor = emissionFactor

	-- Ao factor
	local aoFactor = gui.create("WIPFMSlider",ctrlVbox)
	aoFactor:SetText(locale.get_text("ao_factor"))
	aoFactor:SetRange(0.0,1.0)
	aoFactor:SetDefault(1.0)
	aoFactor:SetTooltip(locale.get_text("pfm_ao_factor_desc"))
	aoFactor:SetStepSize(0.01)
	aoFactor:AddCallback("OnLeftValueChanged",function(el,value)
		self:ApplyAmbientOcclusionFactor(value)
	end)
	self.m_ctrlAoFactor = aoFactor

	-- Subsurface method
	local sssMethod = gui.create("WIDropDownMenu",ctrlVbox)
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_none"),tostring(-1))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_cubic"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_CUBIC))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_gaussian"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_GAUSSIAN))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_principled"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_burley"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_BURLEY))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_random_walk"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_principled_random_walk"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED_RANDOM_WALK))
	sssMethod:SelectOption(0)
	sssMethod:AddCallback("OnOptionSelected",function(renderMode,idx)
		local val = tonumber(renderMode:GetOptionValue(idx))
		local sssEnabled = (val ~= -1)
		self.m_ctrlSSSFactor:SetVisible(sssEnabled)
		self.m_ctrlSSSColorWrapper:SetVisible(sssEnabled)
		self.m_ctrlSSSRadiusWrapper:SetVisible(sssEnabled)
		self:ApplySubsurfaceScattering()
	end)
	self.m_ctrlSSSMethod = sssMethod
	sssMethod:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_mated_sss_method"))

	-- Subsurface Scattering
	local sssFactor = gui.create("WIPFMSlider",ctrlVbox)
	sssFactor:SetText(locale.get_text("pfm_mated_sss_factor"))
	sssFactor:SetRange(0.0,0.2)
	sssFactor:SetDefault(0.01)
	-- sssFactor:SetTooltip(locale.get_text("sss_factor_desc"))
	sssFactor:SetStepSize(0.01)
	sssFactor:AddCallback("OnLeftValueChanged",function(el,value)
		self:ApplySubsurfaceScattering()
	end)
	self.m_ctrlSSSFactor = sssFactor
	self.m_ctrlSSSFactor:SetVisible(false)

	-- Subsurface color
	local sssColorEntry = gui.create("WIPFMColorEntry",ctrlVbox)
	sssColorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
		self:ApplySubsurfaceScattering()
	end)
	sssColorEntry:SetColor(Color(242,210,157))
	local sssColorEntryWrapper = sssColorEntry:Wrap("WIEditableEntry")
	sssColorEntryWrapper:SetText(locale.get_text("pfm_mated_sss_color"))
	self.m_ctrlSSSColor = sssColorEntry
	self.m_ctrlSSSColorWrapper = sssColorEntryWrapper
	self.m_ctrlSSSColorWrapper:SetVisible(false)

	-- Subsurface radius
	local sssRadius = gui.create("WITextEntry",ctrlVbox)
	sssRadius:SetText("112 52.8 1.6")
	sssRadius:AddCallback("OnTextEntered",function(pEntry)
		self:ApplySubsurfaceScattering()
	end)
	local sssRadiusWrapper = sssRadius:Wrap("WIEditableEntry")
	sssRadiusWrapper:SetText(locale.get_text("pfm_mated_sss_radius"))
	self.m_ctrlSSSRadius = sssRadius
	self.m_ctrlSSSRadiusWrapper = sssRadiusWrapper
	self.m_ctrlSSSRadiusWrapper:SetVisible(false)

	-- Alpha Mode
	local alphaMode = gui.create("WIDropDownMenu",ctrlVbox)
	alphaMode:AddOption(locale.get_text("alpha_mode_opaque"),tostring(game.Material.ALPHA_MODE_OPAQUE))
	alphaMode:AddOption(locale.get_text("alpha_mode_mask"),tostring(game.Material.ALPHA_MODE_MASK))
	alphaMode:AddOption(locale.get_text("alpha_mode_blend"),tostring(game.Material.ALPHA_MODE_BLEND))
	alphaMode:SelectOption(0)
	alphaMode:AddCallback("OnOptionSelected",function(renderMode,idx)
		local alphaMode = tonumber(renderMode:GetOptionValue(idx))
		self.m_ctrlAlphaCutoff:SetVisible(alphaMode == 1)
		self:SetMaterialParameter("int","alpha_mode",alphaMode)
	end)
	self.m_alphaMode = alphaMode
	alphaMode:Wrap("WIEditableEntry"):SetText(locale.get_text("alpha_mode"))

	-- Alpha Cutoff
	local alphaCutoff = gui.create("WIPFMSlider",ctrlVbox)
	alphaCutoff:SetText(locale.get_text("alpha_cutoff"))
	alphaCutoff:SetRange(0.0,1.0)
	alphaCutoff:SetDefault(0.5)
	-- alphaCutoff:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	alphaCutoff:SetStepSize(0.01)
	alphaCutoff:SetVisible(false)
	alphaCutoff:AddCallback("OnLeftValueChanged",function(el,value)
		self:SetMaterialParameter("float","alpha_cutoff",tostring(value))
	end)
	self.m_ctrlAlphaCutoff = alphaCutoff

	-- Color
	local colorEntry = gui.create("WIPFMColorEntry",ctrlVbox)
	colorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
		local vCol = newCol:ToVector4()
		self:SetMaterialParameter("vector4","color_factor",tostring(vCol))
	end)
	local colorEntryWrapper = colorEntry:Wrap("WIEditableEntry")
	colorEntryWrapper:SetText(locale.get_text("color_factor"))
	self.m_colorEntry = colorEntry

	gui.create("WIBase",ctrlVbox)
end
function gui.PFMMaterialEditor:SetMaterialParameter(type,key,val)
	if(util.is_valid(self.m_material) == false or self.m_material:IsError()) then return end
	local data = self.m_material:GetDataBlock()
	data:SetValue(type,key,tostring(val))
	self:ReloadMaterialDescriptor()
end
function gui.PFMMaterialEditor:ReloadMaterialDescriptor()
	self.m_material:InitializeShaderDescriptorSet(true)
	self.m_viewport:Render()
end
function gui.PFMMaterialEditor:ApplySubsurfaceScattering()
	if(util.is_valid(self.m_material) == false) then return end
	local data = self.m_material:GetDataBlock()
	local method = tonumber(self.m_ctrlSSSMethod:GetOptionValue(self.m_ctrlSSSMethod:GetSelectedOption()))
	if(method == -1) then data:RemoveValue("subsurface_scattering")
	else
		local block = data:AddBlock("subsurface_scattering")
		block:SetValue("int","method",tostring(method))
		block:SetValue("float","factor",tostring(self.m_ctrlSSSFactor:GetValue()))
		block:SetValue("color","color",tostring(self.m_ctrlSSSColor:GetValue()))
		block:SetValue("vector","radius",tostring(self.m_ctrlSSSRadius:GetValue()))
	end
	self:ReloadMaterialDescriptor()
end
function gui.PFMMaterialEditor:ApplyRoughnessFactor(roughness)
	self:SetMaterialParameter("float","roughness_factor",roughness)
end
function gui.PFMMaterialEditor:ApplyMetalnessFactor(metalness)
	self:SetMaterialParameter("float","metalness_factor",metalness)
end
function gui.PFMMaterialEditor:ApplyAmbientOcclusionFactor(ao)
	self:SetMaterialParameter("float","ao_factor",ao)
end
function gui.PFMMaterialEditor:ApplyEmissionFactor(emission)
	self:SetMaterialParameter("vector","emission_factor",tostring(emission) .. " " .. tostring(emission) .. " " .. tostring(emission))
end
function gui.PFMMaterialEditor:SetMaterial(mat,mdl)
	self.m_viewport:SetModel(mdl or "pfm/texture_sphere")
	self.m_viewport:ScheduleUpdate()

	self.m_material = game.load_material(mat)
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
	mdlC:SetMaterialOverride(0,mat)
	self.m_viewport:Render()

	local data = self.m_material:GetDataBlock()

	if(data:HasValue("roughness_factor")) then
		local roughnessFactor = data:GetFloat("roughness_factor")
		self.m_ctrlRoughness:SetValue(roughnessFactor)
		self.m_ctrlRoughness:SetDefault(roughnessFactor)
	end

	if(data:HasValue("metalness_factor")) then
		local metalnessFactor = data:GetFloat("metalness_factor")
		self.m_ctrlMetalness:SetValue(metalnessFactor)
		self.m_ctrlMetalness:SetDefault(metalnessFactor)
	end

	if(data:HasValue("ao_factor")) then
		local aoFactor = data:GetFloat("ao_factor")
		self.m_ctrlAoFactor:SetValue(aoFactor)
		self.m_ctrlAoFactor:SetDefault(aoFactor)
	end

	if(data:HasValue("emission_factor")) then
		local emissionFactor = data:GetVector("emission_factor")
		self.m_ctrlEmissionFactor:SetValue(emissionFactor.x)
		self.m_ctrlEmissionFactor:SetDefault(emissionFactor.x)
	end

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

	if(data:HasValue("alpha_mode")) then
		local alphaMode = data:GetInt("alpha_mode")
		self.m_alphaMode:SelectOption(tostring(alphaMode))
	end

	if(data:HasValue("alpha_cutoff")) then
		local alphaCutoff = data:GetFloat("alpha_cutoff")
		self.m_ctrlAlphaCutoff:SetValue(tostring(alphaCutoff))
	end

	if(data:HasValue("color_factor")) then
		local colorFactor = data:GetVector("color_factor")
		self.m_colorEntry:SetValue(Color(colorFactor))
	end

	local blockSSS = data:FindBlock("subsurface_scattering")
	if(blockSSS ~= nil) then
		if(blockSSS:HasValue("method")) then
			self.m_ctrlSSSMethod:SelectOption(tostring(blockSSS:GetInt("method")))
		end
		if(blockSSS:HasValue("factor")) then
			self.m_ctrlSSSFactor:SetValue(blockSSS:GetFloat("factor"))
		end
		if(blockSSS:HasValue("color")) then
			self.m_ctrlSSSColor:SetColor(blockSSS:GetColor("color"))
		end
		if(blockSSS:HasValue("radius")) then
			self.m_ctrlSSSRadius:SetValue(blockSSS:GetFloat("radius"))
		end
	end
end
function gui.PFMMaterialEditor:InitializePreviewControls()
	local btRaytracying = gui.create("WIPFMButton",self.m_renderControlsVbox)
	btRaytracying:SetText(locale.get_text("pfm_render_preview"))
	btRaytracying:AddCallback("OnPressed",function(btRaytracying)
		btRaytracying:SetEnabled(false)
		self.m_rtViewport:Refresh()
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
	self.m_ctrlIblStrength = iblStrength

	gui.create("WIBase",self.m_renderControlsVbox)
end
function gui.PFMMaterialEditor:SetRenderer(renderer)
	local realtime = (renderer == gui.PFMMaterialEditor.RENDERER_REALTIME)
	self.m_viewport:SetVisible(realtime)
	self.m_rtViewport:SetVisible(not realtime)
end
function gui.PFMMaterialEditor:InitializeViewport()
	local width = 1024
	local height = 1024
	local vpContainer = gui.create("WIBase",self.m_vpBox,0,0,width,height)
	self.m_viewport = gui.create("WIModelView",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_viewport:SetClearColor(Color.Clear)
	self.m_viewport:InitializeViewport(width,height)
	self.m_viewport:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))

	self.m_rtViewport = gui.create("WIRaytracedViewport",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_rtViewport:SetGameScene(self.m_viewport:GetScene())
	self.m_rtViewport:SetVisible(false)
	self.m_rtViewport:SetUseElementSizeAsRenderResolution(true)
	self.m_rtViewport:AddCallback("OnComplete",function()
		self.m_btRaytracying:SetEnabled(true)
		self:SetRenderer(gui.PFMMaterialEditor.RENDERER_RAYTRACING)
	end)

	local settings = self.m_rtViewport:GetRenderSettings()
	settings:SetSky("skies/dusk379.hdr")
	settings:SetWidth(width)
	settings:SetHeight(height)
	settings:SetSamples(40)
end
gui.register("WIPFMMaterialEditor",gui.PFMMaterialEditor)

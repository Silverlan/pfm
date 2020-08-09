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
include("controls_menu.lua")

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
	self:ResetOptions()
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

	local ctrlVbox = gui.create("WIPFMControlsMenu",self.m_controlBox)
	self.m_ctrlVBox = ctrlVbox

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
	self.m_pbrPreset = preset

	-- Metalness
	self.m_ctrlMetalness = ctrlVbox:AddSliderControl("metalness","metalness",0.0,0.0,1.0,function(el,value) self:ApplyMetalnessFactor(value) end,0.01)
	self.m_ctrlMetalness:SetTooltip(locale.get_text("pfm_metalness_desc"))

	-- Roughness
	self.m_ctrlRoughness = ctrlVbox:AddSliderControl("roughness","roughness",0.5,0.0,1.0,function(el,value) self:ApplyRoughnessFactor(value) end,0.01)
	self.m_ctrlRoughness:SetTooltip(locale.get_text("pfm_roughness_desc"))

	-- Emission factor
	-- TODO: RGB!
	-- RGB Sliders?
	self.m_ctrlEmissionFactor = ctrlVbox:AddSliderControl("emission_factor","emission_factor",0.0,0.0,1.0,function(el,value) self:ApplyEmissionFactor(value) end,0.01)
	self.m_ctrlEmissionFactor:SetTooltip(locale.get_text("pfm_emission_factor_desc"))

	-- Ao factor
	self.m_ctrlAoFactor = ctrlVbox:AddSliderControl("ao_factor","ao_factor",1.0,0.0,1.0,function(el,value) self:ApplyAmbientOcclusionFactor(value) end,0.01)
	self.m_ctrlAoFactor:SetTooltip(locale.get_text("pfm_ao_factor_desc"))

	-- Alpha Mode
	local alphaMode = gui.create("WIDropDownMenu",ctrlVbox)
	alphaMode:AddOption(locale.get_text("alpha_mode_opaque"),tostring(game.Material.ALPHA_MODE_OPAQUE))
	alphaMode:AddOption(locale.get_text("alpha_mode_mask"),tostring(game.Material.ALPHA_MODE_MASK))
	alphaMode:AddOption(locale.get_text("alpha_mode_blend"),tostring(game.Material.ALPHA_MODE_BLEND))
	alphaMode:AddCallback("OnOptionSelected",function(renderMode,idx)
		local alphaMode = tonumber(renderMode:GetOptionValue(idx))
		self.m_ctrlAlphaCutoff:SetVisible(alphaMode == 1)
		self:SetMaterialParameter("int","alpha_mode",alphaMode)
	end)
	self.m_alphaMode = alphaMode
	alphaMode:Wrap("WIEditableEntry"):SetText(locale.get_text("alpha_mode"))

	-- Alpha Cutoff
	self.m_ctrlAlphaCutoff = ctrlVbox:AddSliderControl("alpha_cutoff","alpha_cutoff",0.5,0.0,1.0,function(el,value) self:SetMaterialParameter("float","alpha_cutoff",tostring(value)) end,0.01)
	-- self.m_ctrlAlphaCutoff:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	self.m_ctrlAlphaCutoff:SetVisible(false)

	-- Color
	local colorEntry = gui.create("WIPFMColorEntry",ctrlVbox)
	colorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
		local vCol = newCol:ToVector4()
		self:SetMaterialParameter("vector4","color_factor",tostring(vCol))
	end)
	local colorEntryWrapper = colorEntry:Wrap("WIEditableEntry")
	colorEntryWrapper:SetText(locale.get_text("color_factor"))
	self.m_colorEntry = colorEntry

	-- Cycles options
	local cyclesHeader = gui.create("WIEditableEntry",ctrlVbox)
	cyclesHeader:SetEmpty()
	cyclesHeader:SetCategory(locale.get_text("pfm_mated_cycles_sss"))

	-- See https://blender.stackexchange.com/a/179561 for more information of SSS in Cycles
	-- Source: http://www.graphics.stanford.edu/papers/bssrdf/bssrdf.pdf / https://i.stack.imgur.com/npIk8.png
	local sssPresets = {
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_apple"),
			color = {0.846,0.841,0.528},
			radiusRGB = {0.696,0.640,0.190},
			radiusMM = {6.96,6.40,1.90},
			factor = 0.01,
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_chicken") .. " 01",
			color = {0.314,0.156,0.126},
			radiusRGB = {0.578,0.195,0.087},
			radiusMM = {11.61,3.88,1.75},
			factor = 0.02
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_chicken") .. " 02",
			color = {0.321,0.160,0.108},
			radiusRGB = {0.944,0.335,0.179},
			radiusMM = {9.44,3.35,1.79},
			factor = 0.01
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_cream"),
			color = {0.846,0.841,0.528},
			radiusRGB = {0.753,0.234,0.127},
			radiusMM = {15.03,4.66,2.54},
			factor = 0.02
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_ketchup"),
			color = {0.164,0.006,0.002},
			radiusRGB = {0.476,0.058,0.039},
			radiusMM = {4.76,0.58,0.39},
			factor = 0.01
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_marble"),
			color = {0.830,0.791,0.753},
			radiusRGB = {0.851,0.557,0.395},
			radiusMM = {8.51,5.57,3.95},
			factor = 0.01
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_potato"),
			color = {0.764,0.613,0.213},
			radiusRGB = {0.714,0.361,0.102},
			radiusMM = {14.27,7.23,2.04},
			factor = 0.02
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_skin") .. " 01",
			color = {0.436,0.227,0.131},
			radiusRGB = {0.367,0.137,0.068},
			radiusMM = {3.67,1.37,0.68},
			factor = 0.01
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_skin") .. " 02",
			color = {0.623,0.433,0.343},
			radiusRGB = {0.482,0.169,0.109},
			radiusMM = {4.82,1.69,1.09},
			factor = 0.01
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_skim_milk"),
			color = {0.815,0.813,0.682},
			radiusRGB = {0.921,0.522,0.175},
			radiusMM = {18.42,10.44,3.50},
			factor = 0.02
		},
		{
			name = locale.get_text("pfm_mated_cycles_sss_preset_whole_milk"),
			color = {0.908,0.881,0.759},
			radiusRGB = {0.545,0.329,0.125},
			radiusMM = {10.9,6.58,2.51},
			factor = 0.02
		}
	}
	local presetSSS = gui.create("WIDropDownMenu",ctrlVbox)
	presetSSS:AddOption("-","-")
	for i,preset in ipairs(sssPresets) do
		presetSSS:AddOption(preset.name,tostring(i))
	end
	presetSSS:Wrap("WIEditableEntry"):SetText(locale.get_text("preset"))
	presetSSS:AddCallback("OnOptionSelected",function(el,option)
		local preset = tonumber(el:GetOptionValue(el:GetSelectedOption()))
		if(sssPresets[preset] == nil) then return end
		preset = sssPresets[preset]
		-- self.m_ctrlSSSColor:SetColor(Color(Vector(preset.color[1],preset.color[2],preset.color[3])))
		self.m_ctrlSSSScatterColor:SetColor(Color(Vector(preset.radiusRGB[1],preset.radiusRGB[2],preset.radiusRGB[3])))
		self.m_ctrlSSSFactor:SetValue(preset.factor)
		if(tonumber(self.m_ctrlSSSMethod:GetOptionValue(self.m_ctrlSSSMethod:GetSelectedOption())) == -1) then
			self.m_ctrlSSSMethod:SelectOption(1)
		end
	end)
	self.m_presetSSS = presetSSS

	-- Subsurface method
	local sssMethod = gui.create("WIDropDownMenu",ctrlVbox)
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_none"),tostring(-1))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_principled_random_walk"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED_RANDOM_WALK))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_burley"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_BURLEY))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_cubic"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_CUBIC))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_gaussian"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_GAUSSIAN))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_principled"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_PRINCIPLED))
	sssMethod:AddOption(locale.get_text("pfm_mated_sss_method_random_walk"),tostring(game.SurfaceMaterial.SUBSURFACE_SCATTERING_METHOD_RANDOM_WALK))
	sssMethod:AddCallback("OnOptionSelected",function(renderMode,idx)
		local val = tonumber(renderMode:GetOptionValue(idx))
		local sssEnabled = (val ~= -1)
		self.m_ctrlSSSFactor:SetVisible(sssEnabled)
		-- self.m_ctrlSSSColorWrapper:SetVisible(sssEnabled)
		self.m_ctrlSSSScatterColorWrapper:SetVisible(sssEnabled)
		self:ApplySubsurfaceScattering()
	end)
	self.m_ctrlSSSMethod = sssMethod
	sssMethod:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_mated_sss_method"))

	-- Subsurface Scattering
	self.m_ctrlSSSFactor = ctrlVbox:AddSliderControl("sss_factor","pfm_mated_sss_factor",0.01,0.0,0.1,function(el,value) self:ApplySubsurfaceScattering() end,0.001)
	-- self.m_ctrlSSSFactor:SetTooltip(locale.get_text("sss_factor_desc"))
	self.m_ctrlSSSFactor:SetVisible(false)

	-- Subsurface color
	--[[local sssColorEntry = gui.create("WIPFMColorEntry",ctrlVbox)
	sssColorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
		self:ApplySubsurfaceScattering()
	end)
	sssColorEntry:SetColor(Color(242,210,157))
	local sssColorEntryWrapper = sssColorEntry:Wrap("WIEditableEntry")
	sssColorEntryWrapper:SetText(locale.get_text("pfm_mated_sss_color"))
	self.m_ctrlSSSColor = sssColorEntry
	self.m_ctrlSSSColorWrapper = sssColorEntryWrapper
	self.m_ctrlSSSColorWrapper:SetVisible(false)]]

	-- Subsurface radius
	local sssScatterColorEntry = gui.create("WIPFMColorEntry",ctrlVbox)
	sssScatterColorEntry:GetColorProperty():AddCallback(function(oldCol,newCol)
		self:ApplySubsurfaceScattering()
	end)
	sssScatterColorEntry:SetColor(Color(Vector(0.367,0.137,0.068))) -- Skin 01
	local sssScatterColorEntryWrapper = sssScatterColorEntry:Wrap("WIEditableEntry")
	sssScatterColorEntryWrapper:SetText(locale.get_text("pfm_mated_sss_scatter_color"))
	self.m_ctrlSSSScatterColor = sssScatterColorEntry
	self.m_ctrlSSSScatterColorWrapper = sssScatterColorEntryWrapper
	self.m_ctrlSSSScatterColorWrapper:SetVisible(false)

	-- Save
	local btSave = gui.create("WIPFMButton",ctrlVbox)
	btSave:SetText(locale.get_text("save"))
	btSave:AddCallback("OnPressed",function(btRaytracying)
		if(util.is_valid(self.m_material) == false or self.m_material:IsError()) then return end
		self.m_material:Save()
	end)
	self.m_btSave = btSave

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
		block:SetValue("vector","color_factor","1 1 1")
		block:SetValue("color","scatter_color",tostring(self.m_ctrlSSSScatterColor:GetValue()))
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
function gui.PFMMaterialEditor:ResetOptions()
	self.m_pbrPreset:SelectOption(0)
	self.m_ctrlRoughness:ResetToDefault()
	self.m_ctrlMetalness:ResetToDefault()
	self.m_ctrlAoFactor:ResetToDefault()
	self.m_ctrlEmissionFactor:ResetToDefault()
	self.m_alphaMode:SelectOption(0) -- Opaque
	self.m_ctrlAlphaCutoff:ResetToDefault()
	self.m_colorEntry:SetColor(Color.White)

	self.m_presetSSS:SelectOption(0)
	self.m_ctrlSSSMethod:SelectOption(0) -- Principled random walk
	self.m_ctrlSSSFactor:ResetToDefault()
	self.m_ctrlSSSScatterColor:SetColor(Color.White)
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
	mdlC:SetMaterialOverride(0,mat)
	self.m_viewport:Render()

	local material = game.load_material(mat)
	local data = material:GetDataBlock()

	self:ResetOptions()

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
		self.m_colorEntry:SetColor(Color(colorFactor))
	end

	local blockSSS = data:FindBlock("subsurface_scattering")
	if(blockSSS ~= nil) then
		if(blockSSS:HasValue("method")) then
			self.m_ctrlSSSMethod:SelectOption(tostring(blockSSS:GetInt("method")))
		end
		if(blockSSS:HasValue("factor")) then
			self.m_ctrlSSSFactor:SetValue(blockSSS:GetFloat("factor"))
		end
		--[[if(blockSSS:HasValue("color_factor")) then
			self.m_ctrlSSSColor:SetColor(blockSSS:GetColor("color_factor"))
		end]]
		if(blockSSS:HasValue("scatter_color")) then
			self.m_ctrlSSSScatterColor:SetColor(blockSSS:GetColor("scatter_color"))
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
end
function gui.PFMMaterialEditor:InitializePreviewControls()
	local btRaytracying = gui.create("WIPFMButton",self.m_renderControlsVbox)
	btRaytracying:SetText(locale.get_text("pfm_render_preview"))
	btRaytracying:AddCallback("OnPressed",function(btRaytracying)
		btRaytracying:SetEnabled(false)

		local settings = self.m_rtViewport:GetRenderSettings()
		local samples = 40
		-- Use a higher sample count if SSS is enabled
		if(self.m_ctrlSSSMethod:GetSelectedOption() ~= 0) then samples = 120 end
		settings:SetSamples(samples)

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
end
gui.register("WIPFMMaterialEditor",gui.PFMMaterialEditor)

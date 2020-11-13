--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMMaterialEditor:InitializePBRControls()
	local mapVbox = gui.create("WIVBox",self.m_controlBox)
	mapVbox:SetAutoFillContents(true)

	-- Shader
	--[[ctrlVbox:AddDropDownMenu("shader","shader",{
		["pbr"] = "pbr",
		["eye"] = "eye",
		["nodraw"] = "nodraw"
	},0,function(el,option)
		-- TODO
	end)]]

	-- Albedo map
	local numMaps = 6
	local fractionPerMap = 1.0 /numMaps
	local teAlbedoMap,tsAlbedoMap = self:AddTextureSlot(mapVbox,locale.get_text("albedo_map"),"albedo_map",false,true)
	self.m_teAlbedoMap = teAlbedoMap
	self.m_tsAlbedoMap = tsAlbedoMap
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap)

	-- Normal map
	local teNormalMap,texSlotNormalMap = self:AddTextureSlot(mapVbox,locale.get_text("normal_map"),"normal_map",true,false)
	self.m_teNormalMap = teNormalMap
	texSlotNormalMap:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *2)

	-- RMA map
	local teRMAMap,texSlotRMA = self:AddTextureSlot(mapVbox,locale.get_text("rma_map"),"rma_map",false,false)
	texSlotRMA:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
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
	local teEmission,tsEmission = self:AddTextureSlot(mapVbox,locale.get_text("emission_map"),"emission_map",false,false)
	tsEmission:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teEmissionMap = teEmission
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *4)

	-- Wrinkles
	local teWrinkles,tsWrinkles = self:AddTextureSlot(mapVbox,locale.get_text("wrinkle_compress_map"),"wrinkle_compress_map",false,false)
	tsWrinkles:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teWrinkleCompressMap = teWrinkles
	gui.create("WIResizer",mapVbox):SetFraction(fractionPerMap *5)

	local teStretch,tsStretch = self:AddTextureSlot(mapVbox,locale.get_text("wrinkle_stretch_map"),"wrinkle_stretch_map",false,false)
	tsStretch:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teWrinkleStretchMap = teStretch

	mapVbox:Update()
	
	gui.create("WIResizer",self.m_controlBox):SetFraction(0.6)

	local ctrlVbox = gui.create("WIPFMControlsMenu",self.m_controlBox)
	self.m_ctrlVBox = ctrlVbox

	-- Presets
	local pbrPresets = {{"-","-"}}
	local genericSurfMat = phys.get_surface_material("generic")
	local surfMats = phys.get_surface_materials()
	for _,surfMat in ipairs(surfMats) do
		local metalness = surfMat:GetPBRMetalness()
		local roughness = surfMat:GetPBRRoughness()
		if(util.is_same_object(genericSurfMat,surfMat) or genericSurfMat:GetPBRMetalness() ~= metalness or genericSurfMat:GetPBRRoughness() ~= roughness) then
			table.insert(pbrPresets,{surfMat:GetName(),surfMat:GetName()})
		end
	end
	local ctrlMetalness
	local ctrlRoughness
	ctrlVbox:AddDropDownMenu(locale.get_text("preset"),"preset",pbrPresets,0,function(el,option)
		local surfMat = phys.get_surface_material(el:GetOptionValue(option))
		if(surfMat == nil) then return end
		ctrlMetalness:SetValue(surfMat:GetPBRMetalness())
		ctrlRoughness:SetValue(surfMat:GetPBRRoughness())
		--[[local preset = presets[option +1]
		if(preset == nil) then return end
		if(preset.samples ~= nil) then samplesPerPixel:SetValue(preset.samples) end
		if(preset.max_transparency_bounces ~= nil) then maxTransparencyBounces:SetValue(preset.max_transparency_bounces) end
		if(preset.emission_strength ~= nil) then emissionStrength:SetValue(preset.emission_strength) end]]
	end)

	-- Metalness
	ctrlMetalness = ctrlVbox:AddSliderControl(locale.get_text("metalness"),"metalness",0.0,0.0,1.0,function(el,value) self:SetMaterialParameter("float","metalness_factor",value) end,0.01)
	ctrlMetalness:SetTooltip(locale.get_text("pfm_metalness_desc"))
	self:LinkControlToMaterialParameter("metalness",ctrlMetalness)

	-- Roughness
	ctrlRoughness = ctrlVbox:AddSliderControl(locale.get_text("roughness"),"roughness",0.5,0.0,1.0,function(el,value) self:SetMaterialParameter("float","roughness_factor",value) end,0.01)
	ctrlRoughness:SetTooltip(locale.get_text("pfm_roughness_desc"))
	self:LinkControlToMaterialParameter("roughness",ctrlRoughness)

	-- Emission factor
	-- TODO: RGB!
	-- RGB Sliders?
	local ctrlEmissionFactor = ctrlVbox:AddSliderControl(locale.get_text("emission_factor"),"emission_factor",0.0,0.0,1.0,function(el,value) self:SetMaterialParameter("vector","emission_factor",tostring(value) .. " " .. tostring(value) .. " " .. tostring(value)) end,0.01)
	ctrlEmissionFactor:SetTooltip(locale.get_text("pfm_emission_factor_desc"))
	self:LinkControlToMaterialParameter("emission_factor",ctrlEmissionFactor,nil,function(block)
		if(block:HasValue("emission_factor") == false) then return end
		local emissionFactor = block:GetVector("emission_factor")
		ctrlEmissionFactor:SetValue(emissionFactor.x)
		ctrlEmissionFactor:SetDefault(emissionFactor.x)
	end)

	-- Ao factor
	local ctrlAoFactor = ctrlVbox:AddSliderControl(locale.get_text("ao_factor"),"ao_factor",1.0,0.0,1.0,function(el,value) self:SetMaterialParameter("float","ao_factor",value) end,0.01)
	ctrlAoFactor:SetTooltip(locale.get_text("pfm_ao_factor_desc"))
	self:LinkControlToMaterialParameter("ao_factor",ctrlAoFactor)

	-- IOR
	local ctrlIOR = ctrlVbox:AddSliderControl(locale.get_text("pfm_mated_ior"),"ior",1.45,0.0,3.0,function(el,value) self:SetMaterialParameter("float","ior",value) end,0.01)
	self:LinkControlToMaterialParameter("ior",ctrlIOR)
	local presetValues = {
		{1.45,"default"}
	}
	for _,surfMat in ipairs(phys.get_surface_materials()) do
		local ior = surfMat:GetIOR()
		if(ior ~= nil) then
			table.insert(presetValues,{ior,locale.get_text("phys_material_" .. surfMat:GetName())})
		end
	end
	local wrapper = ctrlIOR:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text("pfm_mated_ior"))
	wrapper:SetPresetValues(presetValues)

	-- Alpha Mode
	local ctrlAlphaCutoff
	local ctrlAlphaFactor
	local ctrlAlphaMode = ctrlVbox:AddDropDownMenu(locale.get_text("alpha_mode"),"alpha_mode",{
		{tostring(game.Material.ALPHA_MODE_OPAQUE),locale.get_text("alpha_mode_opaque")},
		{tostring(game.Material.ALPHA_MODE_MASK),locale.get_text("alpha_mode_mask")},
		{tostring(game.Material.ALPHA_MODE_BLEND),locale.get_text("alpha_mode_blend")}
	},0,function(el,option)
		local alphaMode = tonumber(el:GetOptionValue(option))
		ctrlAlphaCutoff:SetVisible(alphaMode == 1)
		ctrlAlphaFactor:SetVisible(alphaMode ~= 0)
		self:SetMaterialParameter("int","alpha_mode",alphaMode)
		self:UpdateAlphaMode()
	end)
	self:LinkControlToMaterialParameter("alpha_mode",ctrlAlphaMode,nil,function(block)
		if(block:HasValue("alpha_mode") == false) then return end
		local alphaMode = block:GetInt("alpha_mode")
		ctrlAlphaMode:SelectOption(tostring(alphaMode))
	end)
	self.m_ctrlAlphaMode = ctrlAlphaMode

	-- Alpha Cutoff
	ctrlAlphaCutoff = ctrlVbox:AddSliderControl(locale.get_text("alpha_cutoff"),"alpha_cutoff",0.5,0.0,1.0,function(el,value) self:SetMaterialParameter("float","alpha_cutoff",tostring(value)) self:UpdateAlphaMode() end,0.01)
	self.m_ctrlAlphaCutoff = ctrlAlphaCutoff
	-- ctrlAlphaCutoff:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	self:LinkControlToMaterialParameter("alpha_cutoff",ctrlAlphaCutoff)
	ctrlAlphaCutoff:SetVisible(false)

	-- Alpha Factor
	ctrlAlphaFactor = ctrlVbox:AddSliderControl(locale.get_text("alpha_factor"),"alpha_factor",1.0,0.0,1.0,function(el,value) self:SetMaterialParameter("float","alpha_factor",tostring(value)) self:UpdateAlphaMode() end,0.01)
	self.m_ctrlAlphaFactor = ctrlAlphaFactor
	-- ctrlAlphaFactor:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	self:LinkControlToMaterialParameter("alpha_factor",ctrlAlphaFactor)
	ctrlAlphaFactor:SetVisible(false)

	-- Color
	local ctrlColorFactor = ctrlVbox:AddColorField(locale.get_text("color_factor"),"color_factor",Color.White,function(oldCol,newCol)
		local vCol = newCol:ToVector4()
		self:SetMaterialParameter("vector","color_factor",tostring(vCol))
	end)
	self:LinkControlToMaterialParameter("color_factor",ctrlColorFactor,nil,function(block)
		if(block:HasValue("color_factor") == false) then return end
		local colorFactor = block:GetVector("color_factor")
		ctrlColorFactor:SetColor(Color(colorFactor))
	end)

	-- Cycles options
	ctrlVbox:AddHeader(locale.get_text("pfm_mated_cycles"))

	local cyclesShaderList = {
		{
			name = locale.get_text("pfm_mated_cycles_shader_pbr"),
			identifier = "pbr"
		},
		{
			name = locale.get_text("pfm_mated_cycles_shader_glass"),
			identifier = "glass"
		},
		{
			name = locale.get_text("pfm_mated_cycles_shader_toon"),
			identifier = "toon"
		}
	}
	local options = {}
	for _,shaderData in ipairs(cyclesShaderList) do table.insert(options,{shaderData.identifier,shaderData.name}) end
	local ctrlCyclesShader = ctrlVbox:AddDropDownMenu(locale.get_text("pfm_mated_cycles_shader"),"cycles_shader",options,0,function(el,option)
		local shaderName = el:GetOptionValue(el:GetSelectedOption())
		for id,el in pairs(self.m_cyclesShaderControls) do el:SetVisible(false) end
		local el = self.m_cyclesShaderControls[shaderName]
		if(el ~= nil) then el:SetVisible(true) end

		local data = self:GetMaterialDataBlock()
		if(data == nil) then return end
		local cyclesBlock = data:AddBlock("cycles")
		cyclesBlock:SetValue("string","shader",shaderName)
	end)
	self:LinkControlToMaterialParameter("shader",ctrlCyclesShader,{"cycles"},function(block)
		if(block:HasValue("shader") == false) then return end
		ctrlCyclesShader:SelectOption(block:GetString("shader"))
	end)

	self.m_cyclesShaderControls = {}
	for _,shaderData in ipairs(cyclesShaderList) do
		local subMenu = ctrlVbox:AddSubMenu()
		self.m_cyclesShaderControls[shaderData.identifier] = subMenu
		self:InitializeCyclesOptions(subMenu,shaderData.identifier)
		subMenu:SetVisible(false)
	end

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

function gui.PFMMaterialEditor:UpdateAlphaMode()
	self.m_tsAlbedoMap:SetAlphaMode(tonumber(self.m_ctrlAlphaMode:GetValue()) or game.Material.ALPHA_MODE_OPAQUE)
	self.m_tsAlbedoMap:SetAlphaCutoff(tonumber(self.m_ctrlAlphaCutoff:GetValue()) or 0.5)
	self.m_tsAlbedoMap:SetAlphaFactor(tonumber(self.m_ctrlAlphaFactor:GetValue()) or 1.0)
end

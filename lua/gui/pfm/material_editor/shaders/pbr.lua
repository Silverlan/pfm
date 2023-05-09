--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMMaterialEditor:InitializePBRControls()
	local mapVbox = gui.create("WIVBox", self.m_controlBox)
	mapVbox:SetAutoFillContentsToWidth(true)

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
	local fractionPerMap = 1.0 / numMaps
	local teAlbedoMap, tsAlbedoMap =
		self:AddTextureSlot(mapVbox, locale.get_text("albedo_map"), "albedo_map", false, true)
	self.m_teAlbedoMap = teAlbedoMap
	self.m_tsAlbedoMap = tsAlbedoMap
	gui.create("WIResizer", mapVbox):SetFraction(fractionPerMap)

	-- Normal map
	local teNormalMap, texSlotNormalMap =
		self:AddTextureSlot(mapVbox, locale.get_text("normal_map"), "normal_map", true, false)
	self.m_teNormalMap = teNormalMap
	texSlotNormalMap:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	gui.create("WIResizer", mapVbox):SetFraction(fractionPerMap * 2)

	-- RMA map
	local teRMAMap, texSlotRMA = self:AddTextureSlot(mapVbox, locale.get_text("rma_map"), "rma_map", false, false)
	texSlotRMA:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teRMAMap = teRMAMap
	gui.create("WIResizer", mapVbox):SetFraction(fractionPerMap * 3)

	texSlotRMA:AddCallback("PopulateContextMenu", function(texSlotRMA, pContext)
		local matIdx
		if util.is_valid(self.m_model) then
			for i, mat in ipairs(self.m_model:GetMaterials()) do
				if mat:GetName() == self.m_material:GetName() then
					matIdx = i - 1
					break
				end
			end
		end
		if matIdx ~= nil then
			pContext:AddItem(locale.get_text("pfm_mated_compose_rma"), function()
				local dialog, frame, fileDialog = gui.create_dialog(function()
					local el = gui.create("WIRMAComposerDialog")
					if matIdx ~= nil then
						el:SetModel(self.m_model, matIdx)
					end
					local rmaTex = texSlotRMA:GetTexture()
					if rmaTex ~= nil then
						el:SetRMAMap(rmaTex)
					end
					el:AddCallback("OnRMAComposed", function(el, rmaMap)
						if util.is_valid(self.m_model) == false then
							return
						end
						local matPath = self.m_model:GetMaterialPaths()[1]
						if matPath == nil then
							return
						end
						local mdlName = file.remove_file_extension(file.get_file_name(self.m_model:GetName()))
						matPath = util.Path(matPath) + (mdlName .. "_rma")
						asset.lock_asset_watchers()
						local texInfo = util.TextureInfo()
						texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
						local result = util.save_image(rmaMap, "materials/" .. matPath:GetString(), texInfo)
						-- TODO: Doesn't work properly?
						-- local result,errMsg = asset.import_texture(rmaMap,asset.TextureImportInfo(),matPath:GetString())
						asset.unlock_asset_watchers()
						if result == false then
							console.print_warning("Unable to save RMA texture: ", errMsg)
							return
						end
						-- Force texture reload
						asset.reload(matPath:GetString(), asset.TYPE_TEXTURE)
						texSlotRMA:SetTexture(matPath:GetString())

						if util.is_valid(self.m_material) == false then
							return
						end
						self.m_material:SetTexture("rma_map", matPath:GetString())
						self.m_material:UpdateTextures()
						self:ReloadMaterialDescriptor()
						self.m_viewport:Render()

						teRMAMap:SetText(matPath:GetString())
					end)
					return el
				end)
				dialog:SetParent(tool.get_filmmaker())
			end)
		end
	end)

	-- Emission map
	local teEmission, tsEmission =
		self:AddTextureSlot(mapVbox, locale.get_text("emission_map"), "emission_map", false, false)
	tsEmission:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teEmissionMap = teEmission
	gui.create("WIResizer", mapVbox):SetFraction(fractionPerMap * 4)

	-- Wrinkles
	local teWrinkles, tsWrinkles =
		self:AddTextureSlot(mapVbox, locale.get_text("wrinkle_compress_map"), "wrinkle_compress_map", false, false)
	tsWrinkles:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teWrinkleCompressMap = teWrinkles
	gui.create("WIResizer", mapVbox):SetFraction(fractionPerMap * 5)

	local teStretch, tsStretch =
		self:AddTextureSlot(mapVbox, locale.get_text("wrinkle_stretch_map"), "wrinkle_stretch_map", false, false)
	tsStretch:SetAlphaMode(game.Material.ALPHA_MODE_OPAQUE)
	self.m_teWrinkleStretchMap = teStretch

	mapVbox:Update()
	mapVbox:SetFixedHeight(true)

	--[[local resizer = gui.create("WIResizer",self.m_controlBox)
	resizer:SetFraction(0.6)
	resizer:SetMoverMode(true)]]

	local ctrlVbox = gui.create("WIPFMControlsMenu", self.m_controlBox)
	ctrlVbox:SetAutoFillContentsToHeight(true)
	ctrlVbox:SetFixedHeight(false)
	self.m_ctrlVBox = ctrlVbox

	-- Presets
	local pbrPresets = { { "-", "-" } }
	local genericSurfMat = phys.get_surface_material("generic")
	local surfMats = phys.get_surface_materials()
	for _, surfMat in ipairs(surfMats) do
		local metalness = surfMat:GetPBRMetalness()
		local roughness = surfMat:GetPBRRoughness()
		if
			util.is_same_object(genericSurfMat, surfMat)
			or genericSurfMat:GetPBRMetalness() ~= metalness
			or genericSurfMat:GetPBRRoughness() ~= roughness
		then
			table.insert(pbrPresets, { surfMat:GetName(), surfMat:GetName() })
		end
	end
	local ctrlMetalness
	local ctrlRoughness
	local ctrlWetness
	ctrlVbox:AddDropDownMenu(locale.get_text("preset"), "preset", pbrPresets, 0, function(el, option)
		local surfMat = phys.get_surface_material(el:GetOptionValue(option))
		if surfMat == nil then
			return
		end
		ctrlMetalness:SetValue(surfMat:GetPBRMetalness())
		ctrlRoughness:SetValue(surfMat:GetPBRRoughness())
		ctrlWetness:SetValue(0.0)
		--[[local preset = presets[option +1]
		if(preset == nil) then return end
		if(preset.samples ~= nil) then samplesPerPixel:SetValue(preset.samples) end
		if(preset.max_transparency_bounces ~= nil) then maxTransparencyBounces:SetValue(preset.max_transparency_bounces) end
		if(preset.emission_strength ~= nil) then emissionStrength:SetValue(preset.emission_strength) end]]
	end)

	-- Metalness
	ctrlMetalness = ctrlVbox:AddSliderControl(
		locale.get_text("metalness"),
		"metalness",
		0.0,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "metalness_factor", value)
		end,
		0.01
	)
	ctrlMetalness:SetTooltip(locale.get_text("pfm_metalness_desc"))
	self:LinkControlToMaterialParameter("metalness_factor", ctrlMetalness)

	-- Roughness
	ctrlRoughness = ctrlVbox:AddSliderControl(
		locale.get_text("roughness"),
		"roughness",
		0.5,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "roughness_factor", value)
		end,
		0.01
	)
	ctrlRoughness:SetTooltip(locale.get_text("pfm_roughness_desc"))
	self:LinkControlToMaterialParameter("roughness_factor", ctrlRoughness)

	-- Wetness
	ctrlWetness = ctrlVbox:AddSliderControl(locale.get_text("wetness"), "wetness", 0.0, 0.0, 1.0, function(el, value)
		self:SetMaterialParameter("float", "wetness_factor", value)
	end, 0.01)
	ctrlWetness:SetTooltip(locale.get_text("pfm_wetness_desc"))
	self:LinkControlToMaterialParameter("wetness_factor", ctrlWetness)

	-- Emission factor
	local ctrlEmissionFactor = ctrlVbox:AddColorField(
		locale.get_text("emission_factor"),
		"emission_factor",
		Color.White,
		function(oldCol, newCol)
			local vCol = newCol:ToVector4()
			self:SetMaterialParameter("vector", "emission_factor", tostring(vCol))
		end
	)
	ctrlEmissionFactor:SetTooltip(locale.get_text("pfm_emission_factor_desc"))
	self:LinkControlToMaterialParameter("emission_factor", ctrlEmissionFactor, nil, function(block)
		if block:HasValue("emission_factor") == false then
			return
		end
		local colorFactor = block:GetVector("emission_factor")
		ctrlEmissionFactor:SetColor(Color(colorFactor))
	end)

	-- Emission strength
	local ctrlEmissionStrength = ctrlVbox:AddSliderControl(
		locale.get_text("emission_strength"),
		"emission_strength",
		1.0,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "emission_strength", value)
		end,
		0.01
	)
	ctrlEmissionStrength:SetTooltip(locale.get_text("pfm_emission_strength_desc"))
	self:LinkControlToMaterialParameter("emission_strength", ctrlEmissionStrength)

	-- Ao factor
	local ctrlAoFactor = ctrlVbox:AddSliderControl(
		locale.get_text("ao_factor"),
		"ao_factor",
		1.0,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "ao_factor", value)
		end,
		0.01
	)
	ctrlAoFactor:SetTooltip(locale.get_text("pfm_ao_factor_desc"))
	self:LinkControlToMaterialParameter("ao_factor", ctrlAoFactor)

	-- IOR
	local ctrlIOR = ctrlVbox:AddSliderControl(
		locale.get_text("pfm_mated_ior"),
		"ior",
		1.45,
		0.0,
		3.0,
		function(el, value)
			self:SetMaterialParameter("float", "ior", value)
		end,
		0.01
	)
	self:LinkControlToMaterialParameter("ior", ctrlIOR)
	local presetValues = {
		{ 1.45, "default" },
	}
	for _, surfMat in ipairs(phys.get_surface_materials()) do
		local ior = surfMat:GetIOR()
		if ior ~= nil then
			table.insert(presetValues, { ior, locale.get_text("phys_material_" .. surfMat:GetName()) })
		end
	end
	local wrapper = ctrlIOR:Wrap("WIEditableEntry")
	wrapper:SetText(locale.get_text("pfm_mated_ior"))
	wrapper:SetPresetValues(presetValues)

	-- Alpha Mode
	local ctrlAlphaCutoff
	local ctrlAlphaFactor
	local ctrlAlphaMode = ctrlVbox:AddDropDownMenu(
		locale.get_text("alpha_mode"),
		"alpha_mode",
		{
			{ tostring(game.Material.ALPHA_MODE_OPAQUE), locale.get_text("alpha_mode_opaque") },
			{ tostring(game.Material.ALPHA_MODE_MASK), locale.get_text("alpha_mode_mask") },
			{ tostring(game.Material.ALPHA_MODE_BLEND), locale.get_text("alpha_mode_blend") },
		},
		0,
		function(el, option)
			local alphaMode = tonumber(el:GetOptionValue(option))
			ctrlAlphaCutoff:SetVisible(alphaMode == 1)
			ctrlAlphaFactor:SetVisible(alphaMode ~= 0)
			self:SetMaterialParameter("int", "alpha_mode", alphaMode)
			self:UpdateAlphaMode()
		end
	)
	self:LinkControlToMaterialParameter("alpha_mode", ctrlAlphaMode, nil, function(block)
		if block:HasValue("alpha_mode") == false then
			return
		end
		local alphaMode = block:GetInt("alpha_mode")
		ctrlAlphaMode:SelectOption(tostring(alphaMode))
	end)
	self.m_ctrlAlphaMode = ctrlAlphaMode

	-- Alpha Cutoff
	ctrlAlphaCutoff = ctrlVbox:AddSliderControl(
		locale.get_text("alpha_cutoff"),
		"alpha_cutoff",
		0.5,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "alpha_cutoff", tostring(value))
			self:UpdateAlphaMode()
		end,
		0.01
	)
	self.m_ctrlAlphaCutoff = ctrlAlphaCutoff
	-- ctrlAlphaCutoff:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	self:LinkControlToMaterialParameter("alpha_cutoff", ctrlAlphaCutoff)
	ctrlAlphaCutoff:SetVisible(false)

	-- Alpha Factor
	ctrlAlphaFactor = ctrlVbox:AddSliderControl(
		locale.get_text("alpha_factor"),
		"alpha_factor",
		1.0,
		0.0,
		1.0,
		function(el, value)
			self:SetMaterialParameter("float", "alpha_factor", tostring(value))
			self:UpdateAlphaMode()
		end,
		0.01
	)
	self.m_ctrlAlphaFactor = ctrlAlphaFactor
	-- ctrlAlphaFactor:SetTooltip(locale.get_text("alpha_cutoff_desc"))
	self:LinkControlToMaterialParameter("alpha_factor", ctrlAlphaFactor)
	ctrlAlphaFactor:SetVisible(false)

	-- Color
	local ctrlColorFactor = ctrlVbox:AddColorField(
		locale.get_text("color_factor"),
		"color_factor",
		Color.White,
		function(oldCol, newCol)
			local vCol = newCol:ToVector4()
			self:SetMaterialParameter("vector", "color_factor", tostring(vCol))
		end
	)
	self:LinkControlToMaterialParameter("color_factor", ctrlColorFactor, nil, function(block)
		if block:HasValue("color_factor") == false then
			return
		end
		local colorFactor = block:GetVector("color_factor")
		ctrlColorFactor:SetColor(Color(colorFactor))
	end)

	-- Unirender options
	ctrlVbox:AddHeader(locale.get_text("pfm_mated_cycles"))

	local cyclesShaderList = {
		{
			name = locale.get_text("pfm_mated_cycles_shader_pbr"),
			identifier = "pbr",
		},
		{
			name = locale.get_text("pfm_mated_cycles_shader_glass"),
			identifier = "glass",
		},
		{
			name = locale.get_text("pfm_mated_cycles_shader_toon"),
			identifier = "toon",
		},
		{
			name = locale.get_text("pfm_mated_cycles_shader_volume"),
			identifier = "volume",
		},
	}
	local options = {}
	for _, shaderData in ipairs(cyclesShaderList) do
		table.insert(options, { shaderData.identifier, shaderData.name })
	end
	local ctrlUnirenderShader = ctrlVbox:AddDropDownMenu(
		locale.get_text("pfm_mated_cycles_shader"),
		"cycles_shader",
		options,
		0,
		function(el, option)
			local shaderName = el:GetOptionValue(el:GetSelectedOption())
			for id, el in pairs(self.m_cyclesShaderControls) do
				el:SetVisible(false)
			end
			local el = self.m_cyclesShaderControls[shaderName]
			if el ~= nil then
				el:SetVisible(true)
			end

			local data = self:GetMaterialDataBlock()
			if data == nil then
				return
			end
			local unirenderBlock = data:AddBlock("unirender")
			unirenderBlock:SetValue("string", "shader", shaderName)
		end
	)
	self:LinkControlToMaterialParameter("shader", ctrlUnirenderShader, { "unirender" }, function(block)
		if block:HasValue("shader") == false then
			return
		end
		ctrlUnirenderShader:SelectOption(block:GetString("shader"))
	end)

	self.m_cyclesShaderControls = {}
	for _, shaderData in ipairs(cyclesShaderList) do
		local subMenu = ctrlVbox:AddSubMenu()
		self.m_cyclesShaderControls[shaderData.identifier] = subMenu
		self:InitializeCyclesOptions(subMenu, shaderData.identifier)
		subMenu:SetVisible(false)
	end

	-- Fur
	local hairBlock = { "hair" }
	ctrlVbox:AddHeader(locale.get_text("pfm_mated_hair"))
	local hairMenu
	local ctrlHairEnabled = ctrlVbox:AddDropDownMenu(
		locale.get_text("enabled"),
		"hair_enabled",
		{
			{ "0", locale.get_text("no") },
			{ "1", locale.get_text("yes") },
		},
		0,
		function(menu, option)
			local enabled = tostring(menu:GetOptionValue(option))
			self:SetMaterialParameter("bool", "enabled", enabled, hairBlock)
			hairMenu:SetVisible(toboolean(enabled))
		end
	)
	self:LinkControlToMaterialParameter("enabled", ctrlHairEnabled, hairBlock, function(block)
		local enabled = true
		if block:HasValue("enabled") then
			enabled = block:GetBool("enabled")
		end
		ctrlHairEnabled:SelectOption(enabled and 1 or 0)
		hairMenu:SetVisible(enabled)
	end)
	hairMenu = ctrlVbox:AddSubMenu()
	hairMenu:SetVisible((ctrlHairEnabled:GetOptionValue(ctrlHairEnabled:GetSelectedOption()) == 1) and true or false)
	local ctrlHairPerSquareMeter = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_per_square_meter"),
		"hair_per_square_meter",
		1000000,
		0.0,
		50000000.0,
		function(el, value)
			self:SetMaterialParameter("float", "hair_per_square_meter", value, hairBlock)
		end,
		1
	)
	local ctrlHairSegmentCount = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_segment_count"),
		"hair_segment_count",
		2,
		0,
		6,
		function(el, value)
			self:SetMaterialParameter("float", "segment_count", value, hairBlock)
		end,
		1
	)
	local ctrlHairThickness = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_thickness"),
		"hair_thickness",
		0.005,
		0,
		0.1,
		function(el, value)
			self:SetMaterialParameter("float", "thickness", value, hairBlock)
		end,
		0.001
	)
	local ctrlHairLength = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_length"),
		"hair_length",
		0.6,
		0,
		10,
		function(el, value)
			self:SetMaterialParameter("float", "length", value, hairBlock)
		end,
		0.01
	)
	local ctrlHairStrength = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_strength"),
		"hair_strength",
		0.4,
		0,
		1,
		function(el, value)
			self:SetMaterialParameter("float", "strength", value, hairBlock)
		end,
		0.01
	)
	local ctrlHairRandomLengthFactor = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_random_hair_length_factor"),
		"hair_random_hair_length_factor",
		0.3,
		0,
		1,
		function(el, value)
			self:SetMaterialParameter("float", "random_hair_length_factor", value, hairBlock)
		end,
		0.01
	)
	local ctrlHairCurvature = hairMenu:AddSliderControl(
		locale.get_text("pfm_mated_hair_curvature"),
		"hair_curvature",
		0.6,
		0,
		1,
		function(el, value)
			self:SetMaterialParameter("float", "curvature", value, hairBlock)
		end,
		0.01
	)
	ctrlHairPerSquareMeter:SetTooltip(locale.get_text("pfm_mated_hair_per_square_meter_desc"))
	ctrlHairRandomLengthFactor:SetTooltip(locale.get_text("pfm_mated_hair_random_hair_length_factor_desc"))
	ctrlHairSegmentCount:SetTooltip(locale.get_text("pfm_mated_hair_segment_count_desc"))
	ctrlHairStrength:SetTooltip(locale.get_text("pfm_mated_hair_strength_desc"))
	self:LinkControlToMaterialParameter("hair_per_square_meter", ctrlHairPerSquareMeter, hairBlock)
	self:LinkControlToMaterialParameter("hair_segment_count", ctrlHairSegmentCount, hairBlock)
	self:LinkControlToMaterialParameter("hair_thickness", ctrlHairThickness, hairBlock)
	self:LinkControlToMaterialParameter("hair_length", ctrlHairLength, hairBlock)
	self:LinkControlToMaterialParameter("hair_strength", ctrlHairStrength, hairBlock)
	self:LinkControlToMaterialParameter("hair_random_hair_length_factor", ctrlHairRandomLengthFactor, hairBlock)
	self:LinkControlToMaterialParameter("hair_curvature", ctrlHairCurvature, hairBlock)

	-- Subdivision
	local subdivBlock = { "subdivision" }
	ctrlVbox:AddHeader(locale.get_text("pfm_mated_subdiv"))
	local subdivMenu
	local ctrlSubdivEnabled = ctrlVbox:AddDropDownMenu(
		locale.get_text("enabled"),
		"subdiv_enabled",
		{
			{ "0", locale.get_text("no") },
			{ "1", locale.get_text("yes") },
		},
		0,
		function(menu, option)
			local enabled = tostring(menu:GetOptionValue(option))
			self:SetMaterialParameter("bool", "enabled", enabled, subdivBlock)
			subdivMenu:SetVisible(toboolean(enabled))
		end
	)
	self:LinkControlToMaterialParameter("enabled", ctrlSubdivEnabled, subdivBlock, function(block)
		local enabled = true
		if block:HasValue("enabled") then
			enabled = block:GetBool("enabled")
		end
		ctrlSubdivEnabled:SelectOption(enabled and 1 or 0)
		subdivMenu:SetVisible(enabled)
	end)
	subdivMenu = ctrlVbox:AddSubMenu()
	subdivMenu:SetVisible(
		(ctrlSubdivEnabled:GetOptionValue(ctrlSubdivEnabled:GetSelectedOption()) == 1) and true or false
	)
	local ctrlSubdivSegCount = subdivMenu:AddSliderControl(
		locale.get_text("pfm_mated_subdiv_max_level"),
		"max_level",
		2,
		0,
		6,
		function(el, value)
			self:SetMaterialParameter("int", "max_level", value, subdivBlock)
		end,
		1
	)
	local ctrlSubdivMaxEdgeScreenSize = subdivMenu:AddSliderControl(
		locale.get_text("pfm_mated_subdiv_max_edge_screen_size"),
		"max_edge_screen_size",
		0,
		0,
		1,
		function(el, value)
			self:SetMaterialParameter("float", "max_edge_screen_size", value, subdivBlock)
		end,
		0.001
	)
	self:LinkControlToMaterialParameter("max_level", ctrlSubdivSegCount, subdivBlock)
	self:LinkControlToMaterialParameter("max_edge_screen_size", ctrlSubdivMaxEdgeScreenSize, subdivBlock)

	-- Save
	local btSave = gui.create("WIPFMButton", self.m_bg)
	local pBg = gui.create("WIRect", btSave, 0, 0, btSave:GetWidth(), btSave:GetHeight(), 0, 0, 1, 1)
	pBg:SetVisible(false)
	self.m_saveBg = pBg
	btSave:SetText(locale.get_text("save"))
	btSave:SetHeight(32)
	btSave:AddCallback("OnPressed", function(btRaytracying)
		local success = false
		if util.is_valid(self.m_material) and self.m_material:IsError() == false then
			success = self.m_material:Save()
		end
		if success then
			pfm.log("Successfully saved material '" .. self.m_material:GetName() .. "'!", pfm.LOG_CATEGORY_PFM)
			self:UpdateSaveButton(true)
		else
			pfm.log(
				"Failed to save material '" .. self.m_material:GetName() .. "'!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_ERROR
			)
		end
	end)
	btSave:SetWidth(self.m_bg:GetWidth())
	btSave:SetY(self.m_bg:GetBottom() - btSave:GetHeight() - 32)
	btSave:SetAnchor(0, 1, 1, 1)
	self.m_btSave = btSave

	local btOpenInExplorer = gui.create("WIPFMButton", self.m_bg)
	btOpenInExplorer:SetText(locale.get_text("pfm_open_in_explorer"))
	btOpenInExplorer:SetHeight(32)
	btOpenInExplorer:AddCallback("OnPressed", function(btRaytracying)
		if util.is_valid(self.m_material) == false then
			return
		end
		local filePath = asset.find_file(self.m_material:GetName(), asset.TYPE_MATERIAL)
		if filePath == nil then
			return
		end
		filePath = asset.get_asset_root_directory(asset.TYPE_MATERIAL) .. "/" .. filePath
		util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
	end)
	btOpenInExplorer:SetWidth(self.m_bg:GetWidth())
	btOpenInExplorer:SetY(self.m_bg:GetBottom() - btOpenInExplorer:GetHeight())
	btOpenInExplorer:SetAnchor(0, 1, 1, 1)
end

function gui.PFMMaterialEditor:UpdateSaveButton(saved)
	self.m_saveBg:SetVisible(true)
	if saved then
		self.m_saveBg:SetColor(Color(20, 100, 20))
	else
		self.m_saveBg:SetColor(Color(100, 20, 20))
	end
end

function gui.PFMMaterialEditor:UpdateAlphaMode()
	self.m_tsAlbedoMap:SetAlphaMode(tonumber(self.m_ctrlAlphaMode:GetValue()) or game.Material.ALPHA_MODE_OPAQUE)
	self.m_tsAlbedoMap:SetAlphaCutoff(tonumber(self.m_ctrlAlphaCutoff:GetValue()) or 0.5)
	self.m_tsAlbedoMap:SetAlphaFactor(tonumber(self.m_ctrlAlphaFactor:GetValue()) or 1.0)
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wimodelview.lua")

local function add_files(path,tFiles,assets)
	for _,f in ipairs(tFiles) do
		local filePath = util.Path(path .. f)
		filePath:RemoveFileExtension()
		filePath:PopFront()
		assets[filePath:GetString()] = true
	end
end

local function find_local_assets(path,extensions,recursive,assets)
	for _,ext in ipairs(extensions) do
		add_files(path,file.find(path .. "*." .. ext),assets)
	end
	if(recursive == false) then return end
	local _,tDirs = file.find(path .. "*")
	for _,d in ipairs(tDirs) do
		find_local_assets(path .. d .. "/",extensions,recursive,assets)
	end
end

local function find_assets(path,extensions,recursive,assets,pathsTraversed)
	if(assets == nil) then
		assets = {}
		find_local_assets(path,extensions,recursive,assets)
		find_assets(path,extensions,recursive,assets,{})
		local assetList = {}
		for assetPath,_ in pairs(assets) do
			table.insert(assetList,assetPath)
		end
		return assetList
	end

	if(pathsTraversed[path] ~= nil) then return end
	pathsTraversed[path] = true
	for _,ext in ipairs(extensions) do
		add_files(path,file.find_external_game_asset_files(path .. "*." .. ext),assets)
	end
	if(recursive == false) then return end
	-- Recursive search
	local _,tDirs = file.find_external_game_asset_files(path .. "*")
	for _,d in ipairs(tDirs) do
		local subPath = path .. d .. "/"
		find_assets(path .. d .. "/",extensions,recursive,assets,pathsTraversed)
	end
end

local function get_asset_list(assetPath,assetType,extensions,recursive)
	if(asset.exists(assetPath,assetType)) then return {assetPath} end
	local fileAssetPath = assetPath
	if(assetPath:sub(#assetPath) ~= "/" and assetPath:sub(#assetPath) ~= "\\") then assetPath = assetPath .. "/" end
	local rootDir
	if(assetType == asset.TYPE_MODEL) then rootDir = "models/"
	else rootDir = "materials/" end
	local isDir = file.is_directory(rootDir .. assetPath)
	if(isDir == false) then
		local _,tDirs = file.find_external_game_asset_files(rootDir .. assetPath)
		isDir = (#tDirs > 0)
	end
	if(isDir == false) then return {fileAssetPath} end
	print("'" .. assetPath .. "' is directory! Collecting assets...")
	return find_assets(util.Path(rootDir .. assetPath):GetString(),extensions,recursive)
end

local modelView
console.register_command("util_export_asset",function(pl,...)
	local exportInfo = game.Model.ExportInfo()
	exportInfo.verbose = false
	exportInfo.generateAo = true
	local mdlName
	local mapName
	local matName
	local texName
	local animName
	local recursive = false
	local listAnimations = false
	local enablePreview = true
	local cmdArgs = console.parse_command_arguments({...})
	local imageFormatToEnum = {
		["png"] = game.Model.ExportInfo.IMAGE_FORMAT_PNG,
		["bmp"] = game.Model.ExportInfo.IMAGE_FORMAT_BMP,
		["tga"] = game.Model.ExportInfo.IMAGE_FORMAT_TGA,
		["jpg"] = game.Model.ExportInfo.IMAGE_FORMAT_JPG,
		["hdr"] = game.Model.ExportInfo.IMAGE_FORMAT_HDR,
		["dds"] = game.Model.ExportInfo.IMAGE_FORMAT_DDS,
		["ktx"] = game.Model.ExportInfo.IMAGE_FORMAT_KTX
	}
	local deviceToEnum = {
		["cpu"] = game.Model.ExportInfo.DEVICE_CPU,
		["gpu"] = game.Model.ExportInfo.DEVICE_GPU
	}
	local format = "glTF"
	local gameIdentifier = ""
	for cmd,args in pairs(cmdArgs) do
		if(cmd == "export_animations") then
			if(args[1] ~= nil) then exportInfo.exportAnimations = toboolean(args[1])
			else exportInfo.exportAnimations = true end
		elseif(cmd == "export_skinned_mesh_data") then
			if(args[1] ~= nil) then exportInfo.exportSkinnedMeshData = toboolean(args[1])
			else exportInfo.exportSkinnedMeshData = true end
		elseif(cmd == "export_images") then
			if(args[1] ~= nil) then exportInfo.exportImages = toboolean(args[1])
			else exportInfo.exportImages = true end
		elseif(cmd == "export_morph_targets") then
			if(args[1] ~= nil) then exportInfo.exportMorphTargets = toboolean(args[1])
			else exportInfo.exportMorphTargets = true end
		elseif(cmd == "enable_extended_dds") then
			if(args[1] ~= nil) then exportInfo.enableExtendedDDS = toboolean(args[1])
			else exportInfo.enableExtendedDDS = true end
		elseif(cmd == "binary") then
			if(args[1] ~= nil) then exportInfo.saveAsBinary = toboolean(args[1])
			else exportInfo.saveAsBinary = true end
		elseif(cmd == "verbose") then
			if(args[1] ~= nil) then exportInfo.verbose = toboolean(args[1])
			else exportInfo.verbose = true end
		elseif(cmd == "generate_ao") then
			if(args[1] ~= nil) then exportInfo.generateAo = toboolean(args[1])
			else exportInfo.generateAo = true end
		elseif(cmd == "ao_resolution") then
			if(args[1] ~= nil) then exportInfo.aoResolution = math.round(tonumber(args[1])) end
		elseif(cmd == "ao_samples") then
			if(args[1] ~= nil) then exportInfo.aoSamples = math.round(tonumber(args[1])) end
		elseif(cmd == "ao_device") then
			if(args[1] ~= nil) then
				local device = args[1]
				exportInfo.aoDevice = deviceToEnum[device] or game.Model.ExportInfo.DEVICE_CPU
			end
		elseif(cmd == "scale") then
			if(args[1] ~= nil) then exportInfo.scale = tonumber(args[1]) end
		elseif(cmd == "merge_meshes_by_material") then
			if(args[1] ~= nil) then exportInfo.mergeMeshesByMaterial = toboolean(args[1])
			else exportInfo.mergeMeshesByMaterial = true end
		elseif(cmd == "image_format") then
			if(args[1] ~= nil) then
				local imgFormat = args[1]:lower()
				exportInfo.imageFormat = imageFormatToEnum[imgFormat] or game.Model.ExportInfo.IMAGE_FORMAT_PNG
			end
		elseif(cmd == "model") then mdlName = args[1]
		elseif(cmd == "map") then mapName = args[1]
		elseif(cmd == "material") then matName = args[1]
		elseif(cmd == "texture") then texName = args[1]
		elseif(cmd == "animation") then animName = args[1]
		elseif(cmd == "list_animations") then listAnimations = true
		elseif(cmd == "embed_animations") then
			if(args[1] ~= nil) then exportInfo.embedAnimations = toboolean(args[1])
			else exportInfo.embedAnimations = true end
		elseif(cmd == "full_export") then
			if(args[1] ~= nil) then exportInfo.fullExport = toboolean(args[1])
			else exportInfo.fullExport = true end
		elseif(cmd == "preview") then
			if(args[1] ~= nil) then enablePreview = toboolean(args[1])
			else enablePreview = true end
		elseif(cmd == "recursive") then
			if(args[1] ~= nil) then recursive = toboolean(args[1])
			else recursive = true end
		elseif(cmd == "normalize_texture_names") then
			if(args[1] ~= nil) then exportInfo.normalizeTextureNames = toboolean(args[1])
			else exportInfo.normalizeTextureNames = true end
		elseif(cmd == "format") then format = args[1]
		elseif(cmd == "game") then gameIdentifier = args[1] end
	end

	if(mdlName ~= nil) then
		local formats = asset.get_supported_import_file_extensions(asset.TYPE_MODEL)
		table.insert(formats,"wmd")
		local models = get_asset_list(mdlName,asset.TYPE_MODEL,formats,recursive)
		if(format == "mdl") then
			include("/util/source_model_exporter.lua")
			local result,err = util.export_source_engine_models(models,gameIdentifier)
			if(result == false) then console.print_warning("Export failed: " .. err) end
			return
		end
		for _,mdlName in ipairs(models) do
			local mdl = game.load_model(mdlName)
			if(mdl == nil) then
				console.print_warning("No model of name '" .. mdlName .. "' found!")
				return
			end
			if(listAnimations) then
				local animNames = mdl:GetAnimationNames()
				print("Model has " .. #animNames .. " animations:")
				console.print_table(animNames)
				return
			end
			if(animName == nil) then
				local result,err = mdl:Export(exportInfo)
				if(result) then print("Model exported successfully!")
				else console.print_warning("Unable to export model: ",err) end
			else
				local result,err = mdl:ExportAnimation(animName,exportInfo)
				if(result) then print("Animation exported successfully!")
				else console.print_warning("Unable to export animation: ",err) end
			end
		end
		if(#models == 0) then console.print_warning("No models found!") end
		if(enablePreview and #models == 1) then
			local mdl = game.load_model(models[1])
			if(mdl ~= nil) then
				if(util.is_valid(modelView) == false) then
					local resolution = engine.get_window_resolution()
					local width = resolution.x
					local height = resolution.y
					modelView = gui.create("WIModelView")
					modelView:SetSize(width,height)
					modelView:SetClearColor(Color.Black)
					modelView:InitializeViewport(width,height)
					modelView:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
					modelView:RequestFocus()
					modelView:TrapFocus()
				end
				modelView:SetModel(mdl)
				if(animName ~= nil) then modelView:PlayAnimation(animName)
				else modelView:PlayIdleAnimation() end
				modelView:Update()
			end
		end
	elseif(mapName ~= nil) then
		local result,err = asset.export_map(mapName,exportInfo)
		if(result) then print("Map exported successfully!")
		else console.print_warning("Unable to export map: ",err) end
	elseif(matName ~= nil) then
		local materials = get_asset_list(matName,asset.TYPE_MATERIAL,{"wmi","vmt","vmat_c"},recursive)
		if(#materials == 0) then console.print_warning("No materials found!") end
		for _,matName in ipairs(materials) do
			local result,err = asset.export_material(matName,exportInfo.imageFormat,exportInfo.normalizeTextureNames)
			if(result) then print("Material exported successfully!")
			else console.print_warning("Unable to export material: ",err) end
		end
	elseif(texName ~= nil) then
		local textures = get_asset_list(texName,asset.TYPE_TEXTURE,{"dds","png","tga","ktx","vtf","vtex_c"},recursive)
		if(#textures == 0) then console.print_warning("No textures found!") end
		for _,texName in ipairs(textures) do
			local result,err = asset.export_texture(texName,exportInfo.imageFormat)
			if(result) then print("Texture exported successfully!")
			else console.print_warning("Unable to export texture: ",err) end
		end
	else
		console.print_warning("No model, map, material or texture has been specified!")
		cmdArgs = nil
	end
	if(cmdArgs == nil) then
		print("Usage: util_export_asset ((-model <modelName> [-animation <animName>] [-list_animations]) | -map <mapName> | -material <matName> | -texture <texName>) [-format glTF/mdl] [-game <gameName>] [-verbose 1/0] [-binary 1/0] [-export_animations 1/0] [-export_skinned_mesh_data 1/0] [-export_images 1/0] [-image_format png/bmp/tga/jpg/hdr/dds/ktx] [-enable_extended_dds 1/0] [-generate_ao 1/0] [-ao_samples 32/64/128/256/512] [-ao_resolution 512/1024/2084/4096] [-scale <scale>] [-embed_animations 1/0]")
		return
	end
end)

function util.generate_ambient_occlusion_maps(model,width,height,samples,rebuild)
	if(rebuild == nil) then rebuild = false end
	if(type(model) == "string") then model = game.load_model(model) end
	if(model == nil) then return end
	local ent = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PBR_CONVERTER)})()
	if(ent == nil) then return end
	local pbrC = ent:GetComponent(ents.COMPONENT_PBR_CONVERTER)
	pbrC:GenerateAmbientOcclusionMaps(model,width or 512,height or 512,samples or 512,rebuild)
end
console.register_command("util_generate_ambient_occlusion",function(pl,...)
	local cmdArgs = console.parse_command_arguments({...})
	if(cmdArgs["model"] ~= nil and #cmdArgs["model"] > 0) then util.generate_ambient_occlusion_maps(cmdArgs["model"][1]) end

	if(cmdArgs["entity"] ~= nil and #cmdArgs["entity"] > 0) then
		local rebuild = toboolean(cmdArgs["rebuild"] and cmdArgs["rebuild"][1] or "0")
		local entIndex = tonumber(cmdArgs["entity"] and cmdArgs["entity"][1] or "")
		if(entIndex ~= nil) then
			local ent = ents.get_by_local_index(entIndex)
			if(ent ~= nil) then
				local width = tonumber(cmdArgs["width"] and cmdArgs["width"][1] or "512")
				local height = tonumber(cmdArgs["height"] and cmdArgs["height"][1] or "512")
				local samples = tonumber(cmdArgs["samples"] and cmdArgs["samples"][1] or "512")
				util.generate_ambient_occlusion_maps(ent,width,height,samples,rebuild)
			end
		end
	end
end)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local supportedExtensions = {"png","tga","dds","vtf"}--,"jpg","jpeg"} -- TODO
asset = asset or {}
function asset.is_image_type_supported(ext)
	local validExtension = false
	for _,extOther in ipairs(supportedExtensions) do
		if(ext == extOther) then
			validExtension = true
			break
		end
	end
	return validExtension
end

function asset.import_texture(texPath,outTexPath)
	texPath = file.remove_file_extension(texPath)
	outTexPath = outTexPath .. file.get_file_name(texPath)
	for _,ext in ipairs(supportedExtensions) do
		local extPath = texPath .. "." .. ext
		if(file.exists(extPath)) then
			texPath = extPath
			break
		end
	end
	local ext = file.get_file_extension(texPath)
	-- if(asset.is_image_type_supported(ext) == false) then return false,"Unsupported image format '" .. ext .. "'!" end
	local fTex = file.open(texPath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(fTex == nil) then return false,"Unable to open source image '" .. texPath .. "'!" end
	local outTexFilePath = "materials/" .. outTexPath .. ".dds"
	if(file.exists(outTexFilePath) or file.exists("materials/" .. outTexPath .. ".vtf")) then return true end
	if(ext == "tga" or ext == "png") then
		local success = engine.load_library("pr_dds")
		if(success == false) then
			fTex:Close()
			return false,"Unable to load dds module: " .. success
		end
		local convertInfo = convert.DDSConvertInfo()
		convertInfo.flags = convert.DDSConvertInfo.CONVERSION_FLAG_BIT_GENERATE_MIPMAPS

		local inputFormat = (ext == "tga") and convert.DDSConvertInfo.IMAGE_FORMAT_TGA or convert.DDSConvertInfo.IMAGE_FORMAT_PNG
		local success = convert.image_to_dds(
			fTex,
			inputFormat,
			outTexFilePath,
			convertInfo
		)
		fTex:Close()
		if(success == false) then
			return false,"Conversion of texture file '" .. texPath .. "' to DDS format has failed! Texture will not be imported!"
		end
		return true
	elseif(ext == "dds" or ext == "vtf") then
		-- Just copy the texture file
		local outputTexture = "materials/" .. outTexFilePath
		local fTexOut = file.open(outputTexture,bit.bor(file.OPEN_MODE_WRITE,file.OPEN_MODE_BINARY))
		if(fTexOut == nil) then
			fTex:Close()
			return false,"Unable to open output texture " .. outputTexture .. "!"
		end
		local ds = fTex:Read(fTex:Size())
		fTexOut:Write(ds)
		fTexOut:Close()

		fTex:Close()
		return true
	end
	return false,"Unsupported image extension '" .. ext .. "'!"
end

function asset.generate_material(name,materialData)
	local mat = game.create_material(name,"pbr")
	if(materialData.albedoMap ~= nil) then mat:SetTexture("albedo_map",materialData.albedoMap) end
	mat:Save(name)
	return mat
end

function asset.import_material_textures(mdl,textureLookupPaths)
	local matPath = mdl:GetMaterialPaths()[1]
	if(matPath == nil) then return false,"Model has no material path defined!" end
	local errMsg
	for _,name in ipairs(mdl:GetMaterialNames()) do
		local success = false
		for _,path in ipairs(textureLookupPaths) do
			if(#path > 0 and path:sub(#path) ~= "/" and path:sub(#path) ~= "\\") then path = path .. "/" end
			local result,msg = asset.import_texture(path .. name,matPath)
			if(result == false) then errMsg = msg
			else
				success = true
				break
			end
		end
		if(success) then
			local mat = game.load_material(name)
			if(mat ~= nil) then
				local matName = file.remove_file_extension(matPath .. mat:GetName())
				mat:SetTexture("albedo_map",matPath .. name) -- Re-assign albedo map
				mat:Save(matName)
			end
		end
	end
	errMsg = errMsg or "Unknown error"
	return false,errMsg
end

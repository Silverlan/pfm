--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("project_packer.lua")

function pfm.save_asset_files_as_archive(assetFiles,fileName)
	fileName = file.remove_file_extension(fileName) .. ".zip"
	util.pack_zip_archive(fileName,assetFiles)
	util.open_path_in_explorer(util.get_addon_path(),fileName)
end

function pfm.pack_models(mdls)
	if(#mdls == 0) then return end
	local packer = pfm.ProjectPacker()
	for _,mdl in ipairs(mdls) do
		packer:AddModel(mdl)
	end

	local mdlName = mdls[1]
	if(type(mdlName) ~= "string") then mdlName = mdlName:GetName() end

	file.create_directory("export")
	local fileName = file.get_file_name(mdlName)
	fileName = file.remove_file_extension(fileName,asset.get_supported_extensions(asset.TYPE_MODEL))
	pfm.save_asset_files_as_archive(packer:GetFiles(),"export/" .. fileName .. "_packed.zip")
end

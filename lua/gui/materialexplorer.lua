-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("assetexplorer.lua")
include("/util/util_asset_import.lua")

util.register_class("gui.MaterialExplorer", gui.AssetExplorer)
function gui.MaterialExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.MaterialExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_MATERIAL)
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_MATERIAL)
	table.insert(extensions, 1, asset.FORMAT_MATERIAL_BINARY)
	table.insert(extensions, 1, asset.FORMAT_MATERIAL_ASCII)
	self:SetFileExtensions(extensions, asset.get_supported_import_file_extensions(asset.TYPE_MATERIAL), {
		asset.FORMAT_MATERIAL_ASCII,
		asset.FORMAT_MATERIAL_BINARY,
	})
end
function gui.MaterialExplorer:PopulateContextMenu(pContext, tSelectedFiles)
	if #tSelectedFiles == 1 then
		local path = tSelectedFiles[1]:GetRelativeAsset()
		if asset.is_loaded(path, asset.TYPE_MATERIAL) == false then
			pContext:AddItem(locale.get_text("pfm_load"), function()
				game.load_material(path)
			end)
		else
			local mat = game.load_material(path)
			local name = file.remove_file_extension(file.get_file_name(mat:GetName()))
			pContext:AddItem(locale.get_text("pfm_edit_material"), function(pItem)
				tool.get_filmmaker():OpenMaterialEditor(path)
			end)
		end
	end
end
gui.register("WIMaterialExplorer", gui.MaterialExplorer)

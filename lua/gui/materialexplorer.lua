--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")

util.register_class("gui.MaterialExplorer",gui.AssetExplorer)
function gui.MaterialExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.MaterialExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_MATERIAL)
	self:SetFileExtensions(asset.MATERIAL_FILE_EXTENSION,{"vmt","vmat_c"})
end
function gui.MaterialExplorer:PopulateContextMenu(pContext,tSelectedFiles)
	if(#tSelectedFiles == 1) then
		local path = tSelectedFiles[1]:GetRelativeAsset()
		if(asset.is_loaded(path,asset.TYPE_MATERIAL) == false) then
			pContext:AddItem(locale.get_text("pfm_load"),function()
				game.load_material(path)
			end)
		else
			local mat = game.load_material(path)
			local name = file.remove_file_extension(file.get_file_name(mat:GetName()))
			pContext:AddItem(locale.get_text("pfm_edit_material"),function(pItem)
				tool.get_filmmaker():OpenMaterialEditor(path)
			end)
		end
	end
end
gui.register("WIMaterialExplorer",gui.MaterialExplorer)

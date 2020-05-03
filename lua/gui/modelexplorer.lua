--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")

util.register_class("gui.ModelExplorer",gui.AssetExplorer)
function gui.ModelExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.ModelExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_MODEL)
	self:SetFileExtensions(asset.MODEL_FILE_EXTENSION,{"mdl","vmdl_c","nif"})
end
function gui.ModelExplorer:PopulateContextMenu(pContext,tSelectedFiles)
	if(#tSelectedFiles == 1) then
		local path = tSelectedFiles[1]:GetRelativeAsset()
		pContext:AddItem(locale.get_text("pfm_show_in_model_viewer"),function()
			local pDialog,frame,el = gui.open_model_dialog()
			el:SetModel(path)
		end)

		if(asset.is_loaded(path,asset.TYPE_MODEL) == false) then
			pContext:AddItem(locale.get_text("pfm_load"),function()
				game.load_model(path)
			end)
		else
			local mdl = game.load_model(path)
			local materials = mdl:GetMaterials()
			if(#materials > 0) then
				local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_edit_material"))
				for _,mat in ipairs(materials) do
					if(mat:IsError() == false) then
						local name = file.remove_file_extension(file.get_file_name(mat:GetName()))
						pSubMenu:AddItem(name,function(pItem)
							tool.get_filmmaker():OpenMaterialEditor(mat:GetName(),path)
						end)
					end
				end
				pSubMenu:Update()
			end
		end
	end
end
gui.register("WIModelExplorer",gui.ModelExplorer)

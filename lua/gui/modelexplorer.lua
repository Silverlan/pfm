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
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_MODEL)
	table.insert(extensions,1,asset.MODEL_FILE_EXTENSION)
	self:SetFileExtensions(extensions,asset.get_supported_import_file_extensions(asset.TYPE_MODEL))
end
function gui.ModelExplorer:PopulateContextMenu(pContext,tSelectedFiles,tExternalFiles)
	self:CallCallbacks("PopulateContextMenu",pContext,tSelectedFiles,tExternalFiles)
end
gui.register("WIModelExplorer",gui.ModelExplorer)

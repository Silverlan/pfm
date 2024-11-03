--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")
include("/util/util_asset_import.lua")

util.register_class("gui.TextureExplorer", gui.AssetExplorer)
function gui.TextureExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.TextureExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_TEXTURE)
	local extensions = asset.get_supported_extensions(asset.TYPE_TEXTURE)
	self:SetFileExtensions(extensions, asset.get_supported_import_file_extensions(asset.TYPE_TEXTURE), extensions)
end
function gui.TextureExplorer:PopulateContextMenu(pContext, tSelectedFiles) end
gui.register("WITextureExplorer", gui.TextureExplorer)

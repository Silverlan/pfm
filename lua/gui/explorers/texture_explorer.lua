-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("asset_explorer.lua")
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
gui.register("texture_explorer", gui.TextureExplorer)

-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/textureexplorer.lua")
include("/gui/pfm/base_catalog.lua")

local Element = util.register_class("gui.PFMTextureCatalog", gui.PFMBaseCatalog)
function Element:InitializeFileIndexTable()
	self:SetFitPaths({ "addons/imported/materials/", "addons/converted/materials/" })

	return pfm.FileIndexTable("materials", "materials/", asset.get_supported_extensions(asset.TYPE_TEXTURE), {})
end
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("materials")

	local extensions = asset.get_supported_extensions(asset.TYPE_TEXTURE)
	for _, ext in ipairs(asset.get_supported_import_file_extensions(asset.TYPE_TEXTURE)) do
		table.insert(extensions, ext)
	end
	explorer:SetExtensions(extensions)
end
function Element:CreateIconExplorer(baseElement)
	return gui.create("WITextureExplorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("WIPFMTextureCatalog", Element)

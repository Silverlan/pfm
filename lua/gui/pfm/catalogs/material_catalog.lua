-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/explorers/material_explorer.lua")
include("/gui/pfm/catalogs/base_catalog.lua")

local Element = util.register_class("gui.PFMMaterialCatalog", gui.PFMBaseCatalog)
function Element:InitializeFileIndexTable()
	self:SetFitPaths({ "addons/imported/materials/", "addons/converted/materials/" })

	return pfm.FileIndexTable(
		"materials",
		"materials/",
		asset.get_supported_extensions(asset.TYPE_MATERIAL),
		{ "vmt", "vmat_c" }
	)
end
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("materials")

	local extensions = asset.get_supported_extensions(asset.TYPE_MATERIAL)
	for _, ext in ipairs(asset.get_supported_import_file_extensions(asset.TYPE_MATERIAL)) do
		table.insert(extensions, ext)
	end
	explorer:SetExtensions(extensions)
end
function Element:CreateIconExplorer(baseElement)
	return gui.create("material_explorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("pfm_material_catalog", Element)

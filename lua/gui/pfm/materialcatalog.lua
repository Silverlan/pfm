--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/materialexplorer.lua")
include("/gui/pfm/base_catalog.lua")

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
	return gui.create("WIMaterialExplorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("WIPFMMaterialCatalog", Element)

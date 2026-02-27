-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/explorers/particle_explorer.lua")
include("/gui/pfm/catalogs/base_catalog.lua")

local Element = util.register_class("gui.PFMParticleCatalog", gui.PFMBaseCatalog)
function Element:InitializeFileIndexTable()
	self:SetFitPaths({})

	return pfm.FileIndexTable(
		"particles",
		"particles/",
		{ asset.FORMAT_PARTICLE_SYSTEM_BINARY, asset.FORMAT_PARTICLE_SYSTEM_ASCII },
		asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM)
	)
end
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("particles")

	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_PARTICLE_SYSTEM)
	table.insert(extensions, asset.FORMAT_PARTICLE_SYSTEM_ASCII)
	table.insert(extensions, asset.FORMAT_PARTICLE_SYSTEM_BINARY)
	explorer:SetExtensions(extensions)
end
function Element:CreateIconExplorer(baseElement)
	return gui.create("particle_explorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("pfm_particle_catalog", Element)

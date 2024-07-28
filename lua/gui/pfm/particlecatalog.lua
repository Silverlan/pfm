--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/particleexplorer.lua")
include("/gui/pfm/base_catalog.lua")

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
	return gui.create("WIParticleExplorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("WIPFMParticleCatalog", Element)

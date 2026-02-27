-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/explorers/tutorial_explorer.lua")
include("/gui/pfm/catalogs/base_catalog.lua")

local Element = util.register_class("gui.PFMTutorialCatalog", gui.PFMBaseCatalog)
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("tutorials")
	explorer:SetExtensions({ "udm" })
end
function Element:CreateIconExplorer(baseElement)
	return gui.create("tutorial_explorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("pfm_tutorial_catalog", Element)

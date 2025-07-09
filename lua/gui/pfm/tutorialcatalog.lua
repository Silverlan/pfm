-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/tutorialexplorer.lua")
include("/gui/pfm/base_catalog.lua")

local Element = util.register_class("gui.PFMTutorialCatalog", gui.PFMBaseCatalog)
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("tutorials")
	explorer:SetExtensions({ "udm" })
end
function Element:CreateIconExplorer(baseElement)
	return gui.create("WITutorialExplorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
end
gui.register("WIPFMTutorialCatalog", Element)

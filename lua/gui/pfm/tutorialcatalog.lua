--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")

util.register_class("fudm.PFMEntityComponent",fudm.PFMSceneElement)
function fudm.PFMEntityComponent:__init(...)
	fudm.PFMSceneElement.__init(self,...)
end

function fudm.PFMEntityComponent:IsEntityComponent() return true end

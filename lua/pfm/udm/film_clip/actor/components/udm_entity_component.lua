--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")

util.register_class("udm.PFMEntityComponent",udm.PFMSceneElement)
function udm.PFMEntityComponent:__init(...)
	udm.PFMSceneElement.__init(self,...)
end

function udm.PFMEntityComponent:IsEntityComponent() return true end

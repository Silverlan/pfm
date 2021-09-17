--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")

fudm.ELEMENT_TYPE_PFM_ENTITY_COMPONENT_PROPERTIES = fudm.register_element("PFMEntityComponentProperties")

fudm.ELEMENT_TYPE_PFM_ENTITY_COMPONENT = fudm.register_type("PFMEntityComponent",{fudm.PFMSceneElement},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ENTITY_COMPONENT,"properties",fudm.PFMEntityComponentProperties())

function fudm.PFMEntityComponent:Initialize() end

function fudm.PFMEntityComponent:IsEntityComponent() return true end
function fudm.PFMEntityComponent:GetComponentName()
    local prop = self:GetProperty("component_type")
    if(prop == nil) then return "" end
    return prop:GetValue()
end

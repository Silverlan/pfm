--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_SPOT_LIGHT = udm.register_element("PFMSpotLight")

udm.register_element_property(udm.ELEMENT_TYPE_PFM_SPOT_LIGHT,"color",udm.Color(Color.White))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SPOT_LIGHT,"intensity",udm.Float(1000.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SPOT_LIGHT,"intensityType",udm.UInt8(ents.LightComponent.INTENSITY_TYPE_CANDELA))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SPOT_LIGHT,"falloffExponent",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SPOT_LIGHT,"maxDistance",udm.Float(1000.0))

function udm.PFMSpotLight:GetComponentName() return "pfm_light_spot" end

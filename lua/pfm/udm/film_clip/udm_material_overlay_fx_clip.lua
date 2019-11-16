--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_time_frame.lua")

udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP = udm.register_element("PFMMaterialOverlayFXClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"material",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"left",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"top",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"width",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"height",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL_OVERLAY_FX_CLIP,"fullscreen",udm.Bool(),{
	getter = "IsFullscreen"
})

function udm.PFMMaterialOverlayFXClip:Initialize()
	udm.BaseElement.Initialize(self)
end

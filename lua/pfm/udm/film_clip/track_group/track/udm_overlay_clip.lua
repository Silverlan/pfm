--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../../udm_time_frame.lua")

udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP = udm.register_element("PFMOverlayClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"material",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"left",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"top",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"width",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"height",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"fullscreen",udm.Bool(),{
	getter = "IsFullscreen"
})

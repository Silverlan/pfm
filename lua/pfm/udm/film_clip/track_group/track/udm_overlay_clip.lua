--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../../udm_time_frame.lua")

fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP = fudm.register_element("PFMOverlayClip")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"timeFrame",fudm.PFMTimeFrame())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"material",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"left",fudm.Int())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"top",fudm.Int())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"width",fudm.Int())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"height",fudm.Int())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP,"fullscreen",fudm.Bool(),{
	getter = "IsFullscreen"
})

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm/project/session/time_frame.lua")

sfm.register_element_type("MaterialOverlayFXClip")
sfm.link_dmx_type("DmeMaterialOverlayFXClip",sfm.MaterialOverlayFXClip)

sfm.BaseElement.RegisterProperty(sfm.MaterialOverlayFXClip,"timeFrame",sfm.TimeFrame)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"material","")
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"left",0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"top",0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"width",0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"height",0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip,"fullscreen",false,{
	getterName = "IsFullscreen"
})

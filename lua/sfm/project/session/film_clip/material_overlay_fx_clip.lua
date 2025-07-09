-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/sfm/project/session/time_frame.lua")

sfm.register_element_type("MaterialOverlayFXClip")
sfm.link_dmx_type("DmeMaterialOverlayFXClip", sfm.MaterialOverlayFXClip)

sfm.BaseElement.RegisterProperty(sfm.MaterialOverlayFXClip, "timeFrame", sfm.TimeFrame)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "material", "")
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "left", 0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "top", 0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "width", 0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "height", 0)
sfm.BaseElement.RegisterAttribute(sfm.MaterialOverlayFXClip, "fullscreen", false, {
	getterName = "IsFullscreen",
})

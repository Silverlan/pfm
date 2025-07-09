-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("track.lua")

sfm.register_element_type("TrackGroup")
sfm.link_dmx_type("DmeTrackGroup", sfm.TrackGroup)

sfm.BaseElement.RegisterArray(sfm.TrackGroup, "tracks", sfm.Track)
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup, "visible", true, {
	getterName = "IsVisible",
})
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup, "mute", false, {
	getterName = "IsMuted",
})

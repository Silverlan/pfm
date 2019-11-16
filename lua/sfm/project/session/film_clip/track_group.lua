--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track.lua")

sfm.register_element_type("TrackGroup")
sfm.link_dmx_type("DmeTrackGroup",sfm.TrackGroup)

sfm.BaseElement.RegisterArray(sfm.TrackGroup,"tracks",sfm.Track)
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup,"visible",true,{
	getterName = "IsVisible"
})
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup,"mute",false,{
	getterName = "IsMuted"
})

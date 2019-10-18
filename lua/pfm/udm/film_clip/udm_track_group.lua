--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track_group")

udm.ELEMENT_TYPE_PFM_TRACK_GROUP = udm.register_element("PFMTrackGroup")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK_GROUP,"tracks",udm.Array(udm.ELEMENT_TYPE_PFM_TRACK))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK_GROUP,"visible",udm.Bool(true),{
	getter = "IsVisible"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK_GROUP,"muted",udm.Bool(false),{
	getter = "IsMuted"
})

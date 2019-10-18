--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("film_clip")

udm.ELEMENT_TYPE_PFM_FILM_CLIP = udm.register_element("PFMFilmClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"actors",udm.Array(udm.ELEMENT_TYPE_PFM_ACTOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"trackGroups",udm.Array(udm.ELEMENT_TYPE_PFM_TRACK_GROUP))

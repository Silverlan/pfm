--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_film_clip.lua")
include("udm_settings.lua")

udm.ELEMENT_TYPE_PFM_SESSION = udm.register_element("PFMSession")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"activeClip",udm.PFMFilmClip())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"clips",udm.Array(udm.ELEMENT_TYPE_PFM_FILM_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"settings",udm.PFMSettings())

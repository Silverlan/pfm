--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_sound.lua")

udm.ELEMENT_TYPE_PFM_CHANNEL_CLIP = udm.register_element("PFMChannelClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CHANNEL_CLIP,"timeFrame",udm.PFMTimeFrame())

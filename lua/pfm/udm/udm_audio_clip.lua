--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_time_frame.lua")
include("udm_sound.lua")

udm.ELEMENT_TYPE_PFM_AUDIO_CLIP = udm.register_element("PFMAudioClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"sound",udm.PFMSound())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeInTime",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeOutTime",udm.Float(0.0))

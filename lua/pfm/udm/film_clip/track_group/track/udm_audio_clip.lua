--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_sound.lua")

fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP = fudm.register_element("PFMAudioClip")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"timeFrame",fudm.PFMTimeFrame())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"sound",fudm.PFMSound())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeInTime",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP,"fadeOutTime",fudm.Float(0.0))

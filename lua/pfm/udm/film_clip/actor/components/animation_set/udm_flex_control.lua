--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/track_group/track/udm_channel.lua")

fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL = fudm.register_element("PFMFlexControl")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"value",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"leftValue",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"rightValue",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"channel",fudm.PFMChannel())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"leftValueChannel",fudm.PFMChannel())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"rightValueChannel",fudm.PFMChannel())

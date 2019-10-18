--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_channel.lua")

udm.ELEMENT_TYPE_PFM_FLEX_CONTROL = udm.register_element("PFMFlexControl")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"value",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"leftValue",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"rightValue",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"channel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"leftValueChannel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,"rightValueChannel",udm.PFMChannel())

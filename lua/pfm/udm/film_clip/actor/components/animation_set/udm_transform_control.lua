--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/track_group/track/udm_channel.lua")

udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL = udm.register_element("PFMTransformControl")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"valuePosition",udm.Vector3())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"valueRotation",udm.Quaternion())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"positionChannel",udm.PFMChannel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"rotationChannel",udm.PFMChannel())

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/film_clip/track_group/track/udm_channel.lua")

fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL = fudm.register_element("PFMTransformControl")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"valuePosition",fudm.Vector3())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"valueRotation",fudm.Quaternion())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"positionChannel",fudm.PFMChannel())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,"rotationChannel",fudm.PFMChannel())

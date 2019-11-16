--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("control")

sfm.register_element_type("TransformControl")
sfm.link_dmx_type("DmeTransformControl",sfm.TransformControl)

sfm.BaseElement.RegisterAttribute(sfm.TransformControl,"valuePosition",Vector())
sfm.BaseElement.RegisterAttribute(sfm.TransformControl,"valueOrientation",Quaternion())
sfm.BaseElement.RegisterProperty(sfm.TransformControl,"positionChannel",sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.TransformControl,"orientationChannel",sfm.Channel)

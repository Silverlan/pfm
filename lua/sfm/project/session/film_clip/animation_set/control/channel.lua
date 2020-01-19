--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("channel")

sfm.register_element_type("Channel")
sfm.link_dmx_type("DmeChannel",sfm.Channel)

sfm.BaseElement.RegisterProperty(sfm.Channel,"log",sfm.Log)
sfm.BaseElement.RegisterProperty(sfm.Channel,"toElement")
sfm.BaseElement.RegisterAttribute(sfm.Channel,"toAttribute","")
sfm.BaseElement.RegisterProperty(sfm.Channel,"graphCurve",sfm.GraphEditorCurve)

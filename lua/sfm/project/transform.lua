--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("Transform")
sfm.link_dmx_type("DmeTransform",sfm.Transform)

sfm.BaseElement.RegisterAttribute(sfm.Transform,"position",Vector())
sfm.BaseElement.RegisterAttribute(sfm.Transform,"orientation",Quaternion())
sfm.BaseElement.RegisterAttribute(sfm.Transform,"scale",1.0)

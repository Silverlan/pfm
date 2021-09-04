--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("PackColorOperator")
sfm.link_dmx_type("DmePackColorOperator",sfm.PackColorOperator)

sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator,"red",1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator,"green",1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator,"blue",1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator,"alpha",1)

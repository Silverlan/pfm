--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("GlobalFlexControllerOperator")
sfm.link_dmx_type("DmeGlobalFlexControllerOperator",sfm.GlobalFlexControllerOperator)

sfm.BaseElement.RegisterAttribute(sfm.GlobalFlexControllerOperator,"flexWeight",0.0)
sfm.BaseElement.RegisterProperty(sfm.GlobalFlexControllerOperator,"gameModel",sfm.GameModel,nil,sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)

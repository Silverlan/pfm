--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ExpressionOperator")
sfm.link_dmx_type("DmeExpressionOperator",sfm.ExpressionOperator)

sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator,"result",0)
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator,"expr","")
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator,"spewresult",false)
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator,"value",0)

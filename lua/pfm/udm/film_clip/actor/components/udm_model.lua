--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_global_flex_controller_operator.lua")

udm.ELEMENT_TYPE_PFM_MODEL = udm.register_element("PFMModel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"modelName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"skin",udm.Int(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"bones",udm.Array(udm.ELEMENT_TYPE_TRANSFORM))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"flexWeights",udm.Array(udm.ATTRIBUTE_TYPE_FLOAT))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"flexControllerNames",udm.Array(udm.ATTRIBUTE_TYPE_STRING))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"globalFlexControllers",udm.Array(udm.ELEMENT_TYPE_PFM_GLOBAL_FLEX_CONTROLLER_OPERATOR))

function udm.PFMModel:GetComponentName() return "pfm_model" end

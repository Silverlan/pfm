--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_MODEL = udm.register_element("PFMModel")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"modelName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MODEL,"skin",udm.Int(0))

function udm.PFMModel:GetComponentName() return "pfm_model" end

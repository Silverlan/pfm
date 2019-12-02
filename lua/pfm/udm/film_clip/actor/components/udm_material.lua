--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_MATERIAL = udm.register_element("PFMMaterial")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL,"materialName",udm.String(""))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_MATERIAL,"overrideValues",udm.Map(udm.ATTRIBUTE_TYPE_STRING))

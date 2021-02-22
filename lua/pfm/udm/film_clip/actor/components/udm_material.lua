--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_MATERIAL = fudm.register_element("PFMMaterial")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_MATERIAL,"materialName",fudm.String(""))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_MATERIAL,"overrideValues",fudm.Map(fudm.ATTRIBUTE_TYPE_STRING))

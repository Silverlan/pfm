--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_SOUND = fudm.register_element("PFMSound")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SOUND,"soundName",fudm.String(""))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SOUND,"volume",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SOUND,"pitch",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SOUND,"origin",fudm.Vector3())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SOUND,"direction",fudm.Vector3())

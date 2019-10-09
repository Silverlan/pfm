--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_element.lua")

udm.ELEMENT_TYPE_TRANSFORM = udm.register_element("Transform")
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"position",udm.Vector3(Vector()))
udm.register_element_property(udm.ELEMENT_TYPE_TRANSFORM,"rotation",udm.Quaternion(Quaternion()))

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../udm_bone.lua")

udm.ELEMENT_TYPE_PFM_RIG_HANDLE = udm.register_type("PFMRigHandle",{udm.PFMBone},true)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RIG_HANDLE,"transform",udm.Transform())

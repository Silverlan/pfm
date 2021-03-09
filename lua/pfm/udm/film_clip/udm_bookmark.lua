--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_time_range.lua")

fudm.ELEMENT_TYPE_PFM_BOOKMARK = fudm.register_element("PFMBookmark")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_BOOKMARK,"timeRange",fudm.PFMTimeRange())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_BOOKMARK,"note",fudm.String(""))

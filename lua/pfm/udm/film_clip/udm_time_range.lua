--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_TIME_RANGE = fudm.register_element("PFMTimeRange")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_RANGE,"time",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TIME_RANGE,"duration",fudm.Float(0.0))

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_TIME_RANGE = udm.register_element("PFMTimeRange")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_RANGE,"time",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_RANGE,"duration",udm.Float(0.0))

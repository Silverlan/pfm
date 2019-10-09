--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/udm/elements/udm_element.lua")

udm.ELEMENT_TYPE_PFM_TIME_FRAME = udm.register_element("PFMTimeFrame")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"start",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TIME_FRAME,"duration",udm.Float(0.0))

function udm.PFMTimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end

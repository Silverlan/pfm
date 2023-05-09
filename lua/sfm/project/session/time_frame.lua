--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("TimeFrame")
sfm.link_dmx_type("DmeTimeFrame", sfm.TimeFrame)

sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "start", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "duration", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "offset", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "scale", 1.0)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("TimeSelection")

sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"enabled",false)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"hold_right",214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"relative",false)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"falloff_left",-214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"interpolator_left",6)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"falloff_right",214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"threshold",0.0005)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"hold_left",-214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"interpolator_right",6)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"resampleinterval",0.01)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection,"recordingstate",3)

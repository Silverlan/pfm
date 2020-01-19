--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("GraphEditorCurve")
sfm.link_dmx_type("DmeGraphEditorCurve",sfm.GraphEditorCurve)

sfm.BaseElement.RegisterArray(sfm.GraphEditorCurve,"keysTime_0",0.0)
sfm.BaseElement.RegisterArray(sfm.GraphEditorCurve,"keysValue_0",0.0)

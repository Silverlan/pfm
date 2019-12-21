--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS = udm.register_element("PFMRenderSettings")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"frameRate",udm.Int(24))

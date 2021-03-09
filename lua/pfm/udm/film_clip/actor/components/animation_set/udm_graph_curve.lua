--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_GRAPH_CURVE = fudm.register_element("PFMGraphCurve")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GRAPH_CURVE,"keyTimes",fudm.Array(fudm.ATTRIBUTE_TYPE_FLOAT))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GRAPH_CURVE,"keyValues",fudm.Array(fudm.ATTRIBUTE_TYPE_FLOAT))

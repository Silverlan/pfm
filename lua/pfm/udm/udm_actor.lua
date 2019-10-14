--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("components")

udm.ELEMENT_TYPE_PFM_ACTOR = udm.register_element("PFMActor")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"components",udm.Array(udm.ELEMENT_TYPE_ANY))

function udm.PFMActor:AddComponent(pfmComponent)
  self:GetComponents():PushBack(udm.Any(pfmComponent))
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_log_list.lua")

udm.ELEMENT_TYPE_PFM_LOG = udm.register_element("PFMLog")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_LOG,"layers",udm.Array(udm.ELEMENT_TYPE_PFM_LOG_LIST))

function udm.PFMLog:AddLayer(name)
  local logLayer = self:CreateChild(udm.ELEMENT_TYPE_PFM_LOG_LIST,name)
  self:GetLayers():PushBack(logLayer)
  return logLayer
end

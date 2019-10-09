--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("log_layer.lua")

util.register_class("sfm.Log",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.Log,"layers",sfm.LogLayer)

function sfm.Log:__init()
  sfm.BaseElement.__init(self,sfm.Log)
end

function sfm.Log:ToPFMLog(pfmLog)
  for _,logLayer in ipairs(self:GetLayers()) do
    local pfmLogLayer = pfmLog:AddLayer(logLayer:GetName())
    logLayer:ToPFMLogLayer(pfmLogLayer)
  end
end

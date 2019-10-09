--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("channel")

util.register_class("sfm.Channel",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.Channel,"log",sfm.Log)

function sfm.Channel:__init()
  sfm.BaseElement.__init(self,sfm.Channel)
end

function sfm.Channel:ToPFMChannel(pfmChannel)
  local log = self:GetLog()
  log:ToPFMLog(pfmChannel:GetLog())
end

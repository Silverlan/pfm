--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("control")

util.register_class("sfm.Control",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Control,"value")
sfm.BaseElement.RegisterAttribute(sfm.Control,"leftValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"rightValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"defaultValue",0.0)
sfm.BaseElement.RegisterProperty(sfm.Control,"channel",sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.Control,"rightvaluechannel",sfm.Channel,{
  getterName = "GetRightValueChannel",
  setterName = "SetRightValueChannel"
})
sfm.BaseElement.RegisterProperty(sfm.Control,"leftvaluechannel",sfm.Channel,{
  getterName = "GetLeftValueChannel",
  setterName = "SetLeftValueChannel"
})

function sfm.Control:__init()
  sfm.BaseElement.__init(self,sfm.Control)
end

function sfm.Control:ToPFMControl(pfmControl)
  pfmControl:SetValue(self:GetValue())
  pfmControl:SetLeftValue(self:GetLeftValue())
  pfmControl:SetRightValue(self:GetRightValue())
  local sfmChannel = self:GetChannel()
  if(sfmChannel ~= nil) then
    sfmChannel:ToPFMChannel(pfmControl:GetChannel())
  end
  
  sfmChannel = self:GetRightValueChannel()
  if(sfmChannel ~= nil) then
    sfmChannel:ToPFMChannel(pfmControl:GetRightValueChannel())
  end
  
  sfmChannel = self:GetLeftValueChannel()
  if(sfmChannel ~= nil) then
    sfmChannel:ToPFMChannel(pfmControl:GetLeftValueChannel())
  end
end

include("control")

util.register_class("sfm.Control",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Control,"value")
sfm.BaseElement.RegisterAttribute(sfm.Control,"leftValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"rightValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"defaultValue",0.0)
sfm.BaseElement.RegisterProperty(sfm.Control,"channel",sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.Control,"rightvaluechannel",sfm.Channel,"GetRightValueChannel")
sfm.BaseElement.RegisterProperty(sfm.Control,"leftvaluechannel",sfm.Channel,"GetLeftValueChannel")

function sfm.Control:__init()
  sfm.BaseElement.__init(self,sfm.Control)
end

function sfm.Control:ToPFMControl(pfmControl)
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

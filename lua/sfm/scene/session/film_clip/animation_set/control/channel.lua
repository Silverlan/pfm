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

util.register_class("sfm.TimeFrame",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"start",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"duration",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"offset",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"scale",1.0)

function sfm.TimeFrame:__init()
  sfm.BaseElement.__init(self,sfm.TimeFrame)
end

function sfm.TimeFrame:ToPFMTimeFrame(pfmTimeFrame)
	pfmTimeFrame:SetStart(self:GetStart())
	pfmTimeFrame:SetDuration(self:GetDuration())
end

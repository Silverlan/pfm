util.register_class("sfm.TimeFrame",sfm.BaseElement)
function sfm.TimeFrame:__init()
  sfm.BaseElement.__init(self)
end

function sfm.TimeFrame:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_start = self:LoadAttributeValue(el,"start",0.0)
  self.m_duration = self:LoadAttributeValue(el,"duration",0.0)
  self.m_offset = self:LoadAttributeValue(el,"offset",0.0)
  self.m_scale = self:LoadAttributeValue(el,"scale",1.0)
end

function sfm.TimeFrame:GetStart() return self.m_start end
function sfm.TimeFrame:GetDuration() return self.m_duration end
function sfm.TimeFrame:GetOffset() return self.m_offset end
function sfm.TimeFrame:GetScale() return self.m_scale end

function sfm.TimeFrame:ToPFMTimeFrame(pfmTimeFrame)
	pfmTimeFrame:SetStart(self:GetStart())
	pfmTimeFrame:SetDuration(self:GetDuration())
end

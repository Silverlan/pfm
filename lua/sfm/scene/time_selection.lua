util.register_class("sfm.TimeSelection",sfm.BaseElement)
function sfm.TimeSelection:__init()
  sfm.BaseElement.__init(self)
end

function sfm.TimeSelection:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_enabled = self:LoadAttributeValue(el,"enabled",false)
  self.m_holdRight = self:LoadAttributeValue(el,"hold_right",214748)
  self.m_relative = self:LoadAttributeValue(el,"relative",false)
  self.m_falloffLeft = self:LoadAttributeValue(el,"falloff_left",-214748)
  self.m_interpolatorLeft = self:LoadAttributeValue(el,"interpolator_left",6)
  self.m_falloffRight = self:LoadAttributeValue(el,"falloff_right",214748)
  self.m_threshold = self:LoadAttributeValue(el,"threshold",0.0005)
  self.m_holdLeft = self:LoadAttributeValue(el,"hold_left",-214748)
  self.m_interpolatorRight = self:LoadAttributeValue(el,"interpolator_right",6)
  self.m_resampleInterval = self:LoadAttributeValue(el,"resampleinterval",0.01)
  self.m_recordingState = self:LoadAttributeValue(el,"recordingstate",3)
end

function sfm.TimeSelection:IsEnabled() return self.m_enabled end
function sfm.TimeSelection:GetHoldRight() return self.m_holdRight end
function sfm.TimeSelection:GetRelative() return self.m_relative end
function sfm.TimeSelection:GetFalloffLeft() return self.m_falloffLeft end
function sfm.TimeSelection:GetInterpolatorLeft() return self.m_interpolatorLeft end
function sfm.TimeSelection:GetFalloffRight() return self.m_falloffRight end
function sfm.TimeSelection:GetThreshold() return self.m_threshold end
function sfm.TimeSelection:GetHoldLeft() return self.m_holdLeft end
function sfm.TimeSelection:GetInterpolatorRight() return self.m_interpolatorRight end
function sfm.TimeSelection:GetResampleInterval() return self.m_resampleInterval end
function sfm.TimeSelection:GetRecordingState() return self.m_recordingState end

util.register_class("sfm.ProgressiveRefinement",sfm.BaseElement)
function sfm.ProgressiveRefinement:__init()
  sfm.BaseElement.__init(self)
end

function sfm.ProgressiveRefinement:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_useAntialiasing = self:LoadAttributeValue(el,"useAntialiasing",1)
  self.m_useDepthOfField = self:LoadAttributeValue(el,"useDepthOfField",1)
  self.m_on = self:LoadAttributeValue(el,"on",1)
  self.m_overrideDepthOfFieldQuality = self:LoadAttributeValue(el,"overrideDepthOfFieldQuality",0)
  self.m_overrideMotionBlurQuality = self:LoadAttributeValue(el,"overrideMotionBlurQuality",0)
  self.m_useMotionBlur = self:LoadAttributeValue(el,"useMotionBlur",1)
  self.m_overrideDepthOfFieldQualityValue = self:LoadAttributeValue(el,"overrideDepthOfFieldQualityValue",1)
  self.m_overrideMotionBlurQualityValue = self:LoadAttributeValue(el,"overrideMotionBlurQualityValue",1)
  self.m_overrideShutterSpeed = self:LoadAttributeValue(el,"overrideShutterSpeed",0)
  self.m_overrideShutterSpeedValue = self:LoadAttributeValue(el,"overrideShutterSpeedValue",0.0208333)
end

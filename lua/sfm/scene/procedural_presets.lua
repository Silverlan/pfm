util.register_class("sfm.ProceduralPresets",sfm.BaseElement)
function sfm.ProceduralPresets:__init()
  sfm.BaseElement.__init(self)
end

function sfm.ProceduralPresets:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_jitterIterations = self:LoadAttributeValue(el,"jitteriterations",5)
  self.m_jitterScaleVector = self:LoadAttributeValue(el,"jitterscale_vector",2.5)
  self.m_jitterScale = self:LoadAttributeValue(el,"jitterscale",1)
  self.m_smoothIterations = self:LoadAttributeValue(el,"smoothiterations",5)
  self.m_smoothScaleVector = self:LoadAttributeValue(el,"smoothscale_vector",2.5)
  self.m_smoothScale = self:LoadAttributeValue(el,"smoothscale",1)
  self.m_staggerInterval = self:LoadAttributeValue(el,"staggerinterval",0.0833)
end

function sfm.ProceduralPresets:GetJitterIterations() return self.m_jitterIterations end
function sfm.ProceduralPresets:GetJitterScaleVector() return self.m_jitterScaleVector end
function sfm.ProceduralPresets:GetJitterScale() return self.m_jitterScale end
function sfm.ProceduralPresets:GetSmoothIterations() return self.m_smoothIterations end
function sfm.ProceduralPresets:GetSmoothScaleVector() return self.m_smoothScaleVector end
function sfm.ProceduralPresets:GetSmoothScale() return self.m_smoothScale end
function sfm.ProceduralPresets:GetStaggerInterval() return self.m_staggerInterval end

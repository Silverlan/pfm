include("render_settings")

util.register_class("sfm.RenderSettings",sfm.BaseElement)
function sfm.RenderSettings:__init()
  sfm.BaseElement.__init(self)
end

function sfm.RenderSettings:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_frameRate = self:LoadAttributeValue(el,"frameRate",24)
  self.m_drawToolRenderablesMask = self:LoadAttributeValue(el,"drawToolRenderablesMask",15)
  self.m_engineCameraEffects = self:LoadAttributeValue(el,"engineCameraEffects",false)
  self.m_lightAverage = self:LoadAttributeValue(el,"lightAverage",0)
  self.m_toneMapScale = self:LoadAttributeValue(el,"toneMapScale",1.0)
  self.m_modelLod = self:LoadAttributeValue(el,"modelLod",0)
  self.m_ambientOcclusionMode = self:LoadAttributeValue(el,"ambientOcclusionMode",1)
  self.m_showAmbientOcclusion = self:LoadAttributeValue(el,"showAmbientOcclusion",0)
  self.m_drawGameRenderablesMask = self:LoadAttributeValue(el,"drawGameRenderablesMask",216)
  self.m_progressiveRefinement = self:LoadProperty(el,"ProgressiveRefinement",sfm.ProgressiveRefinement)
end

function sfm.RenderSettings:GetFrameRate() return self.m_frameRate end
function sfm.RenderSettings:GetDrawToolRenderablesMask() return self.m_drawToolRenderablesMask end
function sfm.RenderSettings:GetEngineCameraEffects() return self.m_engineCameraEffects end
function sfm.RenderSettings:GetLightAverage() return self.m_lightAverage end
function sfm.RenderSettings:GetToneMapScale() return self.m_toneMapScale end
function sfm.RenderSettings:GetModelLod() return self.m_modelLod end
function sfm.RenderSettings:GetAmbientOcclusionMode() return self.m_ambientOcclusionMode end
function sfm.RenderSettings:GetShowAmbientOcclusion() return self.m_showAmbientOcclusion end
function sfm.RenderSettings:GetDrawGameRenderablesMask() return self.m_drawGameRenderablesMask end
function sfm.RenderSettings:GetProgressiveRefinement() return self.m_progressiveRefinement end

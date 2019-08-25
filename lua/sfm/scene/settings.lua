util.register_class("sfm.Settings",sfm.BaseElement)
function sfm.Settings:__init()
  sfm.BaseElement.__init(self)
end

function sfm.Settings:Load(el)
  sfm.BaseElement.Load(self,el)
  
  self.m_movieSettings = self:LoadProperty(el,"movieSettings",sfm.MovieSettings)
  self.m_timeSelection = self:LoadProperty(el,"timeSelection",sfm.TimeSelection)
  self.m_proceduralPresets = self:LoadProperty(el,"proceduralPresets",sfm.ProceduralPresets)
  self.m_renderSettings = self:LoadProperty(el,"renderSettings",sfm.RenderSettings)
  self.m_posterSettings = self:LoadProperty(el,"posterSettings",sfm.PosterSettings)
  --self.m_sharedPresetGroupSettings = self:LoadProperty(el,"sharedPresetGroupSettings")
  --self.m_graphEditorState = self:LoadProperty(el,"graphEditorState")
end

function sfm.Settings:GetMovieSettings() return self.m_movieSettings end
function sfm.Settings:GetTimeSelection() return self.m_timeSelection end
function sfm.Settings:GetProceduralPresets() return self.m_proceduralPresets end
function sfm.Settings:GetRenderSettings() return self.m_renderSettings end
function sfm.Settings:GetPosterSettings() return self.m_posterSettings end

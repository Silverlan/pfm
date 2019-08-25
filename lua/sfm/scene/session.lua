include("session")

util.register_class("sfm.Session",sfm.BaseElement)
function sfm.Session:__init(elSession)
  sfm.BaseElement.__init(self)
  self:Load(elSession)
end

function sfm.Session:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_settings = self:LoadProperty(el,"settings",sfm.Settings)
  self.m_clips = self:LoadArray(el,"clipBin",sfm.FilmClip)
end

function sfm.Session:GetSettings() return self.m_settings end
function sfm.Session:GetClips() return self.m_clips end

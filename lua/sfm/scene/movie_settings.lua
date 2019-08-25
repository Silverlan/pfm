util.register_class("sfm.MovieSettings",sfm.BaseElement)
function sfm.MovieSettings:__init()
  sfm.BaseElement.__init(self)
end

function sfm.MovieSettings:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_movieTarget = self:LoadAttributeValue(el,"videoTarget",6)
  self.m_clearDecals = self:LoadAttributeValue(el,"clearDecals",false)
  self.m_stereoscopic = self:LoadAttributeValue(el,"stereoscopic",false)
  self.m_audioTarget = self:LoadAttributeValue(el,"audioTarget",2)
  self.m_width = self:LoadAttributeValue(el,"width",1280)
  self.m_stereoSingleFile = self:LoadAttributeValue(el,"stereoSingleFile",false)
  self.m_height = self:LoadAttributeValue(el,"height",720)
  self.m_fileName = self:LoadAttributeValue(el,"filename","")
end

function sfm.MovieSettings:GetVideoTarget() return self.m_videoTarget end
function sfm.MovieSettings:GetClearDecals() return self.m_clearDecals end
function sfm.MovieSettings:GetStereoscopic() return self.m_stereoscopic end
function sfm.MovieSettings:GetAudioTarget() return self.m_audioTarget end
function sfm.MovieSettings:GetWidth() return self.m_width end
function sfm.MovieSettings:GetStereoSingleFile() return self.m_stereoSingleFile end
function sfm.MovieSettings:GetHeight() return self.m_height end
function sfm.MovieSettings:GetFileName() return self.m_fileName end

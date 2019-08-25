util.register_class("sfm.PosterSettings",sfm.BaseElement)
function sfm.PosterSettings:__init()
  sfm.BaseElement.__init(self)
end

function sfm.PosterSettings:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_width = self:LoadAttributeValue(el,"width",1920)
  self.m_constrainAspect = self:LoadAttributeValue(el,"constrainAspect",true)
  self.m_height = self:LoadAttributeValue(el,"height",1080)
  self.m_DPI = self:LoadAttributeValue(el,"DPI",300)
  self.m_heightInPixels = self:LoadAttributeValue(el,"heightInPixels",true)
  self.m_units = self:LoadAttributeValue(el,"units",0)
  self.m_widthInPixels = self:LoadAttributeValue(el,"widthInPixels",true)
end

function sfm.PosterSettings:GetWidth() return self.m_width end
function sfm.PosterSettings:GetConstrainAspect() return self.m_constrainAspect end
function sfm.PosterSettings:GetHeight() return self.m_height end
function sfm.PosterSettings:GetDPI() return self.m_DPI end
function sfm.PosterSettings:GetHeightInPixels() return self.m_heightInPixels end
function sfm.PosterSettings:GetUnits() return self.m_units end
function sfm.PosterSettings:GetWidthInPixels() return self.m_widthInPixels end

util.register_class("sfm.Camera",sfm.BaseElement)
function sfm.Camera:__init()
  sfm.BaseElement.__init(self)
end

function sfm.Camera:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_transform = self:LoadProperty(el,"transform",sfm.Transform)
end

function sfm.Camera:GetTransform() return self.m_transform end

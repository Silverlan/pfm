util.register_class("sfm.Transform",sfm.BaseElement)
function sfm.Transform:__init()
  sfm.BaseElement.__init(self)
end

function sfm.Transform:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_position = self:LoadAttributeValue(el,"position",Vector())
  self.m_orientation = self:LoadAttributeValue(el,"orientation",Quaternion())
end

function sfm.Transform:GetPosition() return self.m_position end
function sfm.Transform:GetOrientation() return self.m_orientation end

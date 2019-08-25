util.register_class("sfm.GameModel",sfm.BaseElement)
function sfm.GameModel:__init()
  sfm.BaseElement.__init(self)
end

function sfm.GameModel:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_transform = self:LoadProperty(el,"transform",sfm.Transform)
  self.m_modelName = self:LoadAttributeValue(el,"modelName","")
  self.m_skin = self:LoadAttributeValue(el,"skin",0)
end

function sfm.GameModel:GetTransform() return self.m_transform end
function sfm.GameModel:GetModelName() return self.m_modelName end
function sfm.GameModel:GetSkin() return self.m_skin end

include("animation_set")

util.register_class("sfm.AnimationSet",sfm.BaseElement)
function sfm.AnimationSet:__init()
  sfm.BaseElement.__init(self)
end

function sfm.AnimationSet:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_gameModel = self:LoadProperty(el,"gameModel",sfm.GameModel)
end

function sfm.AnimationSet:GetGameModel() return self.m_gameModel end

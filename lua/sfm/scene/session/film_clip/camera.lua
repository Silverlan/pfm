util.register_class("sfm.Camera",sfm.BaseElement)
util.register_class("sfm.Transform",sfm.BaseElement) -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.Camera,"transform",sfm.Transform)

function sfm.Camera:__init()
  sfm.BaseElement.__init(self,sfm.Camera)
end

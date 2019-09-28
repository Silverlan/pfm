util.register_class("sfm.GameModel",sfm.BaseElement)
util.register_class("sfm.Transform",sfm.BaseElement) -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.GameModel,"transform",sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.GameModel,"modelName","")
sfm.BaseElement.RegisterAttribute(sfm.GameModel,"skin",0)

function sfm.GameModel:__init()
  sfm.BaseElement.__init(self,sfm.GameModel)
end

function sfm.GameModel:ToPFMModel(pfmModel)
  local mdlName = self:GetModelName()
  if(#mdlName > 0) then
    mdlName = mdlName:sub(7) -- Remove "models/"-prefix
    mdlName = file.remove_file_extension(mdlName) .. ".wmd"
  end
  
  pfmModel:SetModelName(mdlName)
  self:GetTransform():ToPFMTransform(pfmModel:GetTransform())
  pfmModel:SetSkin(self:GetSkin())
end

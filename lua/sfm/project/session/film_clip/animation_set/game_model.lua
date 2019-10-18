--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.GameModel",sfm.BaseElement)
util.register_class("sfm.Transform",sfm.BaseElement) -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.GameModel,"transform",sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.GameModel,"modelName","")
sfm.BaseElement.RegisterAttribute(sfm.GameModel,"skin",0)

function sfm.GameModel:__init()
  sfm.BaseElement.__init(self,sfm.GameModel)
end

function sfm.GameModel:GetPragmaModelPath()
  local mdlName = self:GetModelName()
  if(#mdlName > 0) then
    mdlName = mdlName:sub(7) -- Remove "models/"-prefix
    mdlName = file.remove_file_extension(mdlName) .. ".wmd"
  end
  return mdlName
end

function sfm.GameModel:ToPFMModel(pfmModel)
  local mdlName = self:GetPragmaModelPath()
  pfmModel:SetModelName(mdlName)
  pfmModel:SetSkin(self:GetSkin())
end

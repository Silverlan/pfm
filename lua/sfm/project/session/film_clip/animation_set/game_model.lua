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
sfm.BaseElement.RegisterArray(sfm.GameModel,"bones",sfm.Transform)

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
  local mdl = game.load_model(mdlName)
  if(mdl == nil) then
    pfm.log("Unable to load model '" .. mdlName .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
  end

  for _,node in ipairs(self:GetBones()) do
    local name = string.remove_whitespace(node:GetName()) -- Format: "name (boneName)"
    local boneNameStart = name:find("%(")
    local boneNameEnd = name:match('.*()' .. "%)") -- Reverse find
    if(boneNameStart ~= nil and boneNameEnd ~= nil) then
      local boneName = name:sub(boneNameStart +1,boneNameEnd -1)
      local t = udm.create_element(udm.ELEMENT_TYPE_TRANSFORM)
      node:ToPFMTransformBone(t)
      t:SetName(boneName)

      if(mdl ~= nil and mdl:LookupBone(boneName) ~= -1) then
        local boneId = mdl:LookupBone(boneName)
        if(mdl:IsRootBone(boneId)) then
          t:SetPosition(sfm.convert_source_root_bone_position_to_pragma(t:GetPosition()))
          t:SetRotation(sfm.convert_source_root_bone_rotation_to_pragma(t:GetRotation()))
        end
      end

      pfmModel:GetBonesAttr():PushBack(t)
    end
  end
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.GenericDmeChild",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.GenericDmeChild,"transform",sfm.Transform,nil,sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL)

function sfm.GenericDmeChild:__init()
  sfm.BaseElement.__init(self,sfm.GenericDmeChild)
  self.m_children = {}
end

function sfm.GenericDmeChild:GetChildren() return self.m_children end

function sfm.GenericDmeChild:Load(el)
  sfm.BaseElement.Load(self,el)

  local children = el:GetAttrV("children") or {}
  if(#children == 0) then
    pfm.log("Child expected for clip child '" .. self:GetName() .. "' of type '" .. self:GetType() .. "', but none exists!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_ERROR)
    return
  end
  for _,value in ipairs(children) do
    local child = value:GetValue()
    local type = child:GetType()
    if(type == "DmeGameModel") then
      local gameModel = sfm.GameModel()
      gameModel:Load(child)
      table.insert(self.m_children,gameModel)
    elseif(type == "DmeCamera") then
      local camera = sfm.Camera()
      camera:Load(child)
      table.insert(self.m_children,camera)
    elseif(type == "DmeDag") then
        local sfmChild = sfm.GenericDmeChild()
        sfmChild:Load(child)
        table.insert(self.m_children,sfmChild)
    else
      pfm.log("Unsupported film clip child data type '" .. child:GetType() .. "' ('" .. child:GetName() .. "') of child '" .. child:GetName() .. "'!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
    end
  end
end

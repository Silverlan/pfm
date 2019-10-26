--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("scene")

util.register_class("sfm.Scene",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.Scene,"transform",sfm.Transform)

function sfm.Scene:__init()
  sfm.BaseElement.__init(self,sfm.Scene)
  self.m_children = {}
end

function sfm.Scene:GetChildren() return self.m_children end

function sfm.Scene:Load(el)
  sfm.BaseElement.Load(self,el)
  
  for _,attrChild in ipairs(el:GetAttrV("children") or {}) do
    local elChild = attrChild:GetValue()
    local type = elChild:GetType()
    if(type == "DmeProjectedLight") then
      local light = sfm.ProjectedLight()
      light:Load(elChild)
      table.insert(self.m_children,light)
    elseif(type == "DmeDag") then
      local child = sfm.GenericDmeChild()
      child:Load(elChild)
      table.insert(self.m_children,child)
    else
      pfm.log("Type '" .. type .. "' of child '" .. elChild:GetName() .. "' of scene '" .. self:GetName() .. "' is currently not supported! Child will be ignored!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
    end
  end
end

function sfm.Scene:GetChildren() return self.m_children end

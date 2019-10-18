--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.LogLayer",sfm.BaseElement)

function sfm.LogLayer:__init()
  sfm.BaseElement.__init(self,sfm.LogLayer)
  self.m_times = {}
  self.m_values = {}
end

function sfm.LogLayer:Load(el)
  sfm.BaseElement.Load(self,el)
  for _,elValue in ipairs(el:GetAttrV("values")) do
    table.insert(self.m_values,elValue:GetValue())
  end
  
  for _,elValue in ipairs(el:GetAttrV("times")) do
    table.insert(self.m_times,elValue:GetValue())
  end
end

function sfm.LogLayer:GetTimes() return self.m_times end
function sfm.LogLayer:GetValues() return self.m_values end
function sfm.LogLayer:GetType() return self.m_type end

function sfm.LogLayer:ToPFMLogLayer(pfmLogLayer,isBoneTransform)
  for _,t in ipairs(self:GetTimes()) do
    pfmLogLayer:GetTimesAttr():PushBack(udm.Float(t))
  end
  local TYPE_FLOAT = 0
  local TYPE_VECTOR3 = 1
  local TYPE_QUATERNION = 2
  local type = self:GetType()
  if(type == "DmeFloatLogLayer") then type = TYPE_FLOAT
  elseif(type == "DmeVector3LogLayer") then type = TYPE_VECTOR3
  elseif(type == "DmeQuaternionLogLayer") then type = TYPE_QUATERNION
  else
    console.print_warning("Unsupported log layer type: ",type)
    return
  end
  for _,v in ipairs(self:GetValues()) do
    local udmValue
    if(type == TYPE_FLOAT) then udmValue = udm.Float(v)
    elseif(type == TYPE_VECTOR3) then
      if(isBoneTransform == true) then v = sfm.convert_source_anim_set_position_to_pragma(v)
      else v = sfm.convert_source_transform_position_to_pragma(v) end
      udmValue = udm.Vector3(v)
    elseif(type == TYPE_QUATERNION) then
      if(isBoneTransform == true) then v = sfm.convert_source_anim_set_rotation_to_pragma(v)
      else v = sfm.convert_source_transform_rotation_to_pragma(v) end
      udmValue = udm.Quaternion(v)
    end
    pfmLogLayer:GetValuesAttr():PushBack(udmValue)
  end
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_VECTOR3 = udm.register_attribute("Vector3",Vector())
function udm.Vector3:WriteToBinary(ds) ds:WriteVector(self:GetValue()) end
function udm.Vector3:ReadFromBinary(ds) return ds:ReadVector() end
function udm.Vector3:Copy()
  return self.m_class(self:GetValue():Copy())
end
function udm.Vector3:ToASCIIString()
  local v = self:GetValue()
  return v.x .. " " .. v.y .. " " .. v.z
end
function udm.Vector3:LoadFromASCIIString(str)
  local v = string.split(str," ")
  self:SetValue(Vector(tonumber(v[1]),tonumber(v[2]),tonumber(v[3])))
end

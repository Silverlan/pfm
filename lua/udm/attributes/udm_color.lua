--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_COLOR = udm.register_attribute("Color",{0,0,0,0})
function udm.Color:WriteToBinary(ds)
  local v = self:GetValue()
  ds:WriteUInt8(v[1])
  ds:WriteUInt8(v[2])
  ds:WriteUInt8(v[3])
  ds:WriteUInt8(v[4])
end
function udm.Color:ReadFromBinary(ds)
  local v = {}
  table.insert(v,ds:ReadUInt8())
  table.insert(v,ds:ReadUInt8())
  table.insert(v,ds:ReadUInt8())
  table.insert(v,ds:ReadUInt8())
  self:SetValue(v)
end
function udm.Color:Copy()
  return self.m_class(self:GetValue():Copy())
end

function udm.Color:ToASCIIString()
  local v = self:GetValue()
  return tostring(v[1]) .. " " .. tostring(v[2]) .. " " .. tostring(v[3]) .. " " .. tostring(v[4])
end
function udm.Color:LoadFromASCIIString(str)
  local v = string.split(str," ")
  self:SetValue({toint(v[1]),toint(v[2]),toint(v[3]),toint(v[4])})
end

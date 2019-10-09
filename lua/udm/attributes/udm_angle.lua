--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_ANGLE = udm.register_attribute("Angle",EulerAngles())
function udm.Angle:WriteToBinary(ds)
  ds:WriteAngles(self:GetValue())
end
function udm.Angle:ReadFromBinary(ds)
  self:SetValue(ds:ReadAngles())
end
function udm.Angle:Copy()
  return self.m_class(self:GetValue():Copy())
end

function udm.Angle:ToASCIIString()
  local v = self:GetValue()
  return tostring(v.p) .. " " .. tostring(v.y) .. " " .. tostring(v.r)
end
function udm.Angle:LoadFromASCIIString(str)
  local v = string.split(str," ")
  self:SetValue(EulerAngles(tonumber(v[1]),tonumber(v[2]),tonumber(v[3])))
end

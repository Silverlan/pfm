--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_nil.lua")

udm.ATTRIBUTE_TYPE_ANY = udm.register_attribute("Any",udm.Nil())
function udm.Any:WriteToBinary(ds)
	local value = self:GetValue()
	ds:WriteString(udm.get_type_name(value:GetType())) -- TODO: Use a dictionary for these
	value:SaveToBinary(ds)
end
function udm.Any:ReadFromBinary(ds)
	local type = ds:ReadString()
	local el = udm.create(type)
	el:LoadFromBinary(ds)
	return el
end
function udm.Any:Copy()
  return self.m_class(self:GetValue():Copy())
end
function udm.Any:ToASCIIString()
  local value = self:GetValue()
  return "Any[" .. udm.get_type_name(value:GetType()) .. "][" .. v:ToASCIIString() .. "]"
end
function udm.Any:LoadFromASCIIString(str)
	str = str:sub(4)
  str = string.split(str,"][")
  local type = str[1]:sub(2,#str[1] -1)
  local strValue = str[2]:sub(2,#str[2] -1)
  local value = udm.create(type)
  value:LoadFromASCIIString(strValue)
  self:SetValue(value)
end

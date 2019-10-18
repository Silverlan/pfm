--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_base.lua")

util.register_class("udm.BaseAttribute",udm.BaseItem)
function udm.BaseAttribute:__init(class,value)
  udm.BaseItem.__init(self)
  self:SetValue(value)
  self.m_class = class
end

function udm.BaseAttribute:__tostring()
  return self:GetStringValue()
end

function udm.BaseAttribute:SetValue(value) self.m_value = value end
function udm.BaseAttribute:GetValue() return self.m_value end
function udm.BaseAttribute:GetStringValue() return self:ToASCIIString() end

function udm.BaseAttribute:SaveToBinary(ds)
  self:WriteToBinary(ds)
end
function udm.BaseAttribute:LoadFromBinary(ds)
  self:SetValue(self:ReadFromBinary(ds))
end
function udm.BaseAttribute:Copy()
  return self.m_class(self:GetValue())
end

function udm.BaseAttribute:IsArray()
  return self:GetType() == udm.ATTRIBUTE_TYPE_ARRAY
end

function udm.BaseAttribute:IsElement() return false end
function udm.BaseAttribute:IsAttribute() return true end

-- These should be overwritten by derived classes
function udm.BaseAttribute:WriteToBinary(ds) end
function udm.BaseAttribute:ReadFromBinary(ds) end

function udm.BaseAttribute:ToASCIIString() end
function udm.BaseAttribute:LoadFromASCIIString(str) end
--

function udm.create_attribute(type,value)
  return udm.create(type,value,false)
end

function udm.create_attribute_array(attrType)
  local array = udm.create_attribute(udm.ATTRIBUTE_TYPE_ARRAY)
  array:SetElementType(attrType)
  return array
end

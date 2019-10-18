--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.BaseElement",udm.BaseItem)
function udm.BaseElement:__init(class,name)
  udm.BaseItem.__init(self)
  self:SetName(name or "")
  self.m_class = class
  self.m_children = {}
  self.m_attributes = {}
  
  local type = self:GetType()
  local elData = udm.impl.get_type_data(type)
  if(elData == nil) then
    console.print_warning("Attempted to use unregistered element type " .. type .. " for UDM element '" .. self:GetName() .. "'!")
    return
  end
  for identifier,prop in pairs(elData.properties) do
    self["m_" .. identifier] = prop.defaultValue:Copy()
  end
end

function udm.BaseElement:SetProperty(name,prop)
  self["m_" .. name] = prop
  return self:GetProperty(name)
end
function udm.BaseElement:GetProperty(name) return self["m_" .. name] end

function udm.BaseElement:SetName(name) self.m_name = name end
function udm.BaseElement:GetName() return self.m_name end

function udm.BaseElement:GetChildren() return self.m_children end
function udm.BaseElement:GetAttributes() return self.m_attributes end

function udm.BaseElement:CreateChild(type,name)
  local el = udm.create_element(type,name)
  if(el == nil) then return end
  self:AddChild(el,name)
  return el
end

function udm.BaseElement:CreateAttribute(type,name)
  local attr = udm.create_attribute(type,name)
  if(attr == nil) then return end
  self:AddAttribute(attr,name)
  return attr
end

function udm.BaseElement:CreateAttributeArray(type,name)
  local attr = udm.create_attribute_array(type,name)
  if(attr == nil) then return end
  self:AddAttribute(attr,name)
  return attr
end

function udm.BaseElement:IsElement() return true end
function udm.BaseElement:IsAttribute() return false end

function udm.BaseElement:AddChild(element,name)
  self.m_children[name] = element
  return element
end

function udm.BaseElement:RemoveChild(name)
  self.m_children[name] = nil
end

function udm.BaseElement:AddAttribute(attr,name)
  self.m_attributes[name] = attr
  return attr
end

function udm.BaseElement:RemoveAttribute(name)
  self.m_attributes[name] = nil
end

function udm.BaseElement:GetType() return -1 end

function udm.BaseElement:Copy()
  local copy = self.m_class(self:GetName())
  
  local type = self:GetType()
  local elData = udm.impl.get_type_data(type)
  if(elData == nil) then return copy end
  for _,prop in pairs(elData.properties) do
    prop.setterAttribute(copy,prop.getterAttribute(self):Copy())
  end
  return copy
end

function udm.BaseElement:SaveToBinary(ds)
  ds:WriteString(self:GetName())
  
  local type = self:GetType()
  local elData = udm.impl.get_type_data(type)
  if(elData == nil) then return end
  for _,prop in pairs(elData.properties) do
    prop.getter(self):SaveToBinary(ds)
  end
end
function udm.BaseElement:LoadFromBinary(ds)
  self:SetName(ds:ReadString())
  
  local type = self:GetType()
  local elData = udm.impl.get_type_data(type)
  if(elData == nil) then return end
  for _,prop in pairs(elData.properties) do
    prop.getter(self):LoadFromBinary(ds)
  end
end

function udm.create_element(type,name)
  return udm.create(type,name,true)
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.BaseElement",udm.BaseItem)

udm.impl = udm.impl or {}
udm.impl.registered_elements = udm.impl.registered_elements or {}
udm.impl.class_to_element_id = udm.impl.class_to_element_id or {}
local registered_elements = udm.impl.registered_elements
function udm.BaseElement:__init(class,name)
  udm.BaseItem.__init(self)
  self:SetName(name or "")
  self.m_class = class
  self.m_children = {}
  self.m_attributes = {}
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then
    console.print_warning("Unregistered element type!")
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
  local elData = registered_elements[type]
  if(elData == nil) then return copy end
  for _,prop in pairs(elData.properties) do
    prop.setter(copy,prop.getter(self):Copy())
  end
  return copy
end

function udm.BaseElement:SaveToBinary(ds)
  ds:WriteString(self:GetName())
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then return end
  for _,prop in pairs(elData.properties) do
    prop.getter(self):SaveToBinary(ds)
  end
end
function udm.BaseElement:LoadFromBinary(ds)
  self:SetName(ds:ReadString())
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then return end
  for _,prop in pairs(elData.properties) do
    prop.getter(self):LoadFromBinary(ds)
  end
end

function udm.register_element(className)
  util.register_class("udm." .. className,udm.BaseElement)
  local class = udm[className]
  if(udm.impl.class_to_element_id[class] ~= nil) then return udm.impl.class_to_element_id[class] end
  function class:__init(name)
    udm.BaseElement.__init(self,class,name)
  end
  
  local typeId = #registered_elements +1
  function class:GetType()
    return typeId
  end
  function class:__tostring()
    return "UDLElement[" .. className .. "]"
  end
  
  registered_elements[typeId] = {
    class = class,
    properties = {}
  }
  udm.impl.class_to_element_id[class] = typeId
  return typeId
end

function udm.register_element_property(elType,propIdentifier,defaultValue)
  local elData = registered_elements[elType]
  local methodIdentifier = propIdentifier:sub(1,1):upper() .. propIdentifier:sub(2)
  elData.class["Get" .. methodIdentifier] = function(self) return self["m_" .. propIdentifier] end
  elData.class["Set" .. methodIdentifier] = function(self,value) self["m_" .. propIdentifier] = value end
  elData.properties[propIdentifier] = {
    getter = elData.class["Get" .. methodIdentifier],
    setter = elData.class["Set" .. methodIdentifier],
    defaultValue = defaultValue
  }
end

function udm.create_element(elType,name)
  if(registered_elements[elType] == nil) then return end
  return registered_elements[elType].class(name)
end

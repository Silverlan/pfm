include("udm_base.lua")

util.register_class("udm.BaseAttribute",udm.BaseItem)

udm.impl = udm.impl or {}
udm.impl.registered_attributes = udm.impl.registered_attributes or {}
udm.impl.class_to_attribute_id = udm.impl.class_to_attribute_id or {}
local registered_attributes = udm.impl.registered_attributes
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

-- These should be overwritten by derived classes
function udm.BaseAttribute:WriteToBinary(ds) end
function udm.BaseAttribute:ReadFromBinary(ds) end

function udm.BaseAttribute:ToASCIIString() end
function udm.BaseAttribute:LoadFromASCIIString(str) end
--

function udm.register_attribute(className,defaultValue)
  util.register_class("udm." .. className,udm.BaseAttribute)
  local class = udm[className]
  if(udm.impl.class_to_attribute_id[class] ~= nil) then return udm.impl.class_to_attribute_id[class] end
  function class:__init(value)
    udm.BaseAttribute.__init(self,class,value or defaultValue)
  end

  function class:__tostring()
    return self:GetStringValue()
  end
  
  local typeId = #registered_attributes +1
  function class:GetType()
    return typeId
  end
  
  registered_attributes[typeId] = {
    class = class,
    typeName = className
  }
  udm.impl.class_to_attribute_id[class] = typeId
  return typeId
end

function udm.get_type_name(typeId)
  if(registered_attributes[typeId] == nil) then return end
  return registered_attributes[typeId].typeName
end

function udm.create_attribute(attrType,value)
  if(registered_attributes[attrType] == nil) then return end
  return registered_attributes[attrType].class(value)
end

function udm.create_attribute_array(attrType)
  if(registered_attributes[attrType] == nil) then return end
  local array = udm.create_attribute(udm.ATTRIBUTE_TYPE_ARRAY)
  array:SetElementType(attrType)
  return array
end

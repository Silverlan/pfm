util.register_class("udm.BaseElement")

local registered_elements = {}
function udm.BaseElement:__init(class,name)
  self:SetName(name or "")
  self.m_class = class
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then
    console.print_warning("Unregistered element type!")
    return
  end
  for _,prop in ipairs(elData.properties) do
    self["m_" .. prop.identifier] = prop.defaultValue:Copy()
  end
end

function udm.BaseElement:SetName(name) self.m_name = name end
function udm.BaseElement:GetName() return self.m_name end

function udm.BaseElement:GetType() return -1 end

function udm.BaseElement:Copy()
  local copy = self.m_class(self:GetName())
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then return copy end
  for _,prop in ipairs(elData.properties) do
    prop.setter(copy,prop.getter(self):Copy())
  end
  return copy
end

function udm.BaseElement:SaveToBinary(ds)
  ds:WriteString(self:GetName())
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then return end
  for _,prop in ipairs(elData.properties) do
    prop.getter(self):SaveToBinary(ds)
  end
end
function udm.BaseElement:LoadFromBinary(ds)
  self:SetName(ds:ReadString())
  
  local type = self:GetType()
  local elData = registered_elements[type]
  if(elData == nil) then return end
  for _,prop in ipairs(elData.properties) do
    prop.getter(self):LoadFromBinary(ds)
  end
end

function udm.register_element(className)
  util.register_class("udm." .. className,udm.BaseElement)
  local class = udm[className]
  function class:__init(name)
    udm.BaseElement.__init(self,class,name)
  end
  
  local typeId = #registered_elements +1
  function class:GetType()
    return typeId
  end
  
  registered_elements[typeId] = {
    class = class,
    properties = {}
  }
  return #registered_elements
end

function udm.register_element_property(elType,propIdentifier,defaultValue)
  local elData = registered_elements[elType]
  local methodIdentifier = propIdentifier:sub(1,1):upper() .. propIdentifier:sub(2)
  elData.class["Get" .. methodIdentifier] = function(self) return self["m_" .. propIdentifier] end
  elData.class["Set" .. methodIdentifier] = function(self,value) self["m_" .. propIdentifier] = value end
  table.insert(elData.properties,{
    identifier = propIdentifier,
    getter = elData.class["Get" .. methodIdentifier],
    setter = elData.class["Set" .. methodIdentifier],
    defaultValue = defaultValue
  })
end

function udm.create_element(elType,name)
  if(registered_elements[elType] == nil) then return end
  return registered_elements[elType].class(name)
end

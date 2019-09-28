include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_ARRAY = udm.register_attribute("Array",udm.ATTRIBUTE_TYPE_STRING)
function udm.Array:__init(elementType,defaultValue)
  udm.BaseAttribute.__init(self,udm.Array,defaultValue or {})
  self:SetElementType(elementType)
end
function udm.Array:Copy()
  local t = self:GetValue()
  local tCopy = {}
  for _,v in ipairs(t) do
    table.insert(tCopy,v)
  end
  return self.m_class(self:GetElementType(),tCopy)
end
function udm.Array:SetElementType(type) self.m_elementType = type end
function udm.Array:GetElementType() return self.m_elementType end

function udm.Array:WriteToBinary(ds)
  local array = self:GetValue()
  ds:WriteUInt32(#array)
  for _,v in ipairs(array) do
    v:WriteToBinary(ds)
  end
end

function udm.Array:ReadFromBinary(ds)
  local array = {}
  local numElements = ds:ReadUInt32()
  for i=1,numElements do
    local el = udm.create_attribute(self:GetType())
    el:ReadFromBinary(ds)
    table.insert(array,el)
  end
  return array
end

function udm.Array:Insert(pos,attr)
  if(self:GetElementType() == nil) then self:SetElementType(attr:GetType()) end
  if(attr:GetType() ~= self:GetElementType()) then
    console.print_warning(
      "Attempted to push attribute of type " .. (udm.get_type_name(attr:GetType()) or "") .. " into array of type " .. (udm.get_type_name(self:GetElementType()) or "") .. "!"
    )
    return
  end
  table.insert(self:GetValue(),pos,attr)
end

function udm.Array:PushFront(attr)
  self:Insert(1,attr)
end

function udm.Array:PushBack(attr)
  self:Insert(#self:GetValue() +1,attr)
end

function udm.Array:PopBack()
  return table.remove(self:GetValue(),#self:GetValue())
end

function udm.Array:PopFront()
  return table.remove(self:GetValue(),1)
end

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_BINARY = udm.register_attribute("Binary",util.DataStream())
function udm.Binary:WriteToBinary(ds) ds:WriteBinary(ds) end
function udm.Binary:ReadFromBinary(ds) return ds:ReadBinary() end
function udm.Binary:Copy()
  return self.m_class(self:GetValue():Copy())
end

function udm.Binary:ToASCIIString()
  return self:GetValue():ToBinaryString()
end
function udm.Binary:LoadFromASCIIString(str)
  local v = self:GetValue()
  v:Clear()
  v:WriteBinaryString(str)
end

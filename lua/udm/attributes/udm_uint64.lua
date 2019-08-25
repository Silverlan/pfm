include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_UINT64 = udm.register_attribute("UInt64",0)
function udm.UInt64:WriteToBinary(ds) ds:WriteUInt64(self:GetValue()) end
function udm.UInt64:ReadFromBinary(ds) return ds:ReadUInt64() end

function udm.UInt64:ToASCIIString() return tostring(self:GetValue()) end
function udm.UInt64:LoadFromASCIIString(str) self:SetValue(toint(str)) end

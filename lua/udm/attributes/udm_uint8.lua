include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_UINT8 = udm.register_attribute("UInt8",0)
function udm.UInt8:WriteToBinary(ds) ds:WriteUInt8(self:GetValue()) end
function udm.UInt8:ReadFromBinary(ds) return ds:ReadUInt8() end

function udm.UInt8:ToASCIIString() return tostring(self:GetValue()) end
function udm.UInt8:LoadFromASCIIString(str) self:SetValue(toint(str)) end

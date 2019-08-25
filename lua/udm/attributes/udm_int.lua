include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_INT = udm.register_attribute("Int",0)
function udm.Int:WriteToBinary(ds) ds:WriteInt32(self:GetValue()) end
function udm.Int:ReadFromBinary(ds) return ds:ReadInt32() end

function udm.Int:ToASCIIString() return tostring(self:GetValue()) end
function udm.Int:LoadFromASCIIString(str) self:SetValue(toint(str)) end

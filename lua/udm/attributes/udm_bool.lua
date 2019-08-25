include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_BOOL = udm.register_attribute("Bool",false)
function udm.Bool:WriteToBinary(ds) ds:WriteBool(self:GetValue()) end
function udm.Bool:ReadFromBinary(ds) return ds:ReadBool() end

function udm.Bool:ToASCIIString() return self:GetValue() and "1" or "0" end
function udm.Bool:LoadFromASCIIString(str) self:SetValue(toboolean(str)) end

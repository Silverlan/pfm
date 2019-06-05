include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_STRING = udm.register_attribute("String","")
function udm.String:WriteToBinary(ds) ds:WriteString(self:GetValue()) end
function udm.String:ReadFromBinary(ds) return ds:ReadString() end

function udm.String:ToASCIIString() return self:GetValue() end
function udm.String:LoadFromASCIIString(str) self:SetValue(str) end

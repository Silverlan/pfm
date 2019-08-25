include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_FLOAT = udm.register_attribute("Float",0.0)
function udm.Float:WriteToBinary(ds) ds:WriteFloat(self:GetValue()) end
function udm.Float:ReadFromBinary(ds) return ds:ReadFloat() end

function udm.Float:ToASCIIString() return tostring(self:GetValue()) end
function udm.Float:LoadFromASCIIString(str) self:SetValue(tonumber(str)) end

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_TIME = udm.register_attribute("Time",0.0)
function udm.Time:WriteToBinary(ds) ds:WriteFloat(self:GetValue()) end
function udm.Time:ReadFromBinary(ds) return ds:ReadFloat() end

function udm.Time:ToASCIIString() return tostring(self:GetValue()) end
function udm.Time:LoadFromASCIIString(str) self:SetValue(tonumber(str)) end

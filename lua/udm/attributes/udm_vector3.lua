include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_VECTOR3 = udm.register_attribute("Vector3",Vector())
function udm.Vector3:WriteToBinary(ds) ds:WriteVector(self:GetValue()) end
function udm.Vector3:ReadFromBinary(ds) return ds:ReadVector() end

function udm.Vector3:ToASCIIString()
  local v = self:GetValue()
  return v.x .. " " .. v.y .. " " .. v.z
end
function udm.Vector3:LoadFromASCIIString(str)
  local v = string.split(str," ")
  self:SetValue(Vector(tonumber(v[1]),tonumber(v[2]),tonumber(v[3])))
end

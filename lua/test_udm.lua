include("udm/udm.lua")

local v = udm.create_element(udm.ELEMENT_TYPE_TRANSFORM)
v:SetPosition(Vector(10,20,30))
print(v:GetPosition())
--print(v.m_value)
--print(v:GetStringValue())

-- lua_exec_cl test_udm.lua

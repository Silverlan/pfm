--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ATTRIBUTE_TYPE_QUATERNION = udm.register_attribute("Quaternion",Quaternion())
function udm.Quaternion:WriteToBinary(ds)
	ds:WriteQuaternion(self:GetValue())
end
function udm.Quaternion:ReadFromBinary(ds)
	self:SetValue(ds:ReadQuaternion())
end
function udm.Quaternion:Copy()
	return self.m_class(self:GetValue():Copy())
end

function udm.Quaternion:ToASCIIString()
	local v = self:GetValue()
	return tostring(v.x) .. " " .. tostring(v.y) .. " " .. tostring(v.z) .. " " .. tostring(v.w)
end
function udm.Quaternion:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue(Quaternion(tonumber(v[4]),tonumber(v[1]),tonumber(v[2]),tonumber(v[3])))
end

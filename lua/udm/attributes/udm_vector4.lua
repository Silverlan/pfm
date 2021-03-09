--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_VECTOR4 = fudm.register_attribute("Vector4",Vector4())
function fudm.Vector4:WriteToBinary(ds) ds:WriteVector4(self:GetValue()) end
function fudm.Vector4:ReadFromBinary(ds) return ds:ReadVector4() end
function fudm.Vector4:Copy()
	return self.m_class(self:GetValue():Copy())
end
function fudm.Vector4:ToASCIIString()
	local v = self:GetValue()
	return v.x .. " " .. v.y .. " " .. v.z .. " " .. v.w
end
function fudm.Vector4:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue(Vector4(tonumber(v[1]),tonumber(v[2]),tonumber(v[3]),tonumber(v[4])))
end

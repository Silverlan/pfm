--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_VECTOR2 = fudm.register_attribute("Vector2",Vector2())
function fudm.Vector2:WriteToBinary(ds) ds:WriteVector2(self:GetValue()) end
function fudm.Vector2:ReadFromBinary(ds) return ds:ReadVector2() end
function fudm.Vector2:Copy()
	return self.m_class(self:GetValue():Copy())
end
function fudm.Vector2:ToASCIIString()
	local v = self:GetValue()
	return v.x .. " " .. v.y
end
function fudm.Vector2:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue(Vector2(tonumber(v[1]),tonumber(v[2])))
end

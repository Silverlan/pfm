--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_ANGLE = fudm.register_attribute("Angle",EulerAngles())
function fudm.Angle:WriteToBinary(ds) ds:WriteAngles(self:GetValue()) end
function fudm.Angle:ReadFromBinary(ds) return ds:ReadAngles() end
function fudm.Angle:Copy()
	return self.m_class(self:GetValue():Copy())
end

function fudm.Angle:ToASCIIString()
	local v = self:GetValue()
	return tostring(v.p) .. " " .. tostring(v.y) .. " " .. tostring(v.r)
end
function fudm.Angle:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue(EulerAngles(tonumber(v[1]),tonumber(v[2]),tonumber(v[3])))
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_MATRIX = fudm.register_attribute("Matrix",Mat4(1.0))
function fudm.Matrix:WriteToBinary(ds) ds:WriteMat4(self:GetValue()) end
function fudm.Matrix:ReadFromBinary(ds) return ds:ReadMat4() end
function fudm.Matrix:Copy()
	return self.m_class(self:GetValue():Copy())
end

function fudm.Matrix:ToASCIIString()
	local v = self:GetValue()
	return tostring(v:Get(0,0)) .. " " .. tostring(v:Get(0,1)) .. " " .. tostring(v:Get(0,2)) .. " " .. tostring(v:Get(0,3)) .. " " ..
		tostring(v:Get(1,0)) .. " " .. tostring(v:Get(1,1)) .. " " .. tostring(v:Get(1,2)) .. " " .. tostring(v:Get(1,3)) .. " " ..
		tostring(v:Get(2,0)) .. " " .. tostring(v:Get(2,1)) .. " " .. tostring(v:Get(2,2)) .. " " .. tostring(v:Get(2,3)) .. " " ..
		tostring(v:Get(3,0)) .. " " .. tostring(v:Get(3,1)) .. " " .. tostring(v:Get(3,2)) .. " " .. tostring(v:Get(3,3))
end
function fudm.Matrix:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue(Mat4(
		tonumber(v[1]),tonumber(v[2]),tonumber(v[3]),tonumber(v[4]),
		tonumber(v[5]),tonumber(v[6]),tonumber(v[7]),tonumber(v[8]),
		tonumber(v[9]),tonumber(v[10]),tonumber(v[11]),tonumber(v[12]),
		tonumber(v[13]),tonumber(v[14]),tonumber(v[15]),tonumber(v[16])
	))
end

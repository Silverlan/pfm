--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_COLOR = fudm.register_attribute("Color",Color.White)
function fudm.Color:WriteToBinary(ds) ds:WriteColor(self:GetValue()) end
function fudm.Color:ReadFromBinary(ds) return ds:ReadColor() end
function fudm.Color:Copy()
	return self.m_class(self:GetValue():Copy())
end

function fudm.Color:ToASCIIString()
	local v = self:GetValue()
	return tostring(v[1]) .. " " .. tostring(v[2]) .. " " .. tostring(v[3]) .. " " .. tostring(v[4])
end
function fudm.Color:LoadFromASCIIString(str)
	local v = string.split(str," ")
	self:SetValue({toint(v[1]),toint(v[2]),toint(v[3]),toint(v[4])})
end

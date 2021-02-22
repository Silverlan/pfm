--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_BINARY = fudm.register_attribute("Binary",util.DataStream())
function fudm.Binary:WriteToBinary(ds) ds:WriteBinary(ds) end
function fudm.Binary:ReadFromBinary(ds) return ds:ReadBinary() end
function fudm.Binary:Copy()
	return self.m_class(self:GetValue():Copy())
end

function fudm.Binary:ToASCIIString()
	return self:GetValue():ToBinaryString()
end
function fudm.Binary:LoadFromASCIIString(str)
	local v = self:GetValue()
	v:Clear()
	v:WriteBinaryString(str)
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_UINT64 = fudm.register_attribute("UInt64",0)
function fudm.UInt64:WriteToBinary(ds) ds:WriteUInt64(self:GetValue()) end
function fudm.UInt64:ReadFromBinary(ds) return ds:ReadUInt64() end

function fudm.UInt64:ToASCIIString() return tostring(self:GetValue()) end
function fudm.UInt64:LoadFromASCIIString(str) self:SetValue(toint(str)) end

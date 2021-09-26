--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_UINT32 = fudm.register_attribute("UInt32",0)
function fudm.UInt32:WriteToBinary(ds) ds:WriteUInt32(self:GetValue()) end
function fudm.UInt32:ReadFromBinary(ds) return ds:ReadUInt32() end

function fudm.UInt32:ToASCIIString() return tostring(self:GetValue()) end
function fudm.UInt32:LoadFromASCIIString(str) self:SetValue(toint(str)) end

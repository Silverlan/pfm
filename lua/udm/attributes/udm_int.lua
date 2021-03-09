--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_INT = fudm.register_attribute("Int",0)
function fudm.Int:WriteToBinary(ds) ds:WriteInt32(self:GetValue()) end
function fudm.Int:ReadFromBinary(ds) return ds:ReadInt32() end

function fudm.Int:ToASCIIString() return tostring(self:GetValue()) end
function fudm.Int:LoadFromASCIIString(str) self:SetValue(toint(str)) end

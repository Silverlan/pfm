--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_BOOL = fudm.register_attribute("Bool",false)
function fudm.Bool:WriteToBinary(ds) ds:WriteBool(self:GetValue()) end
function fudm.Bool:ReadFromBinary(ds) return ds:ReadBool() end

function fudm.Bool:ToASCIIString() return self:GetValue() and "1" or "0" end
function fudm.Bool:LoadFromASCIIString(str) self:SetValue(toboolean(str)) end

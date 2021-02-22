--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_FLOAT = fudm.register_attribute("Float",0.0)
function fudm.Float:WriteToBinary(ds) ds:WriteFloat(self:GetValue()) end
function fudm.Float:ReadFromBinary(ds) return ds:ReadFloat() end

function fudm.Float:ToASCIIString() return tostring(self:GetValue()) end
function fudm.Float:LoadFromASCIIString(str) self:SetValue(tonumber(str)) end

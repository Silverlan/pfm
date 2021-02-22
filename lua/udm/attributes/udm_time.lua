--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_TIME = fudm.register_attribute("Time",0.0)
function fudm.Time:WriteToBinary(ds) ds:WriteFloat(self:GetValue()) end
function fudm.Time:ReadFromBinary(ds) return ds:ReadFloat() end

function fudm.Time:ToASCIIString() return tostring(self:GetValue()) end
function fudm.Time:LoadFromASCIIString(str) self:SetValue(tonumber(str)) end

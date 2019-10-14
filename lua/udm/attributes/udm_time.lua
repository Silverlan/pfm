--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ATTRIBUTE_TYPE_TIME = udm.register_attribute("Time",0.0)
function udm.Time:WriteToBinary(ds) ds:WriteFloat(self:GetValue()) end
function udm.Time:ReadFromBinary(ds) return ds:ReadFloat() end

function udm.Time:ToASCIIString() return tostring(self:GetValue()) end
function udm.Time:LoadFromASCIIString(str) self:SetValue(tonumber(str)) end

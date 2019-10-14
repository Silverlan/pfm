--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ATTRIBUTE_TYPE_INT = udm.register_attribute("Int",0)
function udm.Int:WriteToBinary(ds) ds:WriteInt32(self:GetValue()) end
function udm.Int:ReadFromBinary(ds) return ds:ReadInt32() end

function udm.Int:ToASCIIString() return tostring(self:GetValue()) end
function udm.Int:LoadFromASCIIString(str) self:SetValue(toint(str)) end

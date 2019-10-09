--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_UINT64 = udm.register_attribute("UInt64",0)
function udm.UInt64:WriteToBinary(ds) ds:WriteUInt64(self:GetValue()) end
function udm.UInt64:ReadFromBinary(ds) return ds:ReadUInt64() end

function udm.UInt64:ToASCIIString() return tostring(self:GetValue()) end
function udm.UInt64:LoadFromASCIIString(str) self:SetValue(toint(str)) end

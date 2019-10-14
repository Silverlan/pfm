--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ATTRIBUTE_TYPE_UINT8 = udm.register_attribute("UInt8",0)
function udm.UInt8:WriteToBinary(ds) ds:WriteUInt8(self:GetValue()) end
function udm.UInt8:ReadFromBinary(ds) return ds:ReadUInt8() end

function udm.UInt8:ToASCIIString() return tostring(self:GetValue()) end
function udm.UInt8:LoadFromASCIIString(str) self:SetValue(toint(str)) end

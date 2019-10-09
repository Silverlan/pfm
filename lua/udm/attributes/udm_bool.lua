--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_BOOL = udm.register_attribute("Bool",false)
function udm.Bool:WriteToBinary(ds) ds:WriteBool(self:GetValue()) end
function udm.Bool:ReadFromBinary(ds) return ds:ReadBool() end

function udm.Bool:ToASCIIString() return self:GetValue() and "1" or "0" end
function udm.Bool:LoadFromASCIIString(str) self:SetValue(toboolean(str)) end

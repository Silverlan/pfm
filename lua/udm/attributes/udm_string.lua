--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_attribute.lua")

udm.ATTRIBUTE_TYPE_STRING = udm.register_attribute("String","")
function udm.String:WriteToBinary(ds) ds:WriteString(self:GetValue()) end
function udm.String:ReadFromBinary(ds) return ds:ReadString() end

function udm.String:ToASCIIString() return self:GetValue() end
function udm.String:LoadFromASCIIString(str) self:SetValue(str) end

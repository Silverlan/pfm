--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_STRING = fudm.register_attribute("String","")
function fudm.String:WriteToBinary(ds) ds:WriteString(self:GetValue()) end
function fudm.String:ReadFromBinary(ds) return ds:ReadString() end

function fudm.String:ToASCIIString() return self:GetValue() end
function fudm.String:LoadFromASCIIString(str) self:SetValue(str) end

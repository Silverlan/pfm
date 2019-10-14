--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ATTRIBUTE_TYPE_NIL = udm.register_attribute("Nil",nil)
function udm.Nil:WriteToBinary(ds) end
function udm.Nil:ReadFromBinary(ds) return nil end
function udm.Nil:Copy()
  return self.m_class(self:GetValue():Copy())
end
function udm.Nil:ToASCIIString()
  return "nil"
end
function udm.Nil:LoadFromASCIIString(str) end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ATTRIBUTE_TYPE_NIL = fudm.register_attribute("Nil",nil)
function fudm.Nil:WriteToBinary(ds) end
function fudm.Nil:ReadFromBinary(ds) return nil end
function fudm.Nil:Copy()
	return self.m_class(nil)
end
function fudm.Nil:ToASCIIString()
	return "nil"
end
function fudm.Nil:LoadFromASCIIString(str) end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_base.lua")
include("udm_listener.lua")

util.register_class("fudm.BaseAttribute",fudm.BaseItem,fudm.Listener)
function fudm.BaseAttribute:__init(class,value)
	fudm.BaseItem.__init(self)
	fudm.Listener.__init(self)
	self.m_class = class
	self:SetValue(value)
end

function fudm.BaseAttribute:__finalize()
end

function fudm.BaseAttribute:__tostring()
	return self:GetStringValue()
end

function fudm.BaseAttribute:DebugPrint(t,name)
	t = t or ""
	console.print_message(t)
	if(name) then console.print_message("[" .. name .. "] = ") end
	console.print_messageln(tostring(self))
end

function fudm.BaseAttribute:DebugDump(f,t,name)
	t = t or ""
	f:WriteString(t)
	if(name) then f:WriteString("[" .. name .. "] = ") end
	f:WriteString(tostring(self) .. "\n")
end

function fudm.BaseAttribute:SetValue(value)
	local oldValue = self.m_value
	if(value ~= nil and util.get_type_name(value) ~= "Nil" and oldValue ~= nil and util.get_type_name(oldValue) ~= "Nil") then
		--if(value == oldValue) then return end
		if(util.get_type_name(value) ~= util.get_type_name(oldValue)) then
			error("Type mismatch detected when attempting to change attribute value for attribute '" .. tostring(self) .. "', with current type '" .. util.get_type_name(oldValue) .. "' and new value type '" .. util.get_type_name(value) .. "'!")
		end
	end
	self.m_value = value

	self:InvokeChangeListeners()
end
function fudm.BaseAttribute:GetValue() return self.m_value end
function fudm.BaseAttribute:GetStringValue() return self:ToASCIIString() end

function fudm.BaseAttribute:LoadFromBinary(ds) self:SetValue(self:ReadFromBinary(ds)) end

function fudm.BaseAttribute:Copy()
	return self.m_class(self:GetValue())
end

function fudm.BaseAttribute:IsArray()
	return self:GetType() == fudm.ELEMENT_TYPE_ARRAY
end

function fudm.BaseAttribute:IsElement() return false end
function fudm.BaseAttribute:IsAttribute() return true end

function fudm.BaseAttribute:ToASCIIString() end
function fudm.BaseAttribute:LoadFromASCIIString(str) end
--

function fudm.create_attribute(type,value)
	return fudm.create(type,value,false)
end

function fudm.create_attribute_array(attrType)
	local array = fudm.create_attribute(fudm.ELEMENT_TYPE_ARRAY)
	array:SetElementType(attrType)
	return array
end

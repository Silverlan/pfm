--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_base.lua")
include("udm_listener.lua")

util.register_class("udm.BaseAttribute",udm.BaseItem,udm.Listener)
function udm.BaseAttribute:__init(class,value)
	udm.BaseItem.__init(self)
	udm.Listener.__init(self)
	self.m_class = class
	self:SetValue(value)
end

function udm.BaseAttribute:__finalize()
	print("Attribute removed!")
end

function udm.BaseAttribute:__tostring()
	return self:GetStringValue()
end

function udm.BaseAttribute:DebugPrint(t,name)
	t = t or ""
	console.print_message(t)
	if(name) then console.print_message("[" .. name .. "] = ") end
	console.print_messageln(tostring(self))
end

function udm.BaseAttribute:DebugDump(f,t,name)
	t = t or ""
	f:WriteString(t)
	if(name) then f:WriteString("[" .. name .. "] = ") end
	f:WriteString(tostring(self) .. "\n")
end

function udm.BaseAttribute:SetValue(value)
	local oldValue = self.m_value
	if(value ~= nil and util.get_type_name(value) ~= "Nil" and oldValue ~= nil and util.get_type_name(oldValue) ~= "Nil") then
		if(value == oldValue) then return end
	end
	self.m_value = value

	self:InvokeChangeListeners()
end
function udm.BaseAttribute:GetValue() return self.m_value end
function udm.BaseAttribute:GetStringValue() return self:ToASCIIString() end

function udm.BaseAttribute:SaveToBinary(ds)
	self:WriteToBinary(ds)
end
function udm.BaseAttribute:LoadFromBinary(ds)
	self:SetValue(self:ReadFromBinary(ds))
end
function udm.BaseAttribute:Copy()
	return self.m_class(self:GetValue())
end

function udm.BaseAttribute:IsArray()
	return self:GetType() == udm.ELEMENT_TYPE_ARRAY
end

function udm.BaseAttribute:IsElement() return false end
function udm.BaseAttribute:IsAttribute() return true end

-- These should be overwritten by derived classes
function udm.BaseAttribute:WriteToBinary(ds) end
function udm.BaseAttribute:ReadFromBinary(ds) end

function udm.BaseAttribute:ToASCIIString() end
function udm.BaseAttribute:LoadFromASCIIString(str) end
--

function udm.create_attribute(type,value)
	return udm.create(type,value,false)
end

function udm.create_attribute_array(attrType)
	local array = udm.create_attribute(udm.ELEMENT_TYPE_ARRAY)
	array:SetElementType(attrType)
	return array
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../udm_listener.lua")

udm.ELEMENT_TYPE_ARRAY = udm.register_type("Array",{udm.BaseElement,udm.Listener},true)
function udm.Array:Initialize(elementType)
	udm.BaseElement.Initialize(self)
	self.m_array = {}
	self:SetElementType(elementType)
end

function udm.Array:__len() return #self.m_array end

function udm.Array:Copy()
	local copy = self.m_class(self:GetElementType())
	for _,v in ipairs(self:GetTable()) do
		copy:PushBack(v)
	end
	return copy
end
function udm.Array:SetElementType(type) self.m_elementType = type end
function udm.Array:GetElementType() return self.m_elementType end

function udm.Array:GetValue() return self.m_array end
function udm.Array:GetTable() return self.m_array end

function udm.Array:WriteToBinary(ds)
	local array = self:GetValue()
	ds:WriteUInt32(#array)
	for _,v in ipairs(array) do
		v:WriteToBinary(ds)
	end
end

function udm.Array:ReadFromBinary(ds)
	local array = {}
	local numElements = ds:ReadUInt32()
	for i=1,numElements do
		local el = udm.create_attribute(self:GetType()) -- TODO: Can also be an element?
		el:ReadFromBinary(ds)
		table.insert(array,el)
	end
	return array
end

function udm.Array:Get(i) return self:GetTable()[i] end

function udm.Array:FindByName(name)
	for _,child in ipairs(self:GetTable()) do
		if(child:GetName() == name) then
			return child
		end
	end
end

function udm.Array:Insert(pos,attr)
	local attrType = attr:GetType()
	if(attrType == udm.ELEMENT_TYPE_REFERENCE) then
		attrType = attr:GetTarget():GetType()
	end
	if(self:GetElementType() == nil) then self:SetElementType(attrType) end
	local t = self:GetElementType()
	if(t ~= udm.ELEMENT_TYPE_ANY and t ~= udm.ATTRIBUTE_TYPE_ANY and attrType ~= t) then
		pfm.error("Attempted to push attribute of type " .. (udm.get_type_name(attrType) or "") .. " into array of type " .. (udm.get_type_name(t) or "") .. "!")
		return
	end
	table.insert(self:GetValue(),pos,attr)
	self:AddChild(attr,"[" .. tostring(#self -1) .. "]")
	self:InvokeChangeListeners(attr,pos)
end

function udm.Array:PushFront(attr)
	self:Insert(1,attr)
end

function udm.Array:PushBack(attr)
	self:Insert(#self +1,attr)
end

function udm.Array:PopBack()
	return table.remove(self:GetValue(),#self)
end

function udm.Array:PopFront()
	-- TODO: Update name in parent(s)
	return table.remove(self:GetValue(),1)
end

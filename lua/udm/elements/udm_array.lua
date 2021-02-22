--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../udm_listener.lua")

fudm.ELEMENT_TYPE_ARRAY = fudm.register_type("Array",{fudm.BaseElement,fudm.Listener},true)
function fudm.Array:Initialize(elementType)
	fudm.BaseElement.Initialize(self)
	self:SetElementType(elementType)
end

function fudm.Array:__len() return #self:GetValue() end

function fudm.Array:Copy()
	local copy = self.m_class(self:GetElementType())
	for _,v in ipairs(self:GetTable()) do
		copy:PushBack(v)
	end
	return copy
end
function fudm.Array:SetElementType(type) self.m_elementType = type end
function fudm.Array:GetElementType() return self.m_elementType end

function fudm.Array:GetValue() return self:GetChildren() end
function fudm.Array:GetTable() return self:GetValue() end

function fudm.Array:WriteToBinary(ds)
	ds:WriteUInt32(self:GetElementType() or math.MAX_UINT32)
end

function fudm.Array:ReadFromBinary(ds)
	local elType = ds:ReadUInt32()
	self:SetElementType((elType ~= math.MAX_UINT32) and elType or nil)
end

function fudm.Array:Get(i) return self:GetTable()[i] end

function fudm.Array:FindByName(name)
	for _,child in ipairs(self:GetTable()) do
		if(child:GetName() == name) then
			return child
		end
	end
end

function fudm.Array:AddChild(element,name)
	if(string.is_integer(name)) then name = tonumber(name) end -- Name will be used as array index
	return fudm.BaseElement.AddChild(self,element,name)
end

function fudm.Array:Insert(pos,attr)
	local attrType = attr:GetType()
	if(attrType == fudm.ELEMENT_TYPE_REFERENCE) then
		local target = attr:GetTarget()
		if(target == nil) then return end
		attrType = target:GetType()
	end
	if(self:GetElementType() == nil) then self:SetElementType(attrType) end
	local t = self:GetElementType()
	if(t ~= fudm.ELEMENT_TYPE_ANY and t ~= fudm.ATTRIBUTE_TYPE_ANY and attrType ~= t) then
		pfm.error("Attempted to push attribute " .. tostring(attr) .. " of type " .. (fudm.get_type_name(attrType) or "") .. " into array " .. tostring(self) .. " of type " .. (fudm.get_type_name(t) or "") .. " (" .. t .. ")!")
		return
	end
	table.insert(self:GetValue(),pos,attr)
	table.insert(attr.m_parents,self)
	-- self:AddChild(attr,"[" .. tostring(#self -1) .. "]")
	self:InvokeChangeListeners(attr,pos)
end

function fudm.Array:Clear()
	local t = self:GetTable()
	for i=1,#t do
		t[i] = nil
	end
end

function fudm.Array:PushFront(attr)
	self:Insert(1,attr)
end

function fudm.Array:PushBack(attr)
	self:Insert(#self +1,attr)
end

function fudm.Array:Remove(pos)
	local el = table.remove(self:GetValue(),pos)
	if(el == nil) then return end
	for i,p in ipairs(el.m_parents) do
		if(util.is_same_object(p,self)) then
			table.remove(el.m_parents,i)
			break
		end
	end
end

function fudm.Array:PopBack()
	return self:Remove(#self)
end

function fudm.Array:PopFront()
	return self:Remove(1)
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../udm_listener.lua")

fudm.ELEMENT_TYPE_VALUE_ARRAY = fudm.register_type("ValueArray",{fudm.BaseElement,fudm.Listener},true)
function fudm.ValueArray:Initialize(valType)
	fudm.BaseElement.Initialize(self)
	self:SetValueType(valType)
end

function fudm.ValueArray:__len() return (self.m_array ~= nil) and #self.m_array or 0 end

function fudm.ValueArray:Copy()
	local copy = self.m_class(self:GetValueType())
	if(#self == 0) then return copy end
	copy:InitializeArray(self:GetValueType())
	copy:GetValue():Reserve(#self)
	for i=1,#self do
		copy:PushBack(self:Get(i))
	end
	return copy
end

local supportedTypes = {
	[util.VAR_TYPE_BOOL] = true,
	[util.VAR_TYPE_DOUBLE] = true,
	[util.VAR_TYPE_FLOAT] = true,
	[util.VAR_TYPE_INT8] = true,
	[util.VAR_TYPE_INT16] = true,
	[util.VAR_TYPE_INT32] = true,
	[util.VAR_TYPE_INT64] = true,
	[util.VAR_TYPE_LONG_DOUBLE] = true,
	[util.VAR_TYPE_STRING] = true,
	[util.VAR_TYPE_UINT8] = true,
	[util.VAR_TYPE_UINT16] = true,
	[util.VAR_TYPE_UINT32] = true,
	[util.VAR_TYPE_UINT64] = true,
	[util.VAR_TYPE_EULER_ANGLES] = true,
	[util.VAR_TYPE_COLOR] = true,
	[util.VAR_TYPE_VECTOR] = true,
	[util.VAR_TYPE_VECTOR2] = true,
	[util.VAR_TYPE_VECTOR4] = true,
	[util.VAR_TYPE_QUATERNION] = true
}
function fudm.ValueArray:SetValueType(type)
	self.m_array = nil
	self:InitializeArray(type)
	if(type ~= nil and supportedTypes[type] ~= true) then
		error("Attempted to use type " .. type .. " as type for value array, which is not supported!")
	end
	self.m_valueType = type
end
function fudm.ValueArray:GetValueType() return self.m_valueType end

function fudm.ValueArray:InitializeArray(type)
	if(self.m_array ~= nil) then return end
	type = type or self:GetValueType()
	if(type == util.VAR_TYPE_BOOL) then self.m_array = util.BoolVector()
	elseif(type == util.VAR_TYPE_DOUBLE) then self.m_array = util.DoubleVector()
	elseif(type == util.VAR_TYPE_FLOAT) then self.m_array = util.FloatVector()
	elseif(type == util.VAR_TYPE_INT8) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_INT16) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_INT32) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_INT64) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_LONG_DOUBLE) then self.m_array = util.LongDoubleVector()
	elseif(type == util.VAR_TYPE_STRING) then self.m_array = util.StringVector()
	elseif(type == util.VAR_TYPE_UINT8) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_UINT16) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_UINT32) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_UINT64) then self.m_array = util.IntVector()
	elseif(type == util.VAR_TYPE_EULER_ANGLES) then self.m_array = util.EulerAnglesVector()
	elseif(type == util.VAR_TYPE_COLOR) then self.m_array = util.ColorVector()
	elseif(type == util.VAR_TYPE_VECTOR) then self.m_array = util.Vector3Vector()
	elseif(type == util.VAR_TYPE_VECTOR2) then self.m_array = util.Vector2Vector()
	elseif(type == util.VAR_TYPE_VECTOR4) then self.m_array = util.Vector4Vector()
	elseif(type == util.VAR_TYPE_QUATERNION) then self.m_array = util.QuaternionVector() end
end

function fudm.ValueArray:GetValue() return self.m_array end
function fudm.ValueArray:GetTable() return self.m_array end

function fudm.ValueArray:WriteToBinary(ds)
	local array = self:GetValue()
	local numValues = (array ~= nil) and #array or 0
	local type = self:GetValueType()
	ds:WriteUInt32(type or math.MAX_UINT32)
	ds:WriteUInt32(numValues)
	for i=0,numValues -1 do
		local v = array:At(i)
		if(type == util.VAR_TYPE_BOOL) then ds:WriteBool(v)
		elseif(type == util.VAR_TYPE_DOUBLE) then ds:WriteDouble(v)
		elseif(type == util.VAR_TYPE_FLOAT) then ds:WriteFloat(v)
		elseif(type == util.VAR_TYPE_INT8) then ds:WriteInt8(v)
		elseif(type == util.VAR_TYPE_INT16) then ds:WriteInt16(v)
		elseif(type == util.VAR_TYPE_INT32) then ds:WriteInt32(v)
		elseif(type == util.VAR_TYPE_INT64) then ds:WriteInt64(v)
		elseif(type == util.VAR_TYPE_LONG_DOUBLE) then ds:WriteLongDouble(v)
		elseif(type == util.VAR_TYPE_STRING) then ds:WriteString(v)
		elseif(type == util.VAR_TYPE_UINT8) then ds:WriteUInt8(v)
		elseif(type == util.VAR_TYPE_UINT16) then ds:WriteUInt16(v)
		elseif(type == util.VAR_TYPE_UINT32) then ds:WriteUInt32(v)
		elseif(type == util.VAR_TYPE_UINT64) then ds:WriteUInt64(v)
		elseif(type == util.VAR_TYPE_EULER_ANGLES) then ds:WriteEulerAngles(v)
		elseif(type == util.VAR_TYPE_COLOR) then ds:WriteColor(v)
		elseif(type == util.VAR_TYPE_VECTOR) then ds:WriteVector(v)
		elseif(type == util.VAR_TYPE_VECTOR2) then ds:WriteVector2(v)
		elseif(type == util.VAR_TYPE_VECTOR4) then ds:WriteVector4(v)
		elseif(type == util.VAR_TYPE_QUATERNION) then ds:WriteQuaternion(v) end
	end
end

function fudm.ValueArray:ReadFromBinary(ds)
	local type = ds:ReadUInt32()
	self:SetValueType((type ~= math.MAX_UINT32) and type or nil)
	local numElements = ds:ReadUInt32()
	self:InitializeArray()
	local array = self:GetValue()
	if(numElements > 0) then
		array:Reserve(numElements)
		for i=1,numElements do
			local v
			if(type == util.VAR_TYPE_BOOL) then v = ds:ReadBool()
			elseif(type == util.VAR_TYPE_DOUBLE) then v = ds:ReadDouble()
			elseif(type == util.VAR_TYPE_FLOAT) then v = ds:ReadFloat()
			elseif(type == util.VAR_TYPE_INT8) then v = ds:ReadInt8()
			elseif(type == util.VAR_TYPE_INT16) then v = ds:ReadInt16()
			elseif(type == util.VAR_TYPE_INT32) then v = ds:ReadInt32()
			elseif(type == util.VAR_TYPE_INT64) then v = ds:ReadInt64()
			elseif(type == util.VAR_TYPE_LONG_DOUBLE) then v = ds:ReadLongDouble()
			elseif(type == util.VAR_TYPE_STRING) then v = ds:ReadString()
			elseif(type == util.VAR_TYPE_UINT8) then v = ds:ReadUInt8()
			elseif(type == util.VAR_TYPE_UINT16) then v = ds:ReadUInt16()
			elseif(type == util.VAR_TYPE_UINT32) then v = ds:ReadUInt32()
			elseif(type == util.VAR_TYPE_UINT64) then v = ds:ReadUInt64()
			elseif(type == util.VAR_TYPE_EULER_ANGLES) then v = ds:ReadEulerAngles()
			elseif(type == util.VAR_TYPE_COLOR) then v = ds:ReadColor()
			elseif(type == util.VAR_TYPE_VECTOR) then v = ds:ReadVector()
			elseif(type == util.VAR_TYPE_VECTOR2) then v = ds:ReadVector2()
			elseif(type == util.VAR_TYPE_VECTOR4) then v = ds:ReadVector4()
			elseif(type == util.VAR_TYPE_QUATERNION) then v = ds:ReadQuaternion() end
			array:PushBack(v)
		end
	end
	return array
end

function fudm.ValueArray:Get(i)
	i = i -1
	if(i < 0 or i >= #self) then return end
	return self:GetTable():At(i)
end
function fudm.ValueArray:Set(i,v) self:GetTable():Set(i -1,v) end

function fudm.ValueArray:Insert(pos,value)
	local t = self:GetValueType()
	if(t == nil) then
		local valueType = util.get_type_name(value)
		if(valueType == "boolean") then t = util.VAR_TYPE_BOOL
		elseif(valueType == "number") then t = util.VAR_TYPE_FLOAT
		elseif(valueType == "string") then t = util.VAR_TYPE_STRING
		elseif(valueType == "EulerAngles") then t = util.VAR_TYPE_EULER_ANGLES
		elseif(valueType == "Color") then t = util.VAR_TYPE_COLOR
		elseif(valueType == "Vector") then t = util.VAR_TYPE_VECTOR
		elseif(valueType == "Vector2") then t = util.VAR_TYPE_VECTOR2
		elseif(valueType == "Vector4") then t = util.VAR_TYPE_VECTOR4
		elseif(valueType == "QuaternionInternal") then t = util.VAR_TYPE_QUATERNION
		else error("Attempted to push value of type '" .. valueType .. "' into value array, which is not supported!") end
		self:SetValueType(t)
	end
	-- Note: It's the caller's responsibility to ensure that the value is of the right type!
	local vector = self:GetValue()
	if(vector:Size() == vector:Capacity()) then
		-- Reserve some space so we don't have to re-allocate constantly
		vector:Reserve(vector:Size() *1.2 +20)
	end
	vector:Insert(pos -1,value)
	self:InvokeChangeListeners(value,pos)
end

function fudm.ValueArray:PushFront(value)
	self:Insert(1,value)
end

function fudm.ValueArray:PushBack(value)
	self:Insert(#self +1,value)
end

function fudm.ValueArray:PopBack()
	local v = self:GetValue():At(#self -1)
	self:GetValue():Erase(#self -1)
	return v
end

function fudm.ValueArray:PopFront()
	local v = self:GetValue():At(0)
	self:GetValue():Erase(0)
	return v
end

function fudm.ValueArray:Clear()
	self.m_array:Clear()
end

-- Lua-table implementation (obsolete)
--[[
include("../udm_listener.lua")

fudm.ELEMENT_TYPE_VALUE_ARRAY = fudm.register_type("ValueArray",{fudm.BaseElement,fudm.Listener},true)
function fudm.ValueArray:Initialize(valType)
	fudm.BaseElement.Initialize(self)
	self.m_array = {}
	self:SetValueType(valType)
end

function fudm.ValueArray:__len() return #self.m_array end

function fudm.ValueArray:Copy()
	local copy = self.m_class(self:GetValueType())
	for _,v in ipairs(self:GetTable()) do
		copy:PushBack(v)
	end
	return copy
end

local supportedTypes = {
	[util.VAR_TYPE_BOOL] = true,
	[util.VAR_TYPE_DOUBLE] = true,
	[util.VAR_TYPE_FLOAT] = true,
	[util.VAR_TYPE_INT8] = true,
	[util.VAR_TYPE_INT16] = true,
	[util.VAR_TYPE_INT32] = true,
	[util.VAR_TYPE_INT64] = true,
	[util.VAR_TYPE_LONG_DOUBLE] = true,
	[util.VAR_TYPE_STRING] = true,
	[util.VAR_TYPE_UINT8] = true,
	[util.VAR_TYPE_UINT16] = true,
	[util.VAR_TYPE_UINT32] = true,
	[util.VAR_TYPE_UINT64] = true,
	[util.VAR_TYPE_EULER_ANGLES] = true,
	[util.VAR_TYPE_COLOR] = true,
	[util.VAR_TYPE_VECTOR] = true,
	[util.VAR_TYPE_VECTOR2] = true,
	[util.VAR_TYPE_VECTOR4] = true,
	[util.VAR_TYPE_QUATERNION] = true
}
function fudm.ValueArray:SetValueType(type)
	if(type ~= nil and supportedTypes[type] ~= true) then
		error("Attempted to use type " .. type .. " as type for value array, which is not supported!")
	end
	self.m_valueType = type
end
function fudm.ValueArray:GetValueType() return self.m_valueType end

function fudm.ValueArray:GetValue() return self.m_array end
function fudm.ValueArray:GetTable() return self.m_array end

function fudm.ValueArray:WriteToBinary(ds)
	local array = self:GetValue()
	local type = self:GetValueType()
	ds:WriteUInt32(type or math.MAX_UINT32)
	ds:WriteUInt32(#array)
	for _,v in ipairs(array) do
		if(type == util.VAR_TYPE_BOOL) then ds:WriteBool(v)
		elseif(type == util.VAR_TYPE_DOUBLE) then ds:WriteDouble(v)
		elseif(type == util.VAR_TYPE_FLOAT) then ds:WriteFloat(v)
		elseif(type == util.VAR_TYPE_INT8) then ds:WriteInt8(v)
		elseif(type == util.VAR_TYPE_INT16) then ds:WriteInt16(v)
		elseif(type == util.VAR_TYPE_INT32) then ds:WriteInt32(v)
		elseif(type == util.VAR_TYPE_INT64) then ds:WriteInt64(v)
		elseif(type == util.VAR_TYPE_LONG_DOUBLE) then ds:WriteLongDouble(v)
		elseif(type == util.VAR_TYPE_STRING) then ds:WriteString(v)
		elseif(type == util.VAR_TYPE_UINT8) then ds:WriteUInt8(v)
		elseif(type == util.VAR_TYPE_UINT16) then ds:WriteUInt16(v)
		elseif(type == util.VAR_TYPE_UINT32) then ds:WriteUInt32(v)
		elseif(type == util.VAR_TYPE_UINT64) then ds:WriteUInt64(v)
		elseif(type == util.VAR_TYPE_EULER_ANGLES) then ds:WriteEulerAngles(v)
		elseif(type == util.VAR_TYPE_COLOR) then ds:WriteColor(v)
		elseif(type == util.VAR_TYPE_VECTOR) then ds:WriteVector(v)
		elseif(type == util.VAR_TYPE_VECTOR2) then ds:WriteVector2(v)
		elseif(type == util.VAR_TYPE_VECTOR4) then ds:WriteVector4(v)
		elseif(type == util.VAR_TYPE_QUATERNION) then ds:WriteQuaternion(v) end
	end
end

function fudm.ValueArray:ReadFromBinary(ds)
	self.m_array = {}
	local array = self.m_array
	local type = ds:ReadUInt32()
	self:SetValueType((type ~= math.MAX_UINT32) and type or nil)
	local numElements = ds:ReadUInt32()
	for i=1,numElements do
		local v
		if(type == util.VAR_TYPE_BOOL) then v = ds:ReadBool()
		elseif(type == util.VAR_TYPE_DOUBLE) then v = ds:ReadDouble()
		elseif(type == util.VAR_TYPE_FLOAT) then v = ds:ReadFloat()
		elseif(type == util.VAR_TYPE_INT8) then v = ds:ReadInt8()
		elseif(type == util.VAR_TYPE_INT16) then v = ds:ReadInt16()
		elseif(type == util.VAR_TYPE_INT32) then v = ds:ReadInt32()
		elseif(type == util.VAR_TYPE_INT64) then v = ds:ReadInt64()
		elseif(type == util.VAR_TYPE_LONG_DOUBLE) then v = ds:ReadLongDouble()
		elseif(type == util.VAR_TYPE_STRING) then v = ds:ReadString()
		elseif(type == util.VAR_TYPE_UINT8) then v = ds:ReadUInt8()
		elseif(type == util.VAR_TYPE_UINT16) then v = ds:ReadUInt16()
		elseif(type == util.VAR_TYPE_UINT32) then v = ds:ReadUInt32()
		elseif(type == util.VAR_TYPE_UINT64) then v = ds:ReadUInt64()
		elseif(type == util.VAR_TYPE_EULER_ANGLES) then v = ds:ReadEulerAngles()
		elseif(type == util.VAR_TYPE_COLOR) then v = ds:ReadColor()
		elseif(type == util.VAR_TYPE_VECTOR) then v = ds:ReadVector()
		elseif(type == util.VAR_TYPE_VECTOR2) then v = ds:ReadVector2()
		elseif(type == util.VAR_TYPE_VECTOR4) then v = ds:ReadVector4()
		elseif(type == util.VAR_TYPE_QUATERNION) then v = ds:ReadQuaternion() end
		table.insert(array,v)
	end
	return array
end

function fudm.ValueArray:Get(i) return self:GetTable()[i] end
function fudm.ValueArray:Set(i,v) self:GetTable()[i] = v end

function fudm.ValueArray:Insert(pos,value)
	local t = self:GetValueType()
	if(t == nil) then
		local valueType = util.get_type_name(value)
		if(valueType == "boolean") then t = util.VAR_TYPE_BOOL
		elseif(valueType == "number") then t = util.VAR_TYPE_FLOAT
		elseif(valueType == "string") then t = util.VAR_TYPE_STRING
		elseif(valueType == "EulerAngles") then t = util.VAR_TYPE_EULER_ANGLES
		elseif(valueType == "Color") then t = util.VAR_TYPE_COLOR
		elseif(valueType == "Vector") then t = util.VAR_TYPE_VECTOR
		elseif(valueType == "Vector2") then t = util.VAR_TYPE_VECTOR2
		elseif(valueType == "Vector4") then t = util.VAR_TYPE_VECTOR4
		elseif(valueType == "QuaternionInternal") then t = util.VAR_TYPE_QUATERNION
		else error("Attempted to push value of type '" .. valueType .. "' into value array, which is not supported!") end
		self:SetValueType(t)
	end
	-- Note: It's the caller's responsibility to ensure that the value is of the right type!
	table.insert(self:GetValue(),pos,value)
	self:InvokeChangeListeners(value,pos)
end

function fudm.ValueArray:PushFront(value)
	self:Insert(1,value)
end

function fudm.ValueArray:PushBack(value)
	self:Insert(#self +1,value)
end

function fudm.ValueArray:PopBack()
	return table.remove(self:GetValue(),#self)
end

function fudm.ValueArray:PopFront()
	return table.remove(self:GetValue(),1)
end

function fudm.ValueArray:Clear()
	self.m_array = {}
end
]]

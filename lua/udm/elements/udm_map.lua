--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_MAP = fudm.register_element("Map")
function fudm.Map:Initialize(elementType)
	fudm.BaseElement.Initialize(self)
	self.m_table = {}
end

function fudm.Map:SetValueType(type) self.m_valueType = type end
function fudm.Map:GetValueType() return self.m_valueType end

function fudm.Map:GetValue() return self.m_table end
function fudm.Map:GetTable() return self.m_table end

function fudm.Map:Get(key) return self:GetTable()[key] end

function fudm.Map:Insert(key,val)
	local attrType = val:GetType()
	if(attrType == fudm.ELEMENT_TYPE_REFERENCE) then
		attrType = val:GetTarget():GetType()
	end
	if(self:GetValueType() == nil) then self:SetValueType(attrType) end
	local t = self:GetValueType()
	if(t ~= fudm.ELEMENT_TYPE_ANY and t ~= fudm.ATTRIBUTE_TYPE_ANY and attrType ~= t) then
		pfm.error("Attempted to push value of type " .. (fudm.get_type_name(attrType) or "") .. " into map of type " .. (fudm.get_type_name(t) or "") .. "!")
		return
	end
	self:GetValue()[key] = val
	self:AddChild(val,key)
end

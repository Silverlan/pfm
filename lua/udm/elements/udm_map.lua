--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_MAP = udm.register_element("Map")
function udm.Map:Initialize(elementType)
	udm.BaseElement.Initialize(self)
	self.m_table = {}
end

function udm.Map:SetValueType(type) self.m_valueType = type end
function udm.Map:GetValueType() return self.m_valueType end

function udm.Map:GetValue() return self.m_table end
function udm.Map:GetTable() return self.m_table end

function udm.Map:Get(key) return self:GetTable()[key] end

function udm.Map:Insert(key,val)
	local attrType = val:GetType()
	if(attrType == udm.ELEMENT_TYPE_REFERENCE) then
		attrType = val:GetTarget():GetType()
	end
	if(self:GetValueType() == nil) then self:SetValueType(attrType) end
	local t = self:GetValueType()
	if(t ~= udm.ELEMENT_TYPE_ANY and t ~= udm.ATTRIBUTE_TYPE_ANY and attrType ~= t) then
		pfm.error("Attempted to push value of type " .. (udm.get_type_name(attrType) or "") .. " into map of type " .. (udm.get_type_name(t) or "") .. "!")
		return
	end
	self:GetValue()[key] = val
	self:AddChild(val,key)
end

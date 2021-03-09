--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/graph_axis.lua")

util.register_class("gui.Axis",gui.Base)
function gui.Axis:__init()
	gui.Base.__init(self)
end
function gui.Axis:OnInitialize()
	gui.Base.OnInitialize(self)
	self.m_items = {}
end
function gui.Axis:OnRemove()
	if(util.is_valid(self.m_cbOnPropertiesChanged)) then self.m_cbOnPropertiesChanged:Remove() end
	for _,itemData in ipairs(self.m_items) do
		for _,cb in ipairs(itemData.callbacks) do
			if(cb:IsValid()) then cb:Remove() end
		end
	end
end
function gui.Axis:SetAxis(axis,horizontal)
	self.m_cbOnPropertiesChanged = axis:AddCallback("OnPropertiesChanged",function()
		self:ScheduleUpdate()
	end)
	self.m_axis = axis
	self.m_horizontal = horizontal or false
end
function gui.Axis:GetAxis() return self.m_axis end
function gui.Axis:IsHorizontal() return self.m_horizontal end
function gui.Axis:IsVertical() return self:IsHorizontal() == false end
function gui.Axis:AttachElementToValue(el,value)
	local itemData = {}
	itemData.element = el
	itemData.value = value
	itemData.callbacks = {
		value:AddChangeListener(function(newValue)
			self:UpdateItem(itemData)
		end)
	}
	table.insert(self.m_items,itemData)
	self:ScheduleUpdate()
end
function gui.Axis:AttachElementToRange(el,startValue,lengthValue)
	local itemData = {}
	itemData.element = el
	itemData.value = startValue
	itemData.lengthValue = lengthValue
	itemData.callbacks = {
		startValue:AddChangeListener(function(newValue)
			self:UpdateItem(itemData)
		end),
		lengthValue:AddChangeListener(function(newValue)
			self:UpdateItem(itemData)
		end)
	}
	table.insert(self.m_items,itemData)
	self:ScheduleUpdate()
end
function gui.Axis:OnUpdate()
	self:UpdateItems()
end
function gui.Axis:UpdateItems()
	for _,itemData in ipairs(self.m_items) do
		if(itemData.element:IsValid()) then
			self:UpdateItem(itemData)
		end
	end
end
function gui.Axis:UpdateItem(itemData)
	local axis = self:GetAxis()
	if(itemData.lengthValue == nil) then
		local v = itemData.value:GetValue()
		local x = axis:ValueToXOffset(v)
		local extents = self:IsHorizontal() and itemData.element:GetWidth() or itemData.element:GetHeight()
		x = x -extents /2

		local pos = itemData.element:GetAbsolutePos()
		if(self:IsHorizontal()) then pos.x = self:GetAbsolutePos().x +x
		else pos.y = self:GetAbsolutePos().y +x end
		itemData.element:SetAbsolutePos(pos)
	else
		local startOffset = itemData.value:GetValue()
		local endOffset = startOffset +itemData.lengthValue:GetValue()
		local xStart = axis:ValueToXOffset(startOffset)
		local xEnd = axis:ValueToXOffset(endOffset)

		local w = xEnd -xStart
		local xStartAbs = (self:IsHorizontal() and self:GetAbsolutePos().x or self:GetAbsolutePos().y) +xStart
		local pos = itemData.element:GetAbsolutePos()
		if(self:IsHorizontal()) then pos.x = xStartAbs
		else pos.y = xStartAbs end
		itemData.element:SetAbsolutePos(pos)
		if(self:IsHorizontal()) then itemData.element:SetWidth(w)
		else itemData.element:SetHeight(w) end
	end
end
gui.register("WIAxis",gui.Axis)

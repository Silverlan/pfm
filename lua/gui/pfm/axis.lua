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
	self.m_itemIndex = 0
end
function gui.Axis:OnRemove()
	if(util.is_valid(self.m_cbOnPropertiesChanged)) then self.m_cbOnPropertiesChanged:Remove() end
	for _,itemData in pairs(self.m_items) do
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
function gui.Axis:UpdateAttachment(i,start,duration)
	local itemData = self.m_items[i]
	if(itemData == nil) then return end
	if(itemData.element:IsValid() == false) then
		self.m_items[i] = nil
		return
	end
	if(start ~= nil) then itemData.value = start end
	if(duration ~= nil) then itemData.lengthValue = duration end
	self:UpdateItem(itemData)
end
function gui.Axis:AttachElementToValue(el,value)
	local index = self.m_itemIndex
	self.m_itemIndex = self.m_itemIndex +1

	local itemData = {}
	itemData.element = el
	itemData.value = value
	itemData.callbacks = {}
	self.m_items[index] = itemData
	self:ScheduleUpdate()
	return index
end
function gui.Axis:AttachElementToValueWithUdmProperty(el,udmEl,propName)
	local val = udmEl:GetPropertyValue(propName)
	local i = self:AttachElementToValue(el,val)
	table.insert(self.m_items[i].callbacks,udmEl:AddChangeListener(propName,function(c,newTime) self:UpdateAttachment(i,newTime) end))
end
function gui.Axis:AttachElementToRange(el,timeFrame)
	local index = self.m_itemIndex
	self.m_itemIndex = self.m_itemIndex +1

	local itemData = {}
	itemData.element = el
	itemData.value = timeFrame:GetStart()
	itemData.lengthValue = timeFrame:GetDuration()
	itemData.callbacks = {
		timeFrame:AddChangeListener("start",function(newValue)
			self:UpdateAttachment(index,newValue)
		end),
		timeFrame:AddChangeListener("duration",function(newValue)
			self:UpdateAttachment(index,nil,newValue)
		end)
	}
	self.m_items[index] = itemData
	self:ScheduleUpdate()
end
function gui.Axis:OnUpdate()
	self:UpdateItems()
end
function gui.Axis:UpdateItems()
	local invalidItems = {}
	for i,itemData in pairs(self.m_items) do
		if(itemData.element:IsValid()) then
			self:UpdateItem(itemData)
		else table.insert(invalidItems,i) end
	end

	for _,i in ipairs(invalidItems) do self.m_items[i] = nil end
end
function gui.Axis:UpdateItem(itemData)
	local axis = self:GetAxis()
	if(itemData.lengthValue == nil) then
		local v = itemData.value
		local x = axis:ValueToXOffset(v)
		local extents = self:IsHorizontal() and itemData.element:GetWidth() or itemData.element:GetHeight()
		x = x -extents /2

		local pos = itemData.element:GetAbsolutePos()
		if(self:IsHorizontal()) then pos.x = self:GetAbsolutePos().x +x
		else pos.y = self:GetAbsolutePos().y +x end
		itemData.element:SetAbsolutePos(pos)
	else
		local startOffset = itemData.value
		local endOffset = startOffset +itemData.lengthValue
		local xStart = axis:ValueToXOffset(startOffset)
		local xEnd = axis:ValueToXOffset(endOffset)

		local w = axis:ValueToXOffset(endOffset) -axis:ValueToXOffset(startOffset)
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

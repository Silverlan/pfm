-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("Element", gui.Base)
function Element:OnInitialize()
	self.m_childCallbacks = {}
	self:AddStyleClass("gridbox")
	self:AddCallback("OnChildAdded", function(el, elChild)
		self:ScheduleUpdate()
		self.m_childCallbacks[elChild] = {}
		local visProp = elChild:GetVisibilityProperty()
		table.insert(
			self.m_childCallbacks[elChild],
			visProp:AddCallback(function()
				self:ScheduleUpdate()
			end)
		)
	end)
	self:AddCallback("OnChildRemoved", function(el, elChild)
		self:ScheduleUpdate()
		self:RemoveChildCallbacks(elChild)
	end)

	self:SetSpacing(5)
end
function Element:OnRemove()
	for elChild, callbacks in pairs(self.m_childCallbacks) do
		for _, cb in ipairs(callbacks) do
			if cb:IsValid() then
				cb:Remove()
			end
		end
	end
end
function Element:RemoveChildCallbacks(el)
	if self.m_childCallbacks[el] == nil then
		return
	end
	for _, cb in ipairs(self.m_childCallbacks[el]) do
		if cb:IsValid() then
			cb:Remove()
		end
	end
	self.m_childCallbacks[el] = nil
end
function Element:SetSpacing(x, y)
	self.m_spacing = { x, y or x }
end
function Element:SetHorizontalSpacing(spacing)
	self.m_spacing[1] = spacing
end
function Element:SetVerticalSpacing(spacing)
	self.m_spacing[2] = spacing
end
function Element:GetHorizontalSpacing()
	return self.m_spacing[1]
end
function Element:GetVerticalSpacing()
	return self.m_spacing[2]
end
function Element:OnSizeChanged(w, h)
	self:ScheduleUpdate()
end
function Element:SetChildOrder(order)
	self.m_childOrder = order
end
function Element:ApplyStyle(style)
	local spacingX
	local spacingY
	local spacing = style:GetPropertyValue("spacing", udm.TYPE_INT32)
	if(spacing) then
		spacingX = spacing
		spacingY = spacing
	end

	spacingX = style:GetPropertyValue("spacingX", udm.TYPE_INT32) or spacingX
	spacingY = style:GetPropertyValue("spacingY", udm.TYPE_INT32) or spacingY
	if(spacingX) then self:SetHorizontalSpacing(spacingX) end
	if(spacingY) then self:SetVerticalSpacing(spacingY) end
	if(spacingX or spacingY) then self:ScheduleUpdate() end
end
function Element:OnUpdate()
	local x = 0
	local y = 0
	local w = self:GetWidth()
	local h = self:GetHeight()
	local childHeight
	local children = self:GetChildren()
	if self.m_childOrder ~= nil then
		local sorted = {}
		for _, idx in ipairs(self.m_childOrder) do
			table.insert(sorted, children[idx])
		end
		children = sorted
	end
	local first = true
	for _, child in ipairs(children) do
		if child:IsVisible() then
			childHeight = childHeight or child:GetHeight()
			local r = x + child:GetWidth()
			if r > w then
				if first then y = 0
				else y = y + child:GetHeight() + self:GetVerticalSpacing() end
				x = 0
			end
			child:ApplyPos(x, y)
			x = child:GetRight() + self:GetHorizontalSpacing()
		end
		first = false
	end
	y = y + (childHeight or 0)
	if y ~= self:GetHeight() then
		self:ApplyHeight(y)
	end
end
gui.register("grid_box", Element)

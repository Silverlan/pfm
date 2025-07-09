-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.GridBox", gui.Base)
function gui.GridBox:__init()
	gui.Base.__init(self)
end
function gui.GridBox:OnInitialize()
	self.m_childCallbacks = {}
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
function gui.GridBox:OnRemove()
	for elChild, callbacks in pairs(self.m_childCallbacks) do
		for _, cb in ipairs(callbacks) do
			if cb:IsValid() then
				cb:Remove()
			end
		end
	end
end
function gui.GridBox:RemoveChildCallbacks(el)
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
function gui.GridBox:SetSpacing(x, y)
	self.m_spacing = { x, y or x }
end
function gui.GridBox:SetHorizontalSpacing(spacing)
	self.m_spacing[1] = spacing
end
function gui.GridBox:SetVerticalSpacing(spacing)
	self.m_spacing[2] = spacing
end
function gui.GridBox:GetHorizontalSpacing()
	return self.m_spacing[1]
end
function gui.GridBox:GetVerticalSpacing()
	return self.m_spacing[2]
end
function gui.GridBox:OnSizeChanged(w, h)
	self:ScheduleUpdate()
end
function gui.GridBox:SetChildOrder(order)
	self.m_childOrder = order
end
function gui.GridBox:OnUpdate()
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
	for _, child in ipairs(children) do
		if child:IsVisible() then
			childHeight = childHeight or child:GetHeight()
			local r = x + child:GetWidth()
			if r > w and child:GetWidth() < w then
				y = y + child:GetHeight() + self:GetVerticalSpacing()
				x = 0
			end
			child:SetPos(x, y)
			x = child:GetRight() + self:GetHorizontalSpacing()
		end
	end
	y = y + (childHeight or 0)
	if y ~= self:GetHeight() then
		self:SetHeight(y)
	end
end
gui.register("WIGridBox", gui.GridBox)

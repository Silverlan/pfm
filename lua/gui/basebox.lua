--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.BaseBox",gui.Base)

function gui.BaseBox:__init()
	gui.Base.__init(self)
end
function gui.BaseBox:RemoveChildCallbacks(el)
	if(self.m_childCallbacks[el] == nil) then return end
	for _,cb in ipairs(self.m_childCallbacks[el]) do
		if(cb:IsValid()) then cb:Remove() end
	end
	self.m_childCallbacks[el] = nil
end
function gui.BaseBox:IsBackgroundElement(el)
	return self.m_backgroundElements and self.m_backgroundElements[el] ~= nil and true or false
end
function gui.BaseBox:SetBackgroundElement(el)
	self:RemoveChildCallbacks(el)
	self.m_backgroundElements = self.m_backgroundElements or {}
	self.m_backgroundElements[el] = true
end
function gui.BaseBox:OnSizeChanged(w,h)
	self:ScheduleUpdate()
end
function gui.BaseBox:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetAutoSizeToContents()
	self.m_childCallbacks = {}
	self:AddCallback("OnChildAdded",function(el,elChild)
		self:ScheduleUpdate()
		if(self:IsBackgroundElement(elChild)) then return end
		self.m_childCallbacks[elChild] = {}
		table.insert(self.m_childCallbacks[elChild],elChild:AddCallback("SetSize",function(elChild)
			-- Note: We mustn't update if the child is anchored, otherwise we end up in an infinite recursion!
			if(elChild:HasAnchor()) then return end
			self:ScheduleUpdate()
		end))
		table.insert(self.m_childCallbacks[elChild],elChild:AddCallback("OnRemove",function(elChild)
			-- We'll have to update whenever one of our children has been removed
			self:ScheduleUpdate()
		end))
		local visProp = elChild:GetVisibilityProperty()
		table.insert(self.m_childCallbacks[elChild],visProp:AddCallback(function()
			self:ScheduleUpdate()
		end))
	end)
	self:AddCallback("OnChildRemoved",function(el,elChild)
		self:ScheduleUpdate()
		self:RemoveChildCallbacks(elChild)
	end)
end
function gui.BaseBox:OnRemove()
	for elChild,callbacks in pairs(self.m_childCallbacks) do
		for _,cb in ipairs(callbacks) do
			if(cb:IsValid()) then cb:Remove() end
		end
	end
end
function gui.BaseBox:SetFixedWidth(fixed)
	local size = self:GetSize()
	self.m_fixedWidth = fixed
	self:SetAutoSizeToContents(not self.m_fixedWidth,not self.m_fixedHeight)
	self:SetSize(size) -- Keep our old size for now
end
function gui.BaseBox:SetFixedHeight(fixed)
	local size = self:GetSize()
	self.m_fixedHeight = fixed
	self:SetAutoSizeToContents(not self.m_fixedWidth,not self.m_fixedHeight)
	self:SetSize(size) -- Keep our old size for now
end
function gui.BaseBox:SetFixedSize(fixed)
	self:SetFixedWidth(fixed)
	self:SetFixedHeight(fixed)
end
-- Auto-fill will stretch the children to fill out the size of the box.
-- Width auto-fill on a horizontal box will cause the last child to be stretched to the remaining width.
-- Height auto-fill on a horizontal box will cause all children to be stretched to the full height.
-- The behavior for vertical boxes is the same, but opposite.
function gui.BaseBox:SetAutoFillContentsToWidth(autoFill)
	self.m_autoFillWidth = autoFill
	if(autoFill) then self:SetFixedWidth(true) end
end
function gui.BaseBox:SetAutoFillContentsToHeight(autoFill)
	self.m_autoFillHeight = autoFill
	if(autoFill) then self:SetFixedHeight(true) end
end
function gui.BaseBox:SetAutoFillContents(autoFill)
	self:SetAutoFillContentsToWidth(autoFill)
	self:SetAutoFillContentsToHeight(autoFill)
end
function gui.BaseBox:SetAutoFillTarget(el) self.m_autoFillTarget = el end
function gui.BaseBox:IsHorizontalBox() return false end
function gui.BaseBox:IsVerticalBox() return false end

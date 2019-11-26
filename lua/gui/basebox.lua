--[[
    Copyright (C) 2019  Florian Weischer

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
function gui.BaseBox:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_childCallbacks = {}
	self:AddCallback("OnChildAdded",function(el,elChild)
		self:ScheduleUpdate()
		if(self:IsBackgroundElement(elChild)) then return end
		self.m_childCallbacks[elChild] = {}
		table.insert(self.m_childCallbacks[elChild],elChild:AddCallback("SetSize",function()
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
function gui.BaseBox:SetFixedSize(fixedSize) self.m_fixedSize = fixedSize end
function gui.BaseBox:OnSizeChanged(w,h)
	if(self.m_fixedSize ~= true or self.m_skipSizeUpdate == true) then return end
	self:Update()
end

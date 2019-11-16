--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.HBox",gui.Base)

function gui.HBox:__init()
	gui.Base.__init(self)
end
function gui.HBox:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_childCallbacks = {}
	self:AddCallback("OnChildAdded",function(el,elChild)
		self:ScheduleUpdate()
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
		if(self.m_childCallbacks[elChild] ~= nil) then
			for _,cb in ipairs(self.m_childCallbacks[elChild]) do
				if(cb:IsValid()) then cb:Remove() end
			end
		end
	end)
end
function gui.HBox:OnRemove()
	for elChild,callbacks in pairs(self.m_childCallbacks) do
		for _,cb in ipairs(callbacks) do
			if(cb:IsValid()) then cb:Remove() end
		end
	end
end
function gui.HBox:SetFixedSize(fixedSize) self.m_fixedSize = fixedSize end
function gui.HBox:OnSizeChanged(w,h)
	if(self.m_fixedSize ~= true or self.m_skipSizeUpdate == true) then return end
	self:Update()
end
function gui.HBox:OnUpdate()
	self.m_skipSizeUpdate = true
	local size = self:GetSize()
	local x = 0
	local lastChild
	for _,child in ipairs(self:GetChildren()) do
		if(child:IsVisible()) then
			child:SetX(x)
			if(self.m_fixedSize == true) then child:SetHeight(size.y) end
			x = x +child:GetWidth()

			lastChild = child
		end
	end
	if(self.m_fixedSize ~= true) then self:SetWidth(x)
	elseif(lastChild ~= nil) then lastChild:SetWidth(size.x -lastChild:GetLeft()) end
	self.m_skipSizeUpdate = nil
end
gui.register("WIHBox",gui.HBox)

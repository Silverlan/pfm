--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("basebox.lua")

util.register_class("gui.HBox",gui.BaseBox)

function gui.HBox:__init()
	gui.BaseBox.__init(self)
end
function gui.HBox:OnUpdate()
	local size = self:GetSize()
	local x = 0
	local h = 0
	local lastChild
	for _,child in ipairs(self:GetChildren()) do
		if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
			child:SetX(x)
			if(self.m_autoFillHeight == true and child:HasAnchor() == false) then child:SetHeight(size.y) end
			x = x +child:GetWidth()
			h = math.max(h,child:GetBottom())

			lastChild = child
		end
	end

	local curSize = size:Copy()
	if(self.m_fixedWidth ~= true) then size.x = x
	elseif(self.m_autoFillWidth == true and lastChild ~= nil and lastChild:HasAnchor() == false) then
		lastChild:SetWidth(size.x -lastChild:GetLeft())
		lastChild:Update()
	end
	if(self.m_fixedHeight ~= true) then size.y = h end
	if(size ~= curSize and self:HasAnchor() == false) then self:SetSize(size) end
	self:CallCallbacks("OnContentsUpdated")
end
function gui.HBox:IsHorizontalBox() return true end
gui.register("WIHBox",gui.HBox)

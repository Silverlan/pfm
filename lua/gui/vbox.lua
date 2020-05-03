--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("basebox.lua")

util.register_class("gui.VBox",gui.BaseBox)

function gui.VBox:__init()
	gui.BaseBox.__init(self)
end
function gui.VBox:OnUpdate()
	local size = self:GetSize()
	local y = 0
	local w = 0
	local lastChild
	for _,child in ipairs(self:GetChildren()) do
		if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
			child:SetY(y)
			if(self.m_autoFillWidth == true and child:HasAnchor() == false) then child:SetWidth(size.x) end
			y = y +child:GetHeight()
			w = math.max(w,child:GetRight())

			lastChild = child
		end
	end

	local curSize = size:Copy()
	if(self.m_fixedWidth ~= true) then size.x = w end
	if(self.m_fixedHeight ~= true) then size.y = y
	elseif(self.m_autoFillHeight == true and lastChild ~= nil and lastChild:HasAnchor() == false) then lastChild:SetHeight(size.y -lastChild:GetTop()) end
	if(size ~= curSize and self:HasAnchor() == false) then self:SetSize(size) end
	self:CallCallbacks("OnContentsUpdated")
end
function gui.VBox:IsVerticalBox() return true end
gui.register("WIVBox",gui.VBox)

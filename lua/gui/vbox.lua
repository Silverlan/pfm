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
	self.m_skipSizeUpdate = true
	local size = self:GetSize()
	local y = 0
	local lastChild
	for _,child in ipairs(self:GetChildren()) do
		if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
			child:SetY(y)
			if(self.m_fixedSize == true) then child:SetWidth(size.x) end
			y = y +child:GetHeight()

			lastChild = child
		end
	end
	if(self.m_fixedSize ~= true) then self:SetHeight(y)
	elseif(lastChild ~= nil) then lastChild:SetHeight(size.y -lastChild:GetTop()) end
	self.m_skipSizeUpdate = nil
end
gui.register("WIVBox",gui.VBox)

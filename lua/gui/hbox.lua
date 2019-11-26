--[[
    Copyright (C) 2019  Florian Weischer

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
	self.m_skipSizeUpdate = true
	local size = self:GetSize()
	local x = 0
	local lastChild
	for _,child in ipairs(self:GetChildren()) do
		if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
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

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
	local autoFillChild
	local children = self:GetChildren()
	for i,child in ipairs(children) do
		if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
			child:SetX(x)
			if(self.m_autoFillHeight == true and child:HasAnchor() == false) then child:SetHeight(size.y) end
			x = x +child:GetWidth()
			h = math.max(h,child:GetBottom())

			lastChild = i
			if(child == self.m_autoFillTarget) then autoFillChild = i end
		end
	end
	autoFillChild = autoFillChild or lastChild

	local curSize = size:Copy()
	if(self.m_fixedWidth ~= true) then size.x = x
	elseif(self.m_autoFillWidth == true and children[autoFillChild] ~= nil and children[autoFillChild]:HasAnchor() == false) then
		local sizeAdd = (size.x -children[lastChild]:GetRight())
		children[autoFillChild]:SetWidth(children[autoFillChild]:GetWidth() +sizeAdd)
		children[autoFillChild]:Update()

		for i=autoFillChild +1,#children do
			local child = children[i]
			if(child:IsVisible() and self:IsBackgroundElement(child) == false) then
				child:SetX(child:GetX() +sizeAdd)
			end
		end
	end
	if(self.m_fixedHeight ~= true) then size.y = h end
	if(size ~= curSize and self:HasAnchor() == false) then self:SetSize(size) end
	self:CallCallbacks("OnContentsUpdated")
end
function gui.HBox:IsHorizontalBox() return true end
gui.register("WIHBox",gui.HBox)

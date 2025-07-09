-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("basebox.lua")

util.register_class("gui.VBox", gui.BaseBox)

function gui.VBox:__init()
	gui.BaseBox.__init(self)
end
function gui.VBox:OnUpdate()
	local size = self:GetSize()
	local y = 0
	local w = 0
	local lastChild
	local autoFillChild
	local children = self:GetChildren()
	for i, child in ipairs(children) do
		if child:IsVisible() and self:IsBackgroundElement(child) == false then
			child:SetY(y)
			if self.m_autoFillWidth == true and child:HasAnchor() == false then
				child:SetWidth(math.max(size.x, 0))
			end
			y = y + child:GetHeight()
			w = math.max(w, child:GetRight())

			lastChild = i
			if child == self.m_autoFillTarget then
				autoFillChild = i
			end
		end
	end
	autoFillChild = autoFillChild or lastChild

	local curSize = size:Copy()
	if self.m_fixedWidth ~= true then
		size.x = w
	else
		size.x = self:GetWidth()
	end
	if self.m_fixedHeight ~= true then
		size.y = y
	else
		size.y = self:GetHeight()
		if
			self.m_autoFillHeight == true
			and children[autoFillChild] ~= nil
			and children[autoFillChild]:HasAnchor() == false
		then
			local height
			local sizeAdd
			if util.is_same_object(children[autoFillChild], children[lastChild]) then
				height = size.y - children[autoFillChild]:GetTop()
			else
				sizeAdd = (size.y - children[lastChild]:GetBottom())
				height = children[autoFillChild]:GetHeight() + sizeAdd
			end
			children[autoFillChild]:SetHeight(height)
			children[autoFillChild]:Update()

			if sizeAdd ~= nil then
				for i = autoFillChild + 1, #children do
					local child = children[i]
					if child:IsVisible() and self:IsBackgroundElement(child) == false then
						child:SetY(child:GetY() + sizeAdd)
					end
				end
			end
		end
	end
	if self.m_sizeUpdateRequired then
		size.x = math.max(size.x, 0)
		size.y = math.max(size.y, 0)
		if size ~= curSize and self:HasAnchor() == false then
			self:UpdateSize(size)
		end
		self:CallCallbacks("OnContentsUpdated")
		self.m_sizeUpdateRequired = nil
	end
end
function gui.VBox:IsVerticalBox()
	return true
end
gui.register("WIVBox", gui.VBox)

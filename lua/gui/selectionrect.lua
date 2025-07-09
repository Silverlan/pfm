-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("selectionoutline.lua")

util.register_class("gui.SelectionRect", gui.Base)
function gui.SelectionRect:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	local el = gui.create("WIOutlinedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	el:SetColor(pfm.get_color_scheme_color("yellow2"))
	self:SetThinkingEnabled(true)
end
function gui.SelectionRect:IsElementInBounds(el, min, max)
	min = min or Vector(self:GetPos(), 0)
	max = max or Vector(self:GetPos() + self:GetSize(), 0)

	local minChild = Vector(el:GetPos(), 0)
	local maxChild = Vector(el:GetPos() + el:GetSize(), 0)
	local r = intersect.aabb_with_aabb(min, max, minChild, maxChild)
	return r ~= intersect.RESULT_OUTSIDE
end
function gui.SelectionRect:FindElements(filter, target)
	target = target or self:GetParent()

	local min = Vector(self:GetPos(), 0)
	local max = Vector(self:GetPos() + self:GetSize(), 0)
	local els = {}
	for _, child in ipairs(target:GetChildren()) do
		if child ~= self then
			if self:IsElementInBounds(child, min, max) and filter(child) == true then
				table.insert(els, child)
			end
		end
	end
	return els
end
function gui.SelectionRect:OnThink()
	self.m_pivotPos = self.m_pivotPos or self:GetPos()

	local p = self:GetParent()
	local pos0 = self.m_pivotPos
	local pos1 = p:GetCursorPos()

	local min = Vector2(math.min(pos0.x, pos1.x), math.min(pos0.y, pos1.y))
	local max = Vector2(math.max(pos0.x, pos1.x), math.max(pos0.y, pos1.y))
	self:SetPos(min)
	self:SetSize(max - min)
end
gui.register("WISelectionRect", gui.SelectionRect)

-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
local Element = util.register_class("gui.pfm.ArrowIndicator", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(47 /1.5, 61 /1.5)

	local el = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	el:SetMaterial("gui/generic_arrow_down")
	el:GetColorProperty():Link(self:GetColorProperty())
	self.m_arrow = el

	self:SetThinkingEnabled(true)
	self:SetColor(Color.Lime)

	self:SetBounceFactor(1.0)
	self:SetArrowRotation(0.0)
	self:SetBounceDistance(20.0)
	self:SetMargin(10)
end
function Element:OnPosChanged(x, y, changeSource)
	if(changeSource == gui.CHANGE_SOURCE_USER) then
		self.m_basePos = self:GetPos()
	end
end
function Element:OnThink()
	self.m_basePos = self.m_basePos or self:GetPos()

	local f = math.sin(time.real_time() *8)
	f = (f +1.0) /2.0
	local moveDist = self.m_bounceDistance *self.m_bounceFactor
	local newPos = self.m_basePos +self.m_dir *f *moveDist
    self:ApplyPos(newPos)
end
function Element:SetBounceDistance(dist) self.m_bounceDistance = dist end
function Element:SetBounceFactor(f) self.m_bounceFactor = f end
function Element:SetMargin(margin) self.m_margin = margin end
function Element:SetArrowRotation(rot)
	local pivotPos = Vector2(self.m_arrow:GetHalfWidth(), self.m_arrow:GetHalfHeight())
	self:SetRotation(rot, pivotPos)

	rot = math.rad(rot)
	rot = rot -math.rad(90)
	self.m_dir = Vector2(math.cos(rot), math.sin(rot))
end
function Element:ClampPositionToParentBounds()
	local pos = self:GetCenter()
	local tip = pos -self.m_dir *self:GetHalfWidth()
	tip.x = math.clamp(tip.x, 0.0, self:GetParent():GetWidth())
	tip.y = math.clamp(tip.y, 0.0, self:GetParent():GetHeight())
	pos = tip +self.m_dir *(self:GetHalfWidth() +self.m_margin)
	pos.x = pos.x -self:GetHalfWidth()
	pos.y = pos.y -self:GetHalfHeight()
	self:SetPos(pos)
end
gui.register("pfm_arrow_indicator", Element)

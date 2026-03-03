-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
local RepeatedTexturedRect = util.register_class("gui.pfm.RepeatedTexturedRect", gui.Base)
function RepeatedTexturedRect:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	local el = gui.create("WI9SliceRectSegment", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
    el:GetColorProperty():Link(self:GetColorProperty())
	el:AddCallback("SetSize", function(p)
		local imgWidth = math.max(el:GetTextureSize().x, 1)
		local scale = el:GetWidth() /imgWidth
		el:SetRenderImageScale(Vector2(scale, 1.0))
	end)
    self.m_element = el
end
function RepeatedTexturedRect:SetMaterial(mat)
	self.m_element:SetMaterial(mat)
end
gui.register("pfm_repeated_textured_rect", RepeatedTexturedRect)

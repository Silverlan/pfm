-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.HoverText", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetZPos(100000)

	local elTextShadow = gui.create("WIText", self)
	elTextShadow:SetColor(Color.Black)
	elTextShadow:SetPos(2, 2)
	elTextShadow:SetFont("pfm_small")
	elTextShadow:AddStyleClass("text_shadow")

	local elText = gui.create("WIText", self)
	elText:SetColor(Color.White)
	elText:SetFont("pfm_small")

	self.m_elTextHover = elText
	self.m_elTextShadowHover = elTextShadow

	self:SetThinkingEnabled(true)
end
function Element:SetWorldSpacePosition(pos)
	self.m_worldPos = pos
end
function Element:OnThink()
	if self.m_worldPos == nil then
		return
	end
	local parent = self:GetParent()
	if not parent:IsType(gui.TYPE_VIEWPORT) then
		return
	end
	local vpData = ents.ClickComponent.get_viewport_data(parent)
	local uv = ents.ClickComponent.world_space_point_to_screen_space_uv(self.m_worldPos, nil, vpData)
	if uv == nil then
		return
	end
	local pos = Vector2(uv.x * vpData.width, uv.y * vpData.height)
	pos.x = pos.x + 10
	pos.y = pos.y - self:GetHeight() * 0.5
	self:SetPos(pos)
end
function Element:GetText()
	return self.m_elTextHover:GetText()
end
function Element:SetText(text)
	self.m_elTextHover:SetText(text)
	self.m_elTextHover:SizeToContents()
	self.m_elTextHover:SetHeight(self.m_elTextHover:GetHeight() + 1)

	self.m_elTextShadowHover:SetText(text)
	self.m_elTextShadowHover:SizeToContents()
	self.m_elTextShadowHover:SetHeight(self.m_elTextShadowHover:GetHeight() + 1)

	self:SizeToContents()
end
gui.register("hover_text", Element)

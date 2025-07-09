-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.KernelsBuildMessage", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	local el = gui.create("WIText", self)
	el:SetText(locale.get_text("pfm_building_render_kernels"))
	el:SetFont("pfm_large")
	el:SetColor(Color.White)
	el:SizeToContents()
	self.m_elText = el

	self.m_nextUpdate = time.real_time() + 1.0
	self.m_numDots = 3
	self:EnableThinking()
end
function Element:OnThink()
	local t = time.real_time()
	if t < self.m_nextUpdate then
		return
	end
	self.m_nextUpdate = t + 1.0
	self.m_numDots = (self.m_numDots + 1) % 4
	local text = locale.get_text("pfm_building_render_kernels")
	text = text .. string.rep(".", self.m_numDots)
	self.m_elText:SetText(text)
	self.m_elText:SizeToContents()
	self:SetSize(self.m_elText:GetSize())
end
gui.register("WIKernelsBuildMessage", Element)

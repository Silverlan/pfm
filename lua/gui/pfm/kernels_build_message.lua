--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.KernelsBuildMessage",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	local el = gui.create("WIText",self)
	el:SetText(locale.get_text("pfm_building_render_kernels"))
	el:SetFont("pfm_large")
	el:SetColor(Color.White)
	el:SizeToContents()
	self.m_elText = el

	self.m_nextUpdate = time.real_time() +1.0
	self.m_numDots = 3
	self:EnableThinking()
end
function Element:OnThink()
	local t = time.real_time()
	if(t < self.m_nextUpdate) then return end
	self.m_nextUpdate = t +1.0
	self.m_numDots = (self.m_numDots +1) %4
	local text = locale.get_text("pfm_building_render_kernels")
	text = text .. string.rep(".",self.m_numDots)
	self.m_elText:SetText(text)
	self.m_elText:SizeToContents()
	self:SetSize(self.m_elText:GetSize())
end
gui.register("WIKernelsBuildMessage",Element)

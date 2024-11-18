--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/shader_graph/shader_graph.lua")

local Element = util.register_class("gui.PFMShaderEditor", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 256)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(128, 128, 128))
	self.m_bg:SetColor(Color(64, 64, 64))

	local elGraph = gui.create("WIShaderGraph", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	elGraph:SetGraph(shader.get_test_graph())
end
gui.register("WIPFMShaderEditor", Element)

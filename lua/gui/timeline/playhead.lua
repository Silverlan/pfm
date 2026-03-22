-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("marker.lua")

local Playhead = util.register_class("gui.Playhead", gui.TimelineMarker)

function Playhead:OnInitialize()
	gui.TimelineMarker.OnInitialize(self)

	self:SetSize(11, 128)
	self.m_line = gui.create("WIRect", self, 5, 8, 1, self:GetHeight() - 8 * 2)
	self.m_top = gui.create("WITexturedRect", self, 0, 0, 11, 16)
	self.m_top:SetMaterial("gui/pfm/timeline/upper_playhead")
	self.m_bottom = gui.create("WITexturedRect", self, 0, self:GetBottom() - 16, 11, 16, 0, 1, 0, 1)
	self.m_bottom:SetMaterial("gui/pfm/timeline/lower_playhead")

	self.m_line:GetColorProperty():Link(self:GetColorProperty())
	self.m_top:GetColorProperty():Link(self:GetColorProperty())
	self.m_bottom:GetColorProperty():Link(self:GetColorProperty())

	self:UpdateLineEndPos()
end
function Playhead:UpdateLineEndPos()
	if util.is_valid(self.m_line) == false then
		return
	end
	self.m_line:ApplyHeight(self:GetHeight() - 8 * 2)
end
function Playhead:OnSizeChanged(w, h)
	self:UpdateLineEndPos()
end
gui.register("playhead", Playhead)

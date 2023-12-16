--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("timeline_marker.lua")

local Element = util.register_class("gui.Playhead", gui.TimelineMarker)

function Element:OnInitialize()
	gui.TimelineMarker.OnInitialize(self)

	self:SetSize(11, 128)
	local color = Color(94, 112, 132)
	self.m_line = gui.create("WIRect", self, 5, 8, 1, self:GetHeight() - 8 * 2)
	self.m_top = gui.create("WITexturedRect", self, 0, 0, 11, 16)
	self.m_top:SetMaterial("gui/pfm/timeline_upper_playhead")
	self.m_bottom = gui.create("WITexturedRect", self, 0, self:GetBottom() - 16, 11, 16, 0, 1, 0, 1)
	self.m_bottom:SetMaterial("gui/pfm/timeline_lower_playhead")

	self.m_line:SetColor(color)

	self:UpdateLineEndPos()
end
function Element:UpdateLineEndPos()
	if util.is_valid(self.m_line) == false then
		return
	end
	self.m_line:SetHeight(self:GetHeight() - 8 * 2)
end
function Element:OnSizeChanged(w, h)
	self:UpdateLineEndPos()
end
gui.register("WIPlayhead", Element)

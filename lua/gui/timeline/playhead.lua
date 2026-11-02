-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("marker.lua")

local Playhead = util.register_class("gui.Playhead", gui.TimelineMarker)

function Playhead:OnInitialize()
	gui.TimelineMarker.OnInitialize(self)

	self:SetSize(11, 128)

	local contents = gui.create_vbox(self)
		:AddStyleClass("fill")
		:AddStyleClass("playhead__content-area")

	self.m_top = gui.create("WIBase", contents)
		:AddStyleClass("playhead__icon")
		:AddStyleClass("playhead__icon--upper")
	self.m_line = gui.create("WIBase", contents)
		:AddStyleClass("playhead__line")
	self.m_bottom = gui.create("WIBase", contents)
		:AddStyleClass("playhead__icon")
		:AddStyleClass("playhead__icon--lower")
end
gui.register("playhead", Playhead)

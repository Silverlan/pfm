-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/controls/play_button.lua")

util.register_class("gui.PFMVRInterface", gui.Base)

function gui.PFMVRInterface:__init()
	gui.Base.__init(self)
end
function gui.PFMVRInterface:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	self.m_playButton = gui.create("pfm_play_button", self)
	self:SetSize(self.m_playButton:GetSize())
end
function gui.PFMVRInterface:GetPlayButton()
	return self.m_playButton
end
gui.register("pfm_vr_interface", gui.PFMVRInterface)

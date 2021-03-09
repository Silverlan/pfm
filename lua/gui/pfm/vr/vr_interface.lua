--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/playbutton.lua")

util.register_class("gui.PFMVRInterface",gui.Base)

function gui.PFMVRInterface:__init()
	gui.Base.__init(self)
end
function gui.PFMVRInterface:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)
	self.m_playButton = gui.create("WIPFMPlayButton",self)
	self:SetSize(self.m_playButton:GetSize())
end
function gui.PFMVRInterface:GetPlayButton() return self.m_playButton end
gui.register("WIPFMVRInterface",gui.PFMVRInterface)

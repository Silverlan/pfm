--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("sound_clip")
include("time_frame.lua")

util.register_class("sfm.SoundClip",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.SoundClip,"sound",sfm.Sound)
sfm.BaseElement.RegisterProperty(sfm.SoundClip,"timeFrame",sfm.TimeFrame)

function sfm.SoundClip:__init()
  sfm.BaseElement.__init(self,sfm.SoundClip)
end

function sfm.SoundClip:GetType() return "DmeSoundClip" end

function sfm.SoundClip:ToPFMAudioClip(pfmAudioClip)
  self:GetSound():ToPFMSound(pfmAudioClip:GetSound())
  self:GetTimeFrame():ToPFMTimeFrame(pfmAudioClip:GetTimeFrame())
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("sound_clip")
include("../../time_frame.lua")

sfm.register_element_type("SoundClip")
sfm.link_dmx_type("DmeSoundClip",sfm.SoundClip)

sfm.BaseElement.RegisterProperty(sfm.SoundClip,"sound",sfm.Sound)
sfm.BaseElement.RegisterProperty(sfm.SoundClip,"timeFrame",sfm.TimeFrame)

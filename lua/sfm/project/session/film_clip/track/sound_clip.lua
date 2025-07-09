-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("sound_clip")
include("../../time_frame.lua")

sfm.register_element_type("SoundClip")
sfm.link_dmx_type("DmeSoundClip", sfm.SoundClip)

sfm.BaseElement.RegisterProperty(sfm.SoundClip, "sound", sfm.Sound)
sfm.BaseElement.RegisterProperty(sfm.SoundClip, "timeFrame", sfm.TimeFrame)

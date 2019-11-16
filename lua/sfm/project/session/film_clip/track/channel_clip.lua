--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../../time_frame.lua")
include("../animation_set/control/channel.lua")

sfm.register_element_type("ChannelClip")
sfm.link_dmx_type("DmeChannelsClip",sfm.ChannelClip)

sfm.BaseElement.RegisterProperty(sfm.ChannelClip,"timeFrame",sfm.TimeFrame)
sfm.BaseElement.RegisterArray(sfm.ChannelClip,"channels",sfm.Channel)

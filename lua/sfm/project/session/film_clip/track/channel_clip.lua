-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("../../time_frame.lua")
include("../animation_set/control/channel.lua")

sfm.register_element_type("ChannelClip")
sfm.link_dmx_type("DmeChannelsClip", sfm.ChannelClip)

sfm.BaseElement.RegisterProperty(sfm.ChannelClip, "timeFrame", sfm.TimeFrame)
sfm.BaseElement.RegisterArray(sfm.ChannelClip, "channels", sfm.Channel)

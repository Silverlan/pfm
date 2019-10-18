--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../../time_frame.lua")

util.register_class("sfm.ChannelClip",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.ChannelClip,"timeFrame",sfm.TimeFrame)

function sfm.ChannelClip:__init()
  sfm.BaseElement.__init(self,sfm.ChannelClip)
end

function sfm.ChannelClip:GetType() return "DmeChannelClip" end

function sfm.ChannelClip:ToPFMChannelClip(pfmChannelClip)
  self:GetTimeFrame():ToPFMTimeFrame(pfmChannelClip:GetTimeFrame())
end

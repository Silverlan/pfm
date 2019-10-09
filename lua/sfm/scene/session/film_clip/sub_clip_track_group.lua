--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track.lua")

util.register_class("sfm.SubClipTrackGroup",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.SubClipTrackGroup,"tracks",sfm.Track)

function sfm.SubClipTrackGroup:__init()
  sfm.BaseElement.__init(self,sfm.SubClipTrackGroup)
end

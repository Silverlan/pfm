--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("session")
include("settings.lua")

util.register_class("sfm.Session",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.Session,"settings",sfm.Settings)
sfm.BaseElement.RegisterArray(sfm.Session,"clipBin",sfm.FilmClip)
sfm.BaseElement.RegisterArray(sfm.Session,"miscBin",sfm.FilmClip)

function sfm.Session:__init(elSession)
  sfm.BaseElement.__init(self,sfm.Session)
  self:Load(elSession)
end

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("session")
include("settings.lua")
include("dag.lua")

sfm.register_element_type("Session")

sfm.BaseElement.RegisterProperty(sfm.Session,"settings",sfm.Settings)
sfm.BaseElement.RegisterProperty(sfm.Session,"activeClip",sfm.FilmClip)
sfm.BaseElement.RegisterArray(sfm.Session,"clipBin",sfm.FilmClip)
sfm.BaseElement.RegisterArray(sfm.Session,"miscBin",sfm.FilmClip)

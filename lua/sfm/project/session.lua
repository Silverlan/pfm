-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("session")
include("settings.lua")
include("dag.lua")

sfm.register_element_type("Session")

sfm.BaseElement.RegisterProperty(sfm.Session, "settings", sfm.Settings)
sfm.BaseElement.RegisterProperty(sfm.Session, "activeClip", sfm.FilmClip)
sfm.BaseElement.RegisterArray(sfm.Session, "clipBin", sfm.FilmClip)
sfm.BaseElement.RegisterArray(sfm.Session, "miscBin", sfm.FilmClip)

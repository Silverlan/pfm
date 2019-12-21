--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("film_clip")
include("time_frame.lua")

sfm.register_element_type("FilmClip")
sfm.link_dmx_type("DmeFilmClip",sfm.FilmClip)

sfm.BaseElement.RegisterAttribute(sfm.FilmClip,"mapname","")
sfm.BaseElement.RegisterArray(sfm.FilmClip,"trackGroups",sfm.TrackGroup)
-- sfm.BaseElement.RegisterArray(sfm.FilmClip,"animationSets",sfm.AnimationSet) -- TODO: Obsolete?
sfm.BaseElement.RegisterArray(sfm.FilmClip,"bookmarkSets",sfm.BookmarkSet)
sfm.BaseElement.RegisterAttribute(sfm.FilmClip,"activeBookmarkSet",0)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"subClipTrackGroup",sfm.TrackGroup)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"camera",sfm.Camera)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"timeFrame",sfm.TimeFrame)
sfm.BaseElement.RegisterProperty(sfm.FilmClip,"scene",sfm.Dag)
sfm.BaseElement.RegisterAttribute(sfm.FilmClip,"fadeIn",0.0)
sfm.BaseElement.RegisterAttribute(sfm.FilmClip,"fadeOut",0.0)

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("bookmark.lua")

sfm.register_element_type("BookmarkSet")
sfm.link_dmx_type("DmeBookmarkSet",sfm.BookmarkSet)

sfm.BaseElement.RegisterArray(sfm.BookmarkSet,"bookmarks",sfm.Bookmark)

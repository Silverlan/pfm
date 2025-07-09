-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("bookmark.lua")

sfm.register_element_type("BookmarkSet")
sfm.link_dmx_type("DmeBookmarkSet", sfm.BookmarkSet)

sfm.BaseElement.RegisterArray(sfm.BookmarkSet, "bookmarks", sfm.Bookmark)

-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("Bookmark")
sfm.link_dmx_type("DmeBookmark", sfm.Bookmark)

sfm.BaseElement.RegisterAttribute(sfm.Bookmark, "time", 0)
sfm.BaseElement.RegisterAttribute(sfm.Bookmark, "duration", 0)
sfm.BaseElement.RegisterAttribute(sfm.Bookmark, "note", "")

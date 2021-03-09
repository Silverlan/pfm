--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_bookmark.lua")

fudm.ELEMENT_TYPE_PFM_BOOKMARK_SET = fudm.register_element("PFMBookmarkSet")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_BOOKMARK_SET,"bookmarks",fudm.Array(fudm.ELEMENT_TYPE_PFM_BOOKMARK))

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("MovieSettings")

sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"videoTarget",6)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"clearDecals",false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"stereoscopic",false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"audioTarget",2)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"width",1280)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"stereoSingleFile",false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"height",720)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings,"filename","")

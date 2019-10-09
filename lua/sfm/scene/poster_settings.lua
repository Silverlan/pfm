--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.PosterSettings",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"width",1920)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"constrainAspect",true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"height",1080)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"DPI",300)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"heightInPixels",true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"units",0)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings,"widthInPixels",true)

function sfm.PosterSettings:__init()
  sfm.BaseElement.__init(self,sfm.PosterSettings)
end

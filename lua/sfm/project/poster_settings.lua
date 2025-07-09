-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("PosterSettings")

sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "width", 1920)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "constrainAspect", true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "height", 1080)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "DPI", 300)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "heightInPixels", true)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "units", 0)
sfm.BaseElement.RegisterAttribute(sfm.PosterSettings, "widthInPixels", true)

-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("MovieSettings")

sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "videoTarget", 6)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "clearDecals", false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "stereoscopic", false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "audioTarget", 2)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "width", 1280)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "stereoSingleFile", false)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "height", 720)
sfm.BaseElement.RegisterAttribute(sfm.MovieSettings, "filename", "")

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ProgressiveRefinement")

sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useAntialiasing",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useDepthOfField",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"on",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideDepthOfFieldQuality",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideMotionBlurQuality",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"useMotionBlur",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideDepthOfFieldQualityValue",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideMotionBlurQualityValue",1)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideShutterSpeed",0)
sfm.BaseElement.RegisterAttribute(sfm.ProgressiveRefinement,"overrideShutterSpeedValue",0.0208333)

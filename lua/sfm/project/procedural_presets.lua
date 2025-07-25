-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ProceduralPresets")

sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "jitteriterations", 5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "jitterscale_vector", 2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "jitterscale", 1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "smoothiterations", 5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "smoothscale_vector", 2.5)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "smoothscale", 1)
sfm.BaseElement.RegisterAttribute(sfm.ProceduralPresets, "staggerinterval", 0.0833)

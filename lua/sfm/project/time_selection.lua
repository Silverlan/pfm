-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("TimeSelection")

sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "enabled", false)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "hold_right", 214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "relative", false)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "falloff_left", -214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "interpolator_left", 6)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "falloff_right", 214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "threshold", 0.0005)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "hold_left", -214748)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "interpolator_right", 6)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "resampleinterval", 0.01)
sfm.BaseElement.RegisterAttribute(sfm.TimeSelection, "recordingstate", 3)

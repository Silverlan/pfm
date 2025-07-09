-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("TimeFrame")
sfm.link_dmx_type("DmeTimeFrame", sfm.TimeFrame)

sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "start", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "duration", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "offset", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame, "scale", 1.0)

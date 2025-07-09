-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("control")

sfm.register_element_type("TransformControl")
sfm.link_dmx_type("DmeTransformControl", sfm.TransformControl)

sfm.BaseElement.RegisterAttribute(sfm.TransformControl, "valuePosition", Vector())
sfm.BaseElement.RegisterAttribute(sfm.TransformControl, "valueOrientation", Quaternion())
sfm.BaseElement.RegisterProperty(sfm.TransformControl, "positionChannel", sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.TransformControl, "orientationChannel", sfm.Channel)

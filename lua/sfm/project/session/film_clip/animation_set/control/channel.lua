-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("channel")

sfm.register_element_type("Channel")
sfm.link_dmx_type("DmeChannel", sfm.Channel)

sfm.BaseElement.RegisterProperty(sfm.Channel, "log", sfm.Log)
sfm.BaseElement.RegisterProperty(sfm.Channel, "fromElement")
sfm.BaseElement.RegisterAttribute(sfm.Channel, "fromAttribute", "")
sfm.BaseElement.RegisterProperty(sfm.Channel, "toElement")
sfm.BaseElement.RegisterAttribute(sfm.Channel, "toAttribute", "")
sfm.BaseElement.RegisterProperty(sfm.Channel, "graphCurve", sfm.GraphEditorCurve)

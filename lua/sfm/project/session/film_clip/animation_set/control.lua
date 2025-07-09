-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("control")

sfm.register_element_type("Control")

sfm.BaseElement.RegisterAttribute(sfm.Control, "value")
sfm.BaseElement.RegisterAttribute(sfm.Control, "leftValue")
sfm.BaseElement.RegisterAttribute(sfm.Control, "rightValue")
sfm.BaseElement.RegisterAttribute(sfm.Control, "defaultValue", 0.0)
sfm.BaseElement.RegisterProperty(sfm.Control, "channel", sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.Control, "rightvaluechannel", sfm.Channel, {
	getterName = "GetRightValueChannel",
	setterName = "SetRightValueChannel",
})
sfm.BaseElement.RegisterProperty(sfm.Control, "leftvaluechannel", sfm.Channel, {
	getterName = "GetLeftValueChannel",
	setterName = "SetLeftValueChannel",
})

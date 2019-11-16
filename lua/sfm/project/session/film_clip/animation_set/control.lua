--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("control")

sfm.register_element_type("Control")

sfm.BaseElement.RegisterAttribute(sfm.Control,"value")
sfm.BaseElement.RegisterAttribute(sfm.Control,"leftValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"rightValue")
sfm.BaseElement.RegisterAttribute(sfm.Control,"defaultValue",0.0)
sfm.BaseElement.RegisterProperty(sfm.Control,"channel",sfm.Channel)
sfm.BaseElement.RegisterProperty(sfm.Control,"rightvaluechannel",sfm.Channel,{
	getterName = "GetRightValueChannel",
	setterName = "SetRightValueChannel"
})
sfm.BaseElement.RegisterProperty(sfm.Control,"leftvaluechannel",sfm.Channel,{
	getterName = "GetLeftValueChannel",
	setterName = "SetLeftValueChannel"
})

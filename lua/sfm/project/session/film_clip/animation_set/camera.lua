--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("Camera")
sfm.link_dmx_type("DmeCamera",sfm.Camera)

sfm.register_element_type("Transform") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.Camera,"transform",sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"fieldOfView",36.0)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"znear",3,{
	getterName = "GetZNear",
	setterName = "SetZNear"
})
sfm.BaseElement.RegisterAttribute(sfm.Camera,"zfar",28377.919921875,{
	getterName = "GetZFar",
	setterName = "SetZFar"
})
sfm.BaseElement.RegisterAttribute(sfm.Camera,"focalDistance",72)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"eyeSeparation",0.75)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"aperture",0.2)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"shutterSpeed",0.0208)
sfm.BaseElement.RegisterProperty(sfm.Camera,"overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.Camera,"overridePos")
sfm.BaseElement.RegisterAttribute(sfm.Camera,"overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.Camera,"visible",false,{
	getterName = "IsVisible"
})

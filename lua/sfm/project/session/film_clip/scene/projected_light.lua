--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ProjectedLight")
sfm.link_dmx_type("DmeProjectedLight",sfm.ProjectedLight)

sfm.BaseElement.RegisterProperty(sfm.ProjectedLight,"transform",sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.ProjectedLight,"overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"overridePos")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"color",sfm.Color)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"intensity",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"constantAttenuation",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"linearAttenuation",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"quadraticAttenuation",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"maxDistance",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"horizontalFOV",41.7)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"verticalFOV",41.7)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"visible",false,{
	getterName = "IsVisible"
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"castShadows",false,{
	getterName = "ShouldCastShadows"
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"volumetric",false,{
	getterName = "IsVolumetric"
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"volumetricIntensity",1.0)

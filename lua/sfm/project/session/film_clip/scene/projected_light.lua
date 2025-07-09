-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ProjectedLight")
sfm.link_dmx_type("DmeProjectedLight", sfm.ProjectedLight)

sfm.BaseElement.RegisterProperty(sfm.ProjectedLight, "transform", sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.ProjectedLight, "overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "overridePos")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "color", sfm.Color)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "intensity", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "constantAttenuation", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "linearAttenuation", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "quadraticAttenuation", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "maxDistance", 0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "horizontalFOV", 41.7)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "verticalFOV", 41.7)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "visible", false, {
	getterName = "IsVisible",
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "castShadows", false, {
	getterName = "ShouldCastShadows",
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "volumetric", false, {
	getterName = "IsVolumetric",
})
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight, "volumetricIntensity", 1.0)

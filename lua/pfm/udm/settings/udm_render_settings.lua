--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")

udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS = udm.register_element("PFMRenderSettings")

udm.PFMRenderSettings.VIEWPORT_MODE_FLAT = 0
udm.PFMRenderSettings.VIEWPORT_MODE_360_LEFT_EYE = 1
udm.PFMRenderSettings.VIEWPORT_MODE_360_RIGHT_EYE = 2

udm.PFMRenderSettings.MODE_COMBINED = 0
udm.PFMRenderSettings.MODE_ALBEDO = 1
udm.PFMRenderSettings.MODE_NORMALS = 2
udm.PFMRenderSettings.MODE_DEPTH = 3
udm.PFMRenderSettings.MODE_ALPHA = 4
udm.PFMRenderSettings.MODE_GEOMETRY_NORMAL = 5
udm.PFMRenderSettings.MODE_SHADING_NORMAL = 6
udm.PFMRenderSettings.MODE_DIRECT_DIFFUSE = 7
udm.PFMRenderSettings.MODE_DIRECT_DIFFUSE_REFLECT = 8
udm.PFMRenderSettings.MODE_DIRECT_DIFFUSE_TRANSMIT = 9
udm.PFMRenderSettings.MODE_DIRECT_GLOSSY = 10
udm.PFMRenderSettings.MODE_DIRECT_GLOSSY_REFLECT = 11
udm.PFMRenderSettings.MODE_DIRECT_GLOSSY_TRANSMIT = 12
udm.PFMRenderSettings.MODE_EMISSION = 13
udm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE = 14
udm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE_REFLECT = 15
udm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE_TRANSMIT = 16
udm.PFMRenderSettings.MODE_INDIRECT_GLOSSY = 17
udm.PFMRenderSettings.MODE_INDIRECT_GLOSSY_REFLECT = 18
udm.PFMRenderSettings.MODE_INDIRECT_GLOSSY_TRANSMIT = 19
udm.PFMRenderSettings.MODE_INDIRECT_SPECULAR = 20
udm.PFMRenderSettings.MODE_INDIRECT_SPECULAR_REFLECT = 21
udm.PFMRenderSettings.MODE_INDIRECT_SPECULAR_TRANSMIT = 22
udm.PFMRenderSettings.MODE_UV = 23
udm.PFMRenderSettings.MODE_IRRADIANCE = 24
udm.PFMRenderSettings.MODE_NOISE = 25
udm.PFMRenderSettings.MODE_CAUSTIC = 26

udm.PFMRenderSettings.DEVICE_TYPE_CPU = 0
udm.PFMRenderSettings.DEVICE_TYPE_GPU = 1

udm.PFMRenderSettings.PREVIEW_QUALITY_LOW = 0
udm.PFMRenderSettings.PREVIEW_QUALITY_MEDIUM = 1
udm.PFMRenderSettings.PREVIEW_QUALITY_HIGH = 2

udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"frameRate",udm.Int(24))

udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"mode",udm.Int(udm.PFMRenderSettings.MODE_COMBINED))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderEngine",udm.String("cycles"))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"preset",udm.String("standard"))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"deviceType",udm.Int(udm.PFMRenderSettings.DEVICE_TYPE_GPU))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"samples",udm.Int(40))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"width",udm.Int(1920))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"height",udm.Int(1080))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"sky",udm.String("skies/dusk379.hdr"))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"skyStrength",udm.Float(0.3))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"skyYawAngle",udm.Float(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"maxTransparencyBounces",udm.Int(128))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"lightIntensityFactor",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"emissionStrength",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"numberOfFrames",udm.Int(1))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"colorTransform",udm.String("filmic-blender"))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"colorTransformLook",udm.String("Medium Contrast"))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"outputFormat",udm.Int(util.IMAGE_FORMAT_PNG))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"denoise",udm.Bool(true),{
	getter = "ShouldDenoise"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderWorld",udm.Bool(true),{
	getter = "ShouldRenderWorld"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderGameObjects",udm.Bool(true),{
	getter = "ShouldRenderGameObjects"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderPlayer",udm.Bool(false),{
	getter = "ShouldRenderPlayer"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"cameraFrustumCullingEnabled",udm.Bool(true),{
	getter = "IsCameraFrustumCullingEnabled"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"pvsCullingEnabled",udm.Bool(true),{
	getter = "IsPvsCullingEnabled"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"progressive",udm.Bool(true),{
	getter = "IsProgressive"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"progressiveRefinementEnabled",udm.Bool(false),{
	getter = "IsProgressiveRefinementEnabled"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"transparentSky",udm.Bool(false),{
	getter = "ShouldMakeSkyTransparent"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"exposure",udm.Float(50))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"previewQuality",udm.Int(udm.PFMRenderSettings.PREVIEW_QUALITY_LOW))

udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"cameraType",udm.Int(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"panoramaType",udm.Int(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"stereoscopic",udm.Bool(true),{
	getter = "IsStereoscopic"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"viewportMode",udm.Int(udm.PFMRenderSettings.VIEWPORT_MODE_360_LEFT_EYE))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"panoramaRange",udm.Float(180))

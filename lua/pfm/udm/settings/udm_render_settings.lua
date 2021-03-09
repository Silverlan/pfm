--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/raytracing_render_job.lua")

fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS = fudm.register_element("PFMRenderSettings")

fudm.PFMRenderSettings.VIEWPORT_MODE_FLAT = 0
fudm.PFMRenderSettings.VIEWPORT_MODE_360_LEFT_EYE = 1
fudm.PFMRenderSettings.VIEWPORT_MODE_360_RIGHT_EYE = 2

fudm.PFMRenderSettings.MODE_COMBINED = 0
fudm.PFMRenderSettings.MODE_ALBEDO = 1
fudm.PFMRenderSettings.MODE_NORMALS = 2
fudm.PFMRenderSettings.MODE_DEPTH = 3
fudm.PFMRenderSettings.MODE_ALPHA = 4
fudm.PFMRenderSettings.MODE_GEOMETRY_NORMAL = 5
fudm.PFMRenderSettings.MODE_SHADING_NORMAL = 6
fudm.PFMRenderSettings.MODE_DIRECT_DIFFUSE = 7
fudm.PFMRenderSettings.MODE_DIRECT_DIFFUSE_REFLECT = 8
fudm.PFMRenderSettings.MODE_DIRECT_DIFFUSE_TRANSMIT = 9
fudm.PFMRenderSettings.MODE_DIRECT_GLOSSY = 10
fudm.PFMRenderSettings.MODE_DIRECT_GLOSSY_REFLECT = 11
fudm.PFMRenderSettings.MODE_DIRECT_GLOSSY_TRANSMIT = 12
fudm.PFMRenderSettings.MODE_EMISSION = 13
fudm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE = 14
fudm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE_REFLECT = 15
fudm.PFMRenderSettings.MODE_INDIRECT_DIFFUSE_TRANSMIT = 16
fudm.PFMRenderSettings.MODE_INDIRECT_GLOSSY = 17
fudm.PFMRenderSettings.MODE_INDIRECT_GLOSSY_REFLECT = 18
fudm.PFMRenderSettings.MODE_INDIRECT_GLOSSY_TRANSMIT = 19
fudm.PFMRenderSettings.MODE_INDIRECT_SPECULAR = 20
fudm.PFMRenderSettings.MODE_INDIRECT_SPECULAR_REFLECT = 21
fudm.PFMRenderSettings.MODE_INDIRECT_SPECULAR_TRANSMIT = 22
fudm.PFMRenderSettings.MODE_UV = 23
fudm.PFMRenderSettings.MODE_IRRADIANCE = 24
fudm.PFMRenderSettings.MODE_NOISE = 25
fudm.PFMRenderSettings.MODE_CAUSTIC = 26

fudm.PFMRenderSettings.DEVICE_TYPE_CPU = 0
fudm.PFMRenderSettings.DEVICE_TYPE_GPU = 1

fudm.PFMRenderSettings.PREVIEW_QUALITY_LOW = 0
fudm.PFMRenderSettings.PREVIEW_QUALITY_MEDIUM = 1
fudm.PFMRenderSettings.PREVIEW_QUALITY_HIGH = 2

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"frameRate",fudm.Int(24))

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"mode",fudm.Int(fudm.PFMRenderSettings.MODE_COMBINED))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderEngine",fudm.String("cycles"))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"preset",fudm.String("standard"))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"deviceType",fudm.Int(fudm.PFMRenderSettings.DEVICE_TYPE_GPU))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"samples",fudm.Int(40))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"width",fudm.Int(1920))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"height",fudm.Int(1080))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"sky",fudm.String("skies/dusk379.hdr"))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"skyStrength",fudm.Float(0.3))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"skyYawAngle",fudm.Float(0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"maxTransparencyBounces",fudm.Int(128))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"lightIntensityFactor",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"emissionStrength",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"numberOfFrames",fudm.Int(1))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"colorTransform",fudm.String("filmic-blender"))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"colorTransformLook",fudm.String("Medium Contrast"))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"outputFormat",fudm.Int(util.IMAGE_FORMAT_PNG))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"denoise",fudm.Bool(true),{
	getter = "ShouldDenoise"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderWorld",fudm.Bool(true),{
	getter = "ShouldRenderWorld"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderGameObjects",fudm.Bool(true),{
	getter = "ShouldRenderGameObjects"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"renderPlayer",fudm.Bool(false),{
	getter = "ShouldRenderPlayer"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"cameraFrustumCullingEnabled",fudm.Bool(true),{
	getter = "IsCameraFrustumCullingEnabled"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"pvsCullingEnabled",fudm.Bool(true),{
	getter = "IsPvsCullingEnabled"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"progressive",fudm.Bool(true),{
	getter = "IsProgressive"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"progressiveRefinementEnabled",fudm.Bool(false),{
	getter = "IsProgressiveRefinementEnabled"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"transparentSky",fudm.Bool(false),{
	getter = "ShouldMakeSkyTransparent"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"exposure",fudm.Float(50))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"previewQuality",fudm.Int(fudm.PFMRenderSettings.PREVIEW_QUALITY_LOW))

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"cameraType",fudm.Int(pfm.RaytracingRenderJob.Settings.CAM_TYPE_PERSPECTIVE))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"panoramaType",fudm.Int(pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"stereoscopic",fudm.Bool(true),{
	getter = "IsStereoscopic"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"viewportMode",fudm.Int(fudm.PFMRenderSettings.VIEWPORT_MODE_360_LEFT_EYE))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RENDER_SETTINGS,"panoramaRange",fudm.Float(180))

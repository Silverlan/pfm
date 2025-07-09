-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("render_settings")

sfm.register_element_type("RenderSettings")

sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "frameRate", 24)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "drawToolRenderablesMask", 15)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "engineCameraEffects", false)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "lightAverage", 0)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "toneMapScale", 1.0)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "modelLod", 0)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "ambientOcclusionMode", 1)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "showAmbientOcclusion", 0)
sfm.BaseElement.RegisterAttribute(sfm.RenderSettings, "drawGameRenderablesMask", 216)
sfm.BaseElement.RegisterProperty(sfm.RenderSettings, "ProgressiveRefinement", sfm.ProgressiveRefinement)

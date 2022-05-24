--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.bake = pfm.bake or {}

pfm.bake.lightmaps = function(lightmapTargets,lightSources,width,height,sampleCount)
	local createInfo = unirender.Scene.CreateInfo()
	createInfo.renderer = "cycles"
	createInfo.width = width
	createInfo.height = height
	createInfo.denoise = true
	createInfo.hdrOutput = true
	createInfo.renderJob = false
	createInfo.exposure = 1.0
	-- createInfo.colorTransform = colorTransform
	createInfo.device = unirender.Scene.DEVICE_TYPE_GPU
	createInfo.globalLightIntensityFactor = 1.0
	-- createInfo.sky = skyTex
	createInfo.skyAngles = EulerAngles(0,0,0)
	createInfo.skyStrength = 1.0
	createInfo.renderer = "cycles"
	createInfo:SetSamplesPerPixel(sampleCount)

	unirender.PBRShader.set_global_renderer_identifier(createInfo.renderer)

	local scene = unirender.create_scene(unirender.Scene.RENDER_MODE_BAKE_DIFFUSE_LIGHTING,createInfo)
	scene:SetSkyAngles(EulerAngles(0,0,0))
	scene:SetSkyTransparent(false)
	scene:SetSkyStrength(1)
	scene:SetEmissionStrength(1)
	scene:SetMaxTransparencyBounces(10)
	scene:SetMaxDiffuseBounces(4)
	scene:SetMaxGlossyBounces(4)
	scene:SetLightIntensityFactor(1)
	scene:SetResolution(width,height)

	for _,ent in ipairs(lightmapTargets) do
		scene:AddLightmapBakeTarget(ent)
	end
	for _,ent in ipairs(lightSources) do
		scene:AddLightSource(ent)
	end

	scene:Finalize()
	local flags = unirender.Renderer.FLAG_NONE
	local renderer = unirender.create_renderer(scene,createInfo.renderer,flags)
	if(renderer == nil) then
		pfm.log("Unable to create renderer for render engine '" .. renderSettings:GetRenderEngine() .. "'!",pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local apiData = renderer:GetApiData()

	return renderer:StartRender()
end

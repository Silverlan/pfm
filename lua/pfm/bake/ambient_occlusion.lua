--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.bake = pfm.bake or {}

pfm.bake.ambient_occlusion = function(mdl,matIdx,width,height,samples)
	local createInfo = unirender.Scene.CreateInfo()
	createInfo.renderer = "cycles"
	createInfo:SetSamplesPerPixel(samples)

	unirender.PBRShader.set_global_renderer_identifier(createInfo.renderer)

	local scene = unirender.create_scene(unirender.Scene.RENDER_MODE_BAKE_AMBIENT_OCCLUSION,createInfo)
	scene:SetSkyAngles(EulerAngles(0,0,0))
	scene:SetSkyTransparent(true)
	scene:SetSkyStrength(1)
	scene:SetEmissionStrength(1)
	scene:SetMaxTransparencyBounces(10)
	scene:SetMaxDiffuseBounces(4)
	scene:SetMaxGlossyBounces(4)
	scene:SetLightIntensityFactor(1)
	scene:SetResolution(width,height)
	scene:SetAoBakeTarget(mdl,matIdx)

	--[[local gameScene = game.get_scene()
	local cam = gameScene:GetActiveCamera()
	local pos = cam:GetEntity():GetPos()
	local rot = cam:GetEntity():GetRotation()
	local nearZ = cam:GetNearZ()
	local farZ = cam:GetFarZ()
	local fov = cam:GetFOV()
	local vp = cam:GetProjectionMatrix() *cam:GetViewMatrix()
	local sceneFlags = unirender.Scene.SCENE_FLAG_NONE
	scene:InitializeFromGameScene(gameScene,pos,rot,vp,nearZ,farZ,fov,sceneFlags,function(ent)
		if(ent:IsPlayer()) then return false end
		return false
	end,function(ent)
		return true
	end)]]

	scene:Finalize()
	local flags = unirender.Renderer.FLAG_NONE
	local renderer,err = unirender.create_renderer(scene,createInfo.renderer,flags)
	if(renderer == false) then
		pfm.log("Unable to create renderer for render engine '" .. renderSettings:GetRenderEngine() .. "': " .. err .. "!",pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local apiData = renderer:GetApiData()

	return renderer:StartRender()
end

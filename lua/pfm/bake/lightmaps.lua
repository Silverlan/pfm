--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.bake = pfm.bake or {}

pfm.bake.find_bake_entities = function()
	local session = tool.get_filmmaker():GetSession()
	if(session == nil) then return {} end
	local actorMap = {}
	for _,actor in ipairs(session:GetActiveClip():GetActorList()) do
		if(actor:HasComponent("model") and actor:HasComponent("light_map_receiver")) then
			actorMap[actor] = true
		end
	end

	-- We want all inanimate actors
	local entities = ents.get_all(ents.citerator(ents.COMPONENT_PFM_ACTOR,{ents.IteratorFilterFunction(function(ent,c)
		local actorData = c:GetActorData()
		return actorData ~= nil and actorMap[actorData] ~= nil
	end)}))

	-- Also include all inanimate map entities
	-- TODO: Include static props that are not lightmapped by default?
	for ent,c in ents.citerator(ents.COMPONENT_MAP,{ents.IteratorFilterComponent(ents.COMPONENT_MODEL)}) do
		if((ent:HasComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER) or ent:HasComponent(ents.COMPONENT_LIGHT_MAP)) and ent:HasComponent(ents.COMPONENT_PFM_ACTOR) == false and ent:IsInert()) then
			local physC = ent:GetComponent(ents.COMPONENT_PHYSICS)
			if(physC == nil or physC:GetPhysicsType() == phys.TYPE_STATIC) then
				table.insert(entities,ent)
			end
		end
	end
	return entities
end

pfm.bake.find_bake_light_sources = function()
	return ents.get_all(ents.citerator(ents.COMPONENT_LIGHT,{ents.IteratorFilterFunction(function(ent,c) return c:IsBaked() end)}))
end

pfm.bake.directional_lightmaps = function(lightmapTargets,lightSources,width,height,lightmapDataCache)
	local meshes = {}
	local entUuids = {}
	for _,ent in ipairs(lightmapTargets) do
		local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		if(renderC ~= nil) then
			for _,subMesh in ipairs(renderC:GetRenderMeshes()) do
				table.insert(meshes,subMesh)
				table.insert(entUuids,ent:GetUuid())
			end
		end
	end

	return util.bake_directional_lightmap_atlas(lightSources,meshes,entUuids,width,height,lightmapDataCache)
end

pfm.bake.lightmaps = function(lightmapTargets,lightSources,width,height,sampleCount,lightmapDataCache,initScene,bakeCombined)
	if(bakeCombined == nil) then bakeCombined = true end
	local createInfo = unirender.Scene.CreateInfo()
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
	unirender.PBRShader.set_global_bake_diffuse_lighting(true)

	local scene = unirender.create_scene(bakeCombined and unirender.Scene.RENDER_MODE_BAKE_DIFFUSE_LIGHTING or unirender.Scene.RENDER_MODE_BAKE_DIFFUSE_LIGHTING_SEPARATE,createInfo)
	scene:SetSkyAngles(EulerAngles(0,0,0))
	scene:SetSkyTransparent(false)
	scene:SetSkyStrength(1)
	scene:SetEmissionStrength(1)
	scene:SetMaxTransparencyBounces(10)
	scene:SetMaxDiffuseBounces(4)
	scene:SetMaxGlossyBounces(4)
	scene:SetLightIntensityFactor(1)
	scene:SetResolution(width,height)
	if(lightmapDataCache ~= nil) then scene:SetLightmapDataCache(lightmapDataCache) end -- Has to be set before adding any bake targets!

	for _,ent in ipairs(lightmapTargets) do
		scene:AddLightmapBakeTarget(ent)
	end
	for _,ent in ipairs(lightSources) do
		scene:AddLightSource(ent)
	end
	if(initScene ~= nil) then initScene(scene) end
	scene:Finalize()
	unirender.PBRShader.set_global_bake_diffuse_lighting(false)
	local flags = unirender.Renderer.FLAG_NONE
	local renderer = unirender.create_renderer(scene,createInfo.renderer,flags)
	if(renderer == nil) then
		pfm.log("Unable to create renderer for render engine '" .. renderSettings:GetRenderEngine() .. "'!",pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local apiData = renderer:GetApiData()
	apiData:GetFromPath("cycles"):SetValue("adaptiveSamplingThreshold",udm.TYPE_FLOAT,0.001)
	return renderer:StartRender()
end

local LightmapBaker = util.register_class("pfm.bake.LightmapBaker",util.CallbackHandler)
function LightmapBaker:__init()
	util.CallbackHandler.__init(self)
end
function LightmapBaker:BakeUvs(lmEntity,cachePath)
	local lightmapReceivers = pfm.bake.find_bake_entities()
	if(util.bake_lightmap_uvs(lmEntity,lightmapReceivers,cachePath) == false) then return false end
	return true
end
function LightmapBaker:Start(width,height,sampleCount,lightmapDataCache,initScene,bakeCombined)
	local lightmapReceivers = pfm.bake.find_bake_entities()

	-- Only include baked light sources
	local lightSources = pfm.bake.find_bake_light_sources()

	local job = pfm.bake.lightmaps(lightmapReceivers,lightSources,width,height,sampleCount,lightmapDataCache,initScene,bakeCombined)
	if(job == nil) then return false end
	job:Start()
	self.m_job = job
	return true
end
function LightmapBaker:Poll()
	self.m_job:Poll()
end
function LightmapBaker:IsComplete() return self.m_job:IsComplete() end
function LightmapBaker:IsSuccessful() return self.m_job:IsSuccessful() end
function LightmapBaker:GetProgress() return self.m_job:GetProgress() end
function LightmapBaker:GetResult() return self.m_job:GetResult() end
function LightmapBaker:Clear()
	if(self.m_job ~= nil) then
		self.m_job:Cancel()
		self.m_job = nil
	end
end

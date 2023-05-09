--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.bake = pfm.bake or {}

local function find_bake_entities()
	local session = tool.get_filmmaker():GetSession()
	if session == nil then
		return {}
	end

	-- We want all inanimate actors
	local entities = ents.get_all(ents.citerator(ents.COMPONENT_PFM_ACTOR, {
		ents.IteratorFilterComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER),
		ents.IteratorFilterComponent(ents.COMPONENT_MODEL),
		ents.IteratorFilterFunction(function(ent, c)
			local actorData = c:GetActorData()
			return actorData ~= nil
		end),
	}))

	-- Also include all inanimate map entities
	for ent, c in ents.citerator(ents.COMPONENT_MAP, { ents.IteratorFilterComponent(ents.COMPONENT_MODEL) }) do
		if ent:HasComponent(ents.COMPONENT_PFM_ACTOR) == false and ent:IsInert() then
			local physC = ent:GetComponent(ents.COMPONENT_PHYSICS)
			if physC == nil or physC:GetPhysicsType() == phys.TYPE_STATIC then
				table.insert(entities, ent)
			end
		end
	end
	return entities
end

pfm.bake.ibl = function(pose, gameScene, lightSources, width, height, sampleCount, initScene)
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
	createInfo.skyAngles = EulerAngles(0, 0, 0)
	createInfo.skyStrength = 1.0
	createInfo.renderer = "cycles"
	createInfo:SetSamplesPerPixel(sampleCount)

	unirender.PBRShader.set_global_renderer_identifier(createInfo.renderer)

	local scene = unirender.create_scene(unirender.Scene.RENDER_MODE_COMBINED, createInfo)
	scene:SetSkyAngles(EulerAngles(0, 0, 0))
	scene:SetSkyTransparent(false)
	scene:SetSkyStrength(1)
	scene:SetEmissionStrength(1)
	scene:SetMaxTransparencyBounces(10)
	scene:SetMaxDiffuseBounces(4)
	scene:SetMaxGlossyBounces(4)
	scene:SetLightIntensityFactor(1)
	scene:SetResolution(width, height)

	local tEnts = find_bake_entities()
	-- print("Bake entities:")
	-- console.print_table(tEnts)
	-- print("Light sources:")
	-- console.print_table(lightSources)
	local entityMap = table.table_to_map(tEnts, true)

	local ent = ents.create("unirender")
	util.remove(ent, true)
	local unirenderC = ent:AddComponent("unirender")

	unirenderC:InvokeEventCallbacks(ents.UnirenderComponent.EVENT_INITIALIZE_SCENE, { scene, renderSettings })
	local entSky, skyC = ents.citerator(ents.COMPONENT_PFM_SKY)()
	if skyC ~= nil then
		skyC:ApplySceneSkySettings(scene)
	end

	local nearZ = 1.0
	local farZ = 32768.0
	local fov = 90.0
	local sceneFlags = unirender.Scene.SCENE_FLAG_NONE
	scene:InitializeFromGameScene(
		gameScene,
		pose:GetOrigin(),
		pose:GetRotation(),
		Mat4(1.0),
		nearZ,
		farZ,
		fov,
		sceneFlags,
		function(ent)
			return entityMap[ent] ~= nil
		end,
		function(ent)
			return false
		end
	)
	local cam = scene:GetCamera()
	cam:SetEquirectangularHorizontalRange(360.0)
	cam:SetEquirectangularVerticalRange(180.0)
	cam:SetRotation(Quaternion())
	cam:SetCameraType(unirender.Camera.TYPE_PANORAMA)
	cam:SetPanoramaType(unirender.Camera.PANORAMA_TYPE_EQUIRECTANGULAR)
	for _, ent in ipairs(lightSources) do
		scene:AddLightSource(ent)
	end
	if initScene ~= nil then
		initScene(scene)
	end

	scene:Finalize()
	local flags = unirender.Renderer.FLAG_NONE
	local renderer, err = unirender.create_renderer(scene, createInfo.renderer, flags)
	if renderer == false then
		pfm.log(
			"Unable to create renderer for render engine '" .. renderSettings:GetRenderEngine() .. "': " .. err .. "!",
			pfm.LOG_CATEGORY_PFM_RENDER,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	local apiData = renderer:GetApiData()

	return renderer:StartRender()
end

local ReflectionProbeBaker = util.register_class("pfm.bake.ReflectionProbeBaker", util.CallbackHandler)
function ReflectionProbeBaker:__init(actorData, entActor)
	util.CallbackHandler.__init(self)
	self.m_actorData = actorData
	self.m_actorEntity = entActor
end
function ReflectionProbeBaker:GetActorData()
	return self.m_actorData
end
function ReflectionProbeBaker:GetActorEntity()
	return self.m_actorEntity
end
function ReflectionProbeBaker:Start()
	local reflC = self.m_actorEntity:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
	local actorC = self.m_actorEntity:GetComponent(ents.COMPONENT_PFM_ACTOR)

	local matPath = util.Path.CreateFilePath(reflC:GetIBLMaterialFilePath())
	matPath:PopFront()
	local curIblMaterial = game.load_material(matPath:GetString())
	if util.is_valid(curIblMaterial) then
		local data = curIblMaterial:GetDataBlock()
		local generated = data:GetBool("generated", false)
		if generated then
			-- Delete old material and textures
			local prefilter = data:GetString("prefilter")
			if prefilter ~= nil then
				asset.delete(prefilter, asset.TYPE_TEXTURE)
			end

			local irradiance = data:GetString("irradiance")
			if irradiance ~= nil then
				asset.delete(irradiance, asset.TYPE_TEXTURE)
			end
		end
	end

	local pm = pfm.get_project_manager()
	local session = pm:GetProject():GetSession()
	local uuid = tostring(session:GetUniqueId())
	local matPath = "projects/" .. uuid .. "/" .. reflC:GetLocationIdentifier()
	pm:SetActorGenericProperty(actorC, "ec/reflection_probe/iblMaterial", matPath)
	local c = self.m_actorData:FindComponent("reflection_probe")
	if c ~= nil then
		c:SetMemberValue("iblMaterial", udm.TYPE_STRING, matPath)
	end

	local sampleCount = 40
	local width = 512
	local height = 512
	local pose = self.m_actorEntity:GetPose()

	-- Only include baked light sources
	local lightSources =
		ents.get_all(ents.citerator(
			ents.COMPONENT_LIGHT,
			{ ents.IteratorFilterFunction(function(ent, c)
				return c:IsBaked()
			end) }
		))

	local job = pfm.bake.ibl(pose, game.get_scene(), lightSources, width, height, sampleCount)
	job:Start()
	self.m_job = job
end
function ReflectionProbeBaker:Poll()
	self.m_job:Poll()
end
function ReflectionProbeBaker:IsComplete()
	return self.m_job:IsComplete()
end
function ReflectionProbeBaker:IsSuccessful()
	return self.m_job:IsSuccessful()
end
function ReflectionProbeBaker:GetProgress()
	return self.m_job:GetProgress()
end
function ReflectionProbeBaker:GetResult()
	return self.m_job:GetResult()
end
function ReflectionProbeBaker:Clear()
	if self.m_job ~= nil then
		self.m_job:Cancel()
		self.m_job = nil
	end
end

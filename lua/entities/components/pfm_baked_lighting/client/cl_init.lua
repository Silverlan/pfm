--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/bake/lightmaps.lua")

local Component = util.register_class("ents.PFMBakedLighting",BaseEntityComponent)
Component:RegisterMember("LightmapMode",udm.TYPE_UINT32,1,{
	enumValues = {
		["NonDirectional"] = 0,
		["Directional"] = 1
	}
})
-- Debug mode
Component:RegisterMember("Resolution",udm.TYPE_STRING,"2048x2048")
Component:RegisterMember("SampleCount",udm.TYPE_UINT32,20000)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_baker = pfm.bake.LightmapBaker()

	self:AddEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
	self:AddEntityComponent("pfm_cuboid_bounds")
end
function Component:OnRemove()
	self.m_baker:Clear()
end
function Component:OnEntitySpawn()
	self.m_lightmapUvCacheDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:UpdateLightmapData(tEnts)
	for _,ent in ipairs(tEnts) do
		local lightMapReceiver = ent:AddComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
		lightMapReceiver:UpdateLightmapUvData()
	end

	local ent = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_LIGHT_MAP)})()
	if(ent ~= nil) then
		local lightmapC = ent:GetComponent(ents.COMPONENT_LIGHT_MAP)
		lightmapC:ReloadLightmapData()
	end
end
function Component:FindLightmapEntities()
	local it = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_MODEL),ents.IteratorFilterComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)})
	return ents.get_all(it)
end
function Component:FindLightSourceEntities()
	local it = ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_LIGHT)})
	local t = {}
	for ent in it do
		if(ent:IsTurnedOn()) then
			local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
			if(lightC:IsBaked()) then
				table.insert(t,ent)
			end
		end
	end
	return t
end
function Component:SetLightmapUvCacheDirty()
	self.m_lightmapUvCacheDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:SetLightmapAtlasDirty()
	self.m_lightmapAtlasDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:GetLightmapJob() return self.m_lightmapJob end
function Component:ImportLightmapTexture(matIdentifier,texName,importTex)
	local ext = file.get_file_extension(importTex)
	if(ext ~= nil and ext ~= "dds" and ext ~= "ktx") then
		local img = util.load_image(importTex,false,util.ImageBuffer.FORMAT_RGBA32)
		if(img == nil) then return end
		local newTexPath = file.remove_file_extension(importTex)
		if(self:SaveLightmapImage(img,newTexPath) == false) then return end
		return self:ImportLightmapTexture(matIdentifier,texName,newTexPath .. ".dds")
	end

	local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC == nil) then return end
	local matName = lightmapC:GetMemberValue("lightmapMaterial")
	if(#matName == 0) then
		local pm = pfm.get_project_manager()
		local session = pm:GetProject():GetSession()
		local uuid = tostring(session:GetUniqueId())
		local path = "projects/" .. uuid .. "/"
		file.create_path("materials/" .. path)
		matName = path .. "lightmap"
	end

	matName = asset.get_normalized_path(matName,asset.TYPE_MATERIAL)
	local mat = game.load_material(matName)
	if(mat == nil) then
		mat = game.create_material(matName,"lightmap")
	end

	local path = file.get_file_path(matName)
	local texPath = path .. texName
	texPath = file.remove_file_extension(texPath,{"dds"}) .. ".dds"

	local absPath = asset.get_asset_root_directory(asset.TYPE_MATERIAL) .. "/" .. texPath
	local res = file.copy(importTex,absPath)

	pfm.log("Baked texture '" .. texPath .. "' imported as '" .. matIdentifier .. "' for material '" .. matName .. "'!",pfm.LOG_CATEGORY_PFM_BAKE)
	asset.reload(texPath,asset.TYPE_TEXTURE)
	mat:SetTexture(matIdentifier,texPath)

	-- Update property
	local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC ~= nil) then
		lightmapC:SetMemberValue("lightmapMaterial",mat:GetName())
	end

	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if(actorC ~= nil) then
		local pm = pfm.get_project_manager()
		pm:SetActorGenericProperty(actorC,"ec/light_map/lightmapMaterial",mat:GetName(),udm.TYPE_STRING)
	end

	-- Save material
	mat:UpdateTextures()
	mat:InitializeShaderDescriptorSet()
	mat:SetLoaded(true)
	mat:Save()
	self:SetLightmapUvCacheDirty()
	self:SetLightmapAtlasDirty()
	return mat
end
function Component:SaveLightmapImage(img,texPath)
	local texInfo = util.TextureInfo()
	texInfo.inputFormat = util.TextureInfo.INPUT_FORMAT_R32G32B32A32_FLOAT
	texInfo.outputFormat = normalMap and util.TextureInfo.OUTPUT_FORMAT_BC3 or util.TextureInfo.OUTPUT_FORMAT_BC6
	texInfo.containerFormat = util.TextureInfo.CONTAINER_FORMAT_DDS
	texInfo.flags = bit.bor(texInfo.flags,util.TextureInfo.FLAG_BIT_GENERATE_MIPMAPS)

	img:Convert(util.ImageBuffer.FORMAT_RGBA32)
	return util.save_image(img,texPath .. ".dds",texInfo)
end
function Component:SaveLightmapTexture(jobResult,resultIdentifier,matIdentifier,texName,normalMap)
	local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC == nil) then return end
	local matName = lightmapC:GetMemberValue("lightmapMaterial")
	if(#matName == 0) then
		local pm = pfm.get_project_manager()
		local session = pm:GetProject():GetSession()
		local uuid = tostring(session:GetUniqueId())
		local path = "projects/" .. uuid .. "/"
		file.create_path("materials/" .. path)
		matName = path .. "lightmap"
	end

	matName = asset.get_normalized_path(matName,asset.TYPE_MATERIAL)
	local mat = game.load_material(matName)
	if(mat == nil) then
		mat = game.create_material(matName,"lightmap")
	end

	local img
	if(type(resultIdentifier) == "string") then img = jobResult:GetImage(resultIdentifier)
	else img = resultIdentifier end
	if(img == nil) then
		pfm.log("Baked texture '" .. matIdentifier .. "' not found, ignoring...",pfm.LOG_CATEGORY_PFM_BAKE)
		return
	end

	local path = file.get_file_path(matName)
	local texPath = path .. texName
	local r = self:SaveLightmapImage(img,asset.get_asset_root_directory(asset.TYPE_MATERIAL) .. "/" .. texPath)
	if(r) then
		pfm.log("Baked texture '" .. matIdentifier .. "' saved as '" .. texPath .. "'!",pfm.LOG_CATEGORY_PFM_BAKE)
		asset.reload(texPath,asset.TYPE_TEXTURE)
		mat:SetTexture(matIdentifier,texPath)
	else
		pfm.log("Failed to save baked texture '" .. matIdentifier .. "' as '" .. texPath .. "'!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
	end
	return mat
end
function Component:OnTick(dt)
	if(self.m_lightmapJob ~= nil) then
		self.m_lightmapJob:Poll()
		if(self.m_lightmapJob:IsComplete()) then
			if(self.m_lightmapJob:IsSuccessful()) then
				local result = self.m_lightmapJob:GetResult()
				local mat = self:SaveLightmapTexture(result,"DIFFUSE","diffuse_map","lightmap_diffuse")
				if(mat == nil) then
					mat = self:SaveLightmapTexture(result,"DIFFUSE_DIRECT","diffuse_direct_map","lightmap_diffuse_direct")
					self:SaveLightmapTexture(result,"DIFFUSE_INDIRECT","diffuse_indirect_map","lightmap_diffuse_indirect")
					if(mat ~= nil) then mat:GetDataBlock():RemoveValue("diffuse_map") end
				else
					mat:GetDataBlock():RemoveValue("diffuse_direct_map")
					mat:GetDataBlock():RemoveValue("diffuse_indirect_map")
				end

				if(mat ~= nil) then
					mat:UpdateTextures()
					mat:InitializeShaderDescriptorSet()
					mat:SetLoaded(true)
					if(mat:Save() == false) then
						pfm.log("Failed to save lightmap atlas material as '" .. mat:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
					else
						local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
						if(lightmapC ~= nil) then
							lightmapC:SetMemberValue("lightmapMaterial",mat:GetName())
						end

						local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
						if(actorC ~= nil) then
							local pm = pfm.get_project_manager()
							pm:SetActorGenericProperty(actorC,"ec/light_map/lightmapMaterial",mat:GetName(),udm.TYPE_STRING)
						end
					end
				end
			else
				print("Lightmap baking error: ",self.m_lightmapJob:GetResultMessage())
			end
			self.m_lightmapJob = nil
		end
	end
	if(self.m_dirLightmapJob ~= nil) then
		self.m_dirLightmapJob:Poll()
		if(self.m_dirLightmapJob:IsComplete()) then
			if(self.m_dirLightmapJob:IsSuccessful()) then
				local image = self.m_dirLightmapJob:GetResult()
				local mat = self:SaveLightmapTexture(image,image,"dominant_direction_map","lightmap_normal",true)
				if(mat ~= nil) then
					mat:UpdateTextures()
					mat:InitializeShaderDescriptorSet()
					mat:SetLoaded(true)
					if(mat:Save() == false) then
						pfm.log("Failed to save lightmap atlas material as '" .. mat:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
					else
						local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
						if(lightmapC ~= nil) then
							lightmapC:SetMemberValue("lightmapMaterial",mat:GetName())
						end

						local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
						if(actorC ~= nil) then
							local pm = pfm.get_project_manager()
							pm:SetActorGenericProperty(actorC,"ec/light_map/lightmapMaterial",mat:GetName(),udm.TYPE_STRING)
						end
					end
				end
			else
				print("Lightmap baking error: ",self.m_dirLightmapJob:GetResultMessage())
			end
			self.m_dirLightmapJob = nil
		end
	end
	if(self.m_lightmapUvCacheDirty) then
		self.m_lightmapUvCacheDirty = nil
		self:TestReloadUvs()
		--self:UpdateLightmapUvCache()
	end
	if(self.m_lightmapAtlasDirty) then
		self.m_lightmapAtlasDirty = nil
		self:UpdateLightmapAtlas()
	end
	pfm.tag_render_scene_as_dirty()

	if(self.m_lightmapJob == nil and self.m_dirLightmapJob == nil) then self:SetTickPolicy(ents.TICK_POLICY_NEVER) end
end
function Component:UpdateLightmapUvCache()
	local lightmapReceivers = self:FindLightmapEntities()
	util.load_baked_lightmap_uvs(self:GetLightmapDataCache(),pfm.bake.find_bake_entities())
end
function Component:UpdateLightmapAtlas()
	local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC ~= nil) then
		--[[local tex = asset.reload(self:GetLightmapAtlas(),asset.TYPE_TEXTURE)
		tex = (tex ~= nil) and tex:GetVkTexture() or nil
		if(tex ~= nil) then lightmapC:SetLightmapAtlas(tex) end

		local texDir = asset.reload(self:GetDirectionalLightmapAtlas(),asset.TYPE_TEXTURE)
		texDir = (texDir ~= nil) and texDir:GetVkTexture() or nil
		if(texDir ~= nil) then lightmapC:SetDirectionalLightmapAtlas(texDir) end]]

		lightmapC:ReloadLightmapData()
	end
end

function Component:IsLightmapUvRebuildRequired()
	local lmC = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP)
	if(lmC == nil) then return true end

	local c = self:GetEntity():GetComponent("light_map_data_cache")
	if(c == nil) then return true end
	local cachePath = c:GetMemberValue("lightmapDataCache")
	local cache,err = ents.LightMapComponent.DataCache.load(cachePath)
	if(cache == false) then return true end
	if(cache:GetLightmapEntity() ~= lmC:GetEntity():GetUuid()) then return true end

	local instances = cache:GetInstanceIds()
	local bakeEntities = pfm.bake.find_bake_entities()
	local curUuids = {}
	for _,ent in ipairs(bakeEntities) do
		local uuid = ent:GetUuid()
		curUuids[uuid] = true
		local pose = ent:GetPose()
		local cachePose = cache:GetInstancePose(uuid)
		if(cachePose ~= nil and cachePose ~= pose) then return true end
	end

	for _,uuid in ipairs(cache:GetInstanceIds()) do
		if(curUuids[uuid] ~= true) then return true end
	end
	return false
end

include("/util/lightmap_bake.lua")
include("/pfm/bake/lightmaps.lua")
function Component:GenerateLightmapUvs()
	local lmC = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP)
	if(lmC == nil) then
		pfm.log("Failed to generate lightmap uvs: No light map component!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local pm = pfm.get_project_manager()
	local session = pm:GetProject():GetSession()
	local uuid = tostring(session:GetUniqueId())
	local path = "data/projects/" .. uuid .. "/"
	file.create_path(path)
	local cachePath = path .. "lightmap_data_cache"

	local meshFilter
	local minArea = Vector()
	local maxArea = Vector()
	local cuboidC = self:GetEntityComponent(ents.COMPONENT_PFM_CUBOID_BOUNDS)
	if(cuboidC ~= nil) then minArea,maxArea = cuboidC:GetBounds() end
	local l = minArea:DistanceSqr(maxArea)
	if(l > 0.0001) then
		meshFilter = function(ent,mesh,subMesh)
			local min,max = subMesh:GetBounds()
			local pose = ent:GetPose()
			min = pose *min
			max = pose *max
			local res = intersect.aabb_with_aabb(min,max,minArea,maxArea)
			return res ~= intersect.RESULT_OUTSIDE
		end
	else
		minArea = nil
		maxArea = nil
	end
	if(self.m_baker:BakeUvs(lmC:GetEntity(),util.get_addon_path() .. cachePath,meshFilter,minArea,maxArea) == false) then
		pfm.log("Failed to bake lightmap uvs!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if(actorC == nil) then
		pfm.log("Failed to generate lightmap uvs: No pfm actor component!",pfm.LOG_CATEGORY_PFM_BAKE,pfm.LOG_SEVERITY_WARNING)
		return
	end

	pm:SetActorGenericProperty(actorC,"ec/light_map_data_cache/lightmapDataCache",cachePath,udm.TYPE_STRING)
	local c = actorC:GetActorData():FindComponent("light_map_data_cache")
	if(c ~= nil) then
		c:SetMemberValue("lightmapDataCache",udm.TYPE_STRING,cachePath)
	end
	self:TestReloadUvs()
end

function Component:TestReloadUvs()
	local cCache = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
	if(cCache == nil) then return end
	cCache:ReloadCache()
end

function Component:GenerateDirectionalLightmaps(preview,lightIntensityFactor)
	local cCache = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
	if(cCache == nil) then return end
	local cache = cCache:GetLightMapDataCache()
	if(cache == nil) then return end
	local resolution = string.split(self:GetResolution(),"x")
	if(#resolution < 2) then return end
	local width = tonumber(resolution[1])
	local height = tonumber(resolution[2])
	if(width == nil or height == nil) then return end
	local bakeEntities = pfm.bake.find_bake_entities()
	local lightSourceEntities = pfm.bake.find_bake_light_sources()
	local lightSources = {}
	for _,ent in ipairs(lightSourceEntities) do table.insert(lightSources,ent:GetComponent(ents.COMPONENT_LIGHT)) end
	local job = pfm.bake.directional_lightmaps(bakeEntities,lightSources,width,height,cache)
	job:Start()
	self.m_dirLightmapJob = job
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	return job
end

function Component:GenerateLightmaps(preview,lightIntensityFactor,asJob)
	local cCache = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
	if(cCache == nil) then return false end
	if(preview == nil) then preview = true end
	-- util.bake_lightmaps(preview,lightIntensityFactor)
	local resolution = string.split(self:GetResolution(),"x")
	if(#resolution < 2) then return false end
	local width = tonumber(resolution[1])
	local height = tonumber(resolution[2])
	if(width == nil or height == nil) then return false end

	-- TODO
	

	local mode = self:GetLightmapMode()
	local bakeCombined = (mode == Component.LIGHTMAP_MODE_NON_DIRECTIONAL)
	self.m_baker:Start(width,height,self:GetSampleCount(),cCache:GetLightMapDataCache(),nil,bakeCombined,asJob)
	if(asJob) then return true end
	self.m_lightmapJob = self.m_baker.m_job

	--[[self.m_lightmapJob = pfm.bake.lightmaps(self:FindLightmapEntities(),self:FindLightSourceEntities(),width,height,self:GetSampleCount(),function(scene)
		local ent = ents.iterator({ents.IteratorFilterComponent("pfm_sky")})()
		if(ent ~= nil) then
			local skyC = ent:GetComponent(ents.COMPONENT_PFM_SKY)
			skyC:ApplySceneSkySettings(scene)
		end
	end)
	self.m_lightmapJob:Start()]]
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	return self:GetLightmapJob()

	--[[if(pfm.load_unirender() == false) then
		log.msg("Cannot bake lightmaps: Unable to load unirender library!",pfm.LOG_CATEGORY_VRP_PROJECT_EDITOR,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local tEnts = {}
	for _,ent in ipairs(ents.get_all()) do
		local includeEntityForLightmaps = false
		if(ent:IsWorld()) then includeEntityForLightmaps = true
		elseif(ent:IsMapEntity() and ent:HasComponent(ents.COMPONENT_PROP)) then includeEntityForLightmaps = true end
		if(includeEntityForLightmaps) then table.insert(tEnts,ent) end
	end
	if(#tEnts == 0) then
		log.msg("Cannot bake lightmaps: No entities to bake lightmaps for!",pfm.LOG_CATEGORY_VRP_PROJECT_EDITOR,pfm.LOG_SEVERITY_WARNING)
		return
	end
	local path = util.Path.CreatePath(file.remove_file_extension(self:GetProjectFileName()))
	local uvCachePath = path +"lightmap_uv_cache"
	vrp.bake_lightmap_uvs(tEnts,uvCachePath:GetString())
	local lightMapPath = path +"lightmap_atlas"
	vrp.bake_lightmaps(lightMapPath:GetString())
	-- self:ReloadLightmapData(tEnts) -- TODO: Reload lightmap data when lightmap has changed!
	return true]]
end
function Component:ReloadLightmapData(tEnts)
	--[[local entWorld = tEnts[1]
	local lightmapC = entWorld:AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC ~= nil) then
		local tex = asset.load(lightmap,asset.TYPE_TEXTURE)
		tex = (tex ~= nil) and tex:GetVkTexture() or nil
		if(tex ~= nil) then lightmapC:SetLightmapAtlas(tex) end
		lightmapC:ReloadLightmapData()
	end
	vrp.load_baked_lightmap_uvs("lm_cache",tEnts)]]
end
ents.COMPONENT_PFM_BAKED_LIGHTING = ents.register_component("pfm_baked_lighting",Component)

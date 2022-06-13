--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/bake/lightmaps.lua")

local Component = util.register_class("ents.PFMBakedLighting",BaseEntityComponent)
--[[Component:RegisterMember("LightmapDataCache",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c) c:SetLightmapUvCacheDirty() end,
	metaData = {
		rootPath = "/",
		extensions = {"lmc"},
		stripExtension = true
	}
})]]
Component:RegisterMember("LightmapAtlas",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c) c:SetLightmapAtlasDirty() end,
	metaData = {
		assetType = "texture",
		rootPath = "/",
		extensions = asset.get_supported_extensions(asset.TYPE_TEXTURE,asset.FORMAT_TYPE_ALL),
		stripExtension = true
	}
})
Component:RegisterMember("Resolution",udm.TYPE_STRING,"2048x2048")
Component:RegisterMember("SampleCount",udm.TYPE_UINT32,200)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_baker = pfm.bake.LightmapBaker()

	self:AddEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
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
function Component:OnTick(dt)
	if(self.m_lightmapJob ~= nil) then
		self.m_lightmapJob:Poll()
		if(self.m_lightmapJob:IsComplete() == false) then return end
		if(self.m_lightmapJob:IsSuccessful()) then

			local pm = pfm.get_project_manager()
			local session = pm:GetProject():GetSession()
			local uuid = tostring(session:GetUniqueId())
			local path = "projects/" .. uuid .. "/"
			file.create_path("materials/" .. path)
			local atlasPath = path .. "lightmap_atlas.hdr"

			local result = self.m_lightmapJob:GetResult()
			local r = util.save_image(result,"materials/" .. atlasPath,util.IMAGE_FORMAT_HDR)
			if(r) then
				print("Lightmap baking complete")
				self:SetLightmapAtlas(atlasPath)

				local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
				if(actorC == nil) then return end

				pm:SetActorGenericProperty(actorC,"ec/pfm_baked_lighting/lightmapAtlas",atlasPath)
				local c = actorC:GetActorData():FindComponent("pfm_baked_lighting")
				if(c ~= nil) then
					c:SetMemberValue("lightmapAtlas",udm.TYPE_STRING,atlasPath)
				end
			end
		else
			print("Lightmap baking error: ",self.m_lightmapJob:GetResultMessage())
		end
	end
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
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
end
function Component:UpdateLightmapUvCache()
	local lightmapReceivers = self:FindLightmapEntities()
	util.load_baked_lightmap_uvs(self:GetLightmapDataCache(),pfm.bake.find_bake_entities())
end
function Component:UpdateLightmapAtlas()
	local lightmapC = self:GetEntity():AddComponent(ents.COMPONENT_LIGHT_MAP)
	if(lightmapC ~= nil) then
		local tex = asset.reload(self:GetLightmapAtlas(),asset.TYPE_TEXTURE)
		print("Lightmap Atlas texture: ",self:GetLightmapAtlas())
		tex = (tex ~= nil) and tex:GetVkTexture() or nil
		if(tex ~= nil) then lightmapC:SetLightmapAtlas(tex) end
		lightmapC:ReloadLightmapData()
	end
end

include("/util/lightmap_bake.lua")
include("/pfm/bake/lightmaps.lua")
function Component:GenerateLightmapUvs()
	local lmC = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP)
	if(lmC == nil) then return end

	local pm = pfm.get_project_manager()
	local session = pm:GetProject():GetSession()
	local uuid = tostring(session:GetUniqueId())
	local path = "data/projects/" .. uuid .. "/"
	file.create_path(path)
	local cachePath = path .. "lightmap_data_cache"

	if(self.m_baker:BakeUvs(lmC:GetEntity(),util.get_addon_path() .. cachePath) == false) then return end

	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if(actorC == nil) then return end

	pm:SetActorGenericProperty(actorC,"ec/light_map_data_cache/lightmapDataCache",cachePath)
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

function Component:GenerateLightmaps(preview,lightIntensityFactor)
	local cCache = self:GetEntityComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
	if(cCache == nil) then return end
	if(preview == nil) then preview = true end
	-- util.bake_lightmaps(preview,lightIntensityFactor)
	local resolution = string.split(self:GetResolution(),"x")
	if(#resolution < 2) then return end
	local width = tonumber(resolution[1])
	local height = tonumber(resolution[2])
	if(width == nil or height == nil) then return end

	-- TODO
	

	self.m_baker:Start(width,height,self:GetSampleCount(),cCache:GetLightMapDataCache())
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
ents.PFM_BAKED_LIGHTING = ents.register_component("pfm_baked_lighting",Component)

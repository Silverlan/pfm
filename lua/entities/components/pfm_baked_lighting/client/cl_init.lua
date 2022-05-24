--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMBakedLighting",BaseEntityComponent)
Component:RegisterMember("LightmapUvCache",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c) c:SetLightmapUvCacheDirty() end,
	metaData = {
		rootPath = "/",
		extensions = {"lmc"},
		stripExtension = true
	}
})
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
end
local LIGHTMAP_CACHE_VERSION = 1
function Component:LoadLightmapUvCache(fileName)
	fileName = file.remove_file_extension(fileName,{"lmc"}) .. ".lmc"
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	local size = f:Size()
	local ds = f:Read(size)
	f:Close()

	local header = ds:ReadString(5)
	if(header ~= "PRLMC") then return false end
	local version = ds:ReadUInt32()
	if(version < 1 or version > LIGHTMAP_CACHE_VERSION) then return false end

	local dictionary = {}
	local numModels = ds:ReadUInt32()
	for i=1,numModels do
		local mdlName = ds:ReadString()
		local dataOffset = ds:ReadUInt64()
		dictionary[i] = {mdlName,dataOffset}
	end
	local tModels = {}
	for i,data in ipairs(dictionary) do
		local mdl = game.load_model(data[1])
		if(mdl ~= nil) then
			table.insert(tModels,mdl)
			ds:Seek(data[2])
			local numGroups = ds:ReadUInt32()
			for j=1,numGroups do
				local meshGroup = (mdl ~= nil) and mdl:GetMeshGroup(j -1) or nil
				local numMeshes = ds:ReadUInt32()
				for k=1,numMeshes do
					local mesh = (meshGroup ~= nil) and meshGroup:GetMesh(k -1) or nil
					local numSubMeshes = ds:ReadUInt32()
					for l=1,numSubMeshes do
						local subMesh = (mesh ~= nil) and mesh:GetSubMesh(l -1) or nil
						local hasLightmapSet = ds:ReadBool()
						if(hasLightmapSet) then
							subMesh:AddUVSet("lightmap")
							local numVerts = ds:ReadUInt32()
							subMesh:SetVertexCount(numVerts)
							for m=1,numVerts do
								local pos = ds:ReadVector()
								local uv = ds:ReadVector2()
								local normal = ds:ReadVector()
								local tangent = ds:ReadVector4()
								local uvLightmap = ds:ReadVector2()

								subMesh:SetVertexPosition(m -1,pos)
								subMesh:SetVertexNormal(m -1,normal)
								subMesh:SetVertexUV(m -1,uv)
								subMesh:SetVertexTangent(m -1,tangent)

								subMesh:SetVertexUV("lightmap",m -1,uvLightmap)
							end

							subMesh:ClearIndices()
							local numIndices = ds:ReadUInt32()
							for i=1,numIndices,3 do
								local idx0 = ds:ReadUInt32()
								local idx1 = ds:ReadUInt32()
								local idx2 = ds:ReadUInt32()
								subMesh:AddTriangle(idx0,idx1,idx2)
							end
						end
						subMesh:Update(game.Model.FUPDATE_ALL)
					end
				end
			end
		end
	end
	return tModels
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
		local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
		if(lightC:IsBaked()) then
			table.insert(t,ent)
		end
	end
	return t
end
function Component:LoadBakedLightmapUvs(lightmapCachePath,tEnts)
	local models = self:LoadLightmapUvCache(lightmapCachePath)
	if(models == false) then
		return false
	end
	self:UpdateLightmapData(tEnts)
	return true
end
function Component:SetLightmapUvCacheDirty()
	self.m_lightmapUvCacheDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:SetLightmapAtlasDirty()
	self.m_lightmapAtlasDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnTick(dt)
	if(self.m_lightmapJob ~= nil) then
		self.m_lightmapJob:Poll()
		if(self.m_lightmapJob:IsComplete() == false) then return end
		if(self.m_lightmapJob:IsSuccessful()) then
			local result = self.m_lightmapJob:GetResult()
			local r = util.save_image(result,"materials/test_lm.hdr",util.IMAGE_FORMAT_HDR)
			if(r) then
				print("Lightmap baking complete")
				self:SetLightmapAtlas("test_lm.hdr")
			end
		else
			print("Lightmap baking error: ",self.m_lightmapJob:GetResultMessage())
		end
	end
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	if(self.m_lightmapUvCacheDirty) then
		self.m_lightmapUvCacheDirty = nil
		self:UpdateLightmapUvCache()
	end
	if(self.m_lightmapAtlasDirty) then
		self.m_lightmapAtlasDirty = nil
		self:UpdateLightmapAtlas()
	end
	pfm.tag_render_scene_as_dirty()
end
function Component:UpdateLightmapUvCache()
	local lightmapReceivers = self:FindLightmapEntities()
	local cacheFileName = file.remove_file_extension(self:GetLightmapUvCache(),{"lmc"}) .. ".lmc"
	self:LoadBakedLightmapUvs(cacheFileName,lightmapReceivers)
	for _,ent in ipairs(lightmapReceivers) do
		local lightMapReceiver = ent:GetComponent(ents.COMPONENT_LIGHT_MAP_RECEIVER)
		if(lightMapReceiver ~= nil) then lightMapReceiver:UpdateLightmapUvData() end

		-- local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		-- if(renderC ~= nil) then renderC:SetCastShadows(false) end -- For performance reasons we only want the actors to cast shadows
	end
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
	local lightmapReceivers = self:FindLightmapEntities()
	util.bake_lightmap_uvs(lightmapReceivers,"test")
end

function Component:GenerateLightmaps(preview,lightIntensityFactor)
	if(preview == nil) then preview = true end
	-- util.bake_lightmaps(preview,lightIntensityFactor)
	local resolution = string.split(self:GetResolution(),"x")
	if(#resolution < 2) then return end
	local width = tonumber(resolution[1])
	local height = tonumber(resolution[2])
	if(width == nil or height == nil) then return end
	self.m_lightmapJob = pfm.bake.lightmaps(self:FindLightmapEntities(),self:FindLightSourceEntities(),width,height,self:GetSampleCount())
	self.m_lightmapJob:Start()
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

--Component:RegisterMember("Resolution",udm.TYPE_STRING,"2048x2048")
--Component:RegisterMember("SampleCount",udm.TYPE_UINT32,200)

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

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

-- Note: Actor animations are currently cached through a separate system, however cameras don't have animation support yet, so we have to handle them
-- separately for now, which we'll do here. Once camera animations are supported, this class can be removed.

pfm = pfm or {}

util.register_class("pfm.ProjectPacker")

function pfm.ProjectPacker:__init()
	self.m_assetFileMap = {}
end

function pfm.ProjectPacker:AddFile(f)
	pfm.log("Adding file '" .. f .. "'...", pfm.LOG_CATEGORY_PFM)
	self.m_assetFileMap[f] = f
end
function pfm.ProjectPacker:AddAsset(f, type, skipAddFunc)
	pfm.log("Adding asset '" .. f .. " (" .. asset.type_to_string(type) .. ")" .. "'...", pfm.LOG_CATEGORY_PFM)
	if skipAddFunc ~= true then
		if type == asset.TYPE_MODEL then
			self:AddModel(f)
		elseif type == asset.TYPE_MATERIAL then
			self:AddMaterial(f)
		elseif type == asset.TYPE_SOUND then
			self:AddSound(f)
		elseif type == asset.TYPE_MAP then
			self:AddMap(f)
		end
	end
	f = asset.find_file(f, type)
	if f == nil then
		return
	end
	self:AddFile(asset.relative_path_to_absolute_path(f, type))
end
function pfm.ProjectPacker:AddMaterial(mat)
	if type(mat) == "string" then
		mat = game.load_material(mat)
	end
	local matName = util.Path(mat:GetName())
	self:AddAsset(matName:GetString(), asset.TYPE_MATERIAL, true)
	local db = mat:GetDataBlock()
	for _, key in ipairs(db:GetKeys()) do
		if db:GetValueType(key) == "texture" then
			local texInfo = mat:GetTextureInfo(key)
			if texInfo ~= nil then
				self:AddFile(
					asset.relative_path_to_absolute_path(util.Path(texInfo:GetName()):GetString(), asset.TYPE_TEXTURE)
				)
			end
		end
	end

	--[[if(db:HasValue("animation")) then
		self:AddFile(asset.relative_path_to_absolute_path(file.remove_file_extension(db:GetString("animation")) .. ".psd",asset.TYPE_MATERIAL))
	end]]
end
function pfm.ProjectPacker:AddModel(mdl)
	if type(mdl) == "string" then
		mdl = game.load_model(mdl)
		if mdl == nil then
			return
		end
	end
	for _, mat in ipairs(mdl:GetMaterials()) do
		self:AddMaterial(mat)
	end
	self:AddAsset(mdl:GetName(), asset.TYPE_MODEL, true)

	for _, mdlName in ipairs(mdl:GetIncludeModels()) do
		local mdlInclude = game.load_model(mdlName)
		if mdlInclude ~= nil then
			self:AddModel(mdlInclude)
		end
	end
end
function pfm.ProjectPacker:AddSound(snd)
	self:AddAsset(snd, asset.TYPE_AUDIO, true)
end
function pfm.ProjectPacker:AddFilmClip(filmClip)
	for _, actor in ipairs(filmClip:GetActorList()) do
		pfm.log("Adding actor '" .. tostring(actor) .. "'...", pfm.LOG_CATEGORY_PFM)
		for _, component in ipairs(actor:GetComponents()) do
			local type = component:GetType()
			if type == "model" then
				local mdlName = component:GetMemberValue("model")
				if mdlName ~= nil and #mdlName > 0 then
					local mdl = game.load_model(mdlName)
					if mdl ~= nil then
						self:AddModel(mdl)
					end
				end
			elseif type == "pfm_sky" then
				local skyTex = component:GetMemberValue("skyTexture")
				if skyTex ~= nil and #skyTex > 0 then
					self:AddAsset(skyTex, asset.TYPE_TEXTURE)
				end
			elseif type == "pfm_particle_system" then
				local ptName = component:GetMemberValue("particleSystem")
				local ptFileName = component:GetMemberValue("particleSystemFile")
				if ptName ~= nil and #ptName > 0 and ptFileName ~= nil and #ptFileName > 0 then
					self:AddAsset(ptFileName, asset.TYPE_PARTICLE_SYSTEM)
					local ptSystemDef = ents.ParticleSystemComponent.get_particle_system_definition(ptName)
					if ptSystemDef ~= nil then
						local mat = ptSystemDef["material"]
						mat = (mat ~= nil) and game.load_material(mat) or nil
						if mat ~= nil then
							self:AddMaterial(mat)
						end
					end
				end
			end

			local componentId = ents.find_component_id(type)
			local componentInfo = (componentId ~= nil) and ents.get_component_info(componentId) or nil
			if componentInfo ~= nil then
				local numMembers = componentInfo:GetMemberCount()
				local isLuaComponent = false
				if numMembers == 0 then
					numMembers = ents.get_lua_component_member_count(componentId)
					isLuaComponent = true
				end
				for i = 1, numMembers do
					local memberInfo
					if isLuaComponent then
						memberInfo = ents.get_lua_component_member_info(componentId, i - 1)
					else
						memberInfo = componentInfo:GetMemberInfo(i - 1)
					end
					if memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE then
						local value = component:GetMemberValue(memberInfo.name)
						if value ~= nil then
							local filePath = value
							local meta = memberInfo.metaData
							local assetType = (meta ~= nil) and meta:GetValue("assetType") or nil
							assetType = (assetType ~= nil) and asset.get_type_enum(assetType) or nil
							if assetType ~= nil then
								local fileName = asset.find_file(filePath, assetType)
								if fileName ~= nil then
									self:AddAsset(fileName, assetType)
								end
							else
								local rootPath = (meta ~= nil) and meta:GetValue("rootPath") or nil
								local extensions = (meta ~= nil and meta:HasValue("extensions"))
										and meta:GetArrayValues("extensions", udm.TYPE_STRING)
									or nil
								if rootPath ~= nil then
									rootPath = util.Path.CreatePath(rootPath)
									filePath = rootPath:GetString() .. filePath
								end
								local ext = (extensions ~= nil) and file.get_file_extension(filePath, extensions)
									or file.get_file_extension(filePath)
								if ext ~= nil then
									self:AddFile(filePath)
								else
									for _, ext in ipairs(extensions) do
										local extPath = filePath .. "." .. ext
										if file.exists(extPath) then
											self:AddFile(extPath)
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	for _, trackGroup in ipairs(filmClip:GetTrackGroups()) do
		for _, track in ipairs(trackGroup:GetTracks()) do
			for _, filmClip in ipairs(track:GetFilmClips()) do
				self:AddFilmClip(filmClip)
			end
			for _, audioClip in ipairs(track:GetAudioClips()) do
				local sound = audioClip:GetSound()
				local soundName = sound:GetSoundName()
				if #soundName > 0 then
					self:AddSound(soundName)
				end
			end
		end
	end
end
function pfm.ProjectPacker:AddSession(session)
	pfm.log("Adding session '" .. tostring(session) .. "'...", pfm.LOG_CATEGORY_PFM)
	for _, filmClip in ipairs(session:GetClips()) do
		self:AddFilmClip(filmClip)
	end
end
function pfm.ProjectPacker:AddMap(map)
	pfm.log("Adding map '" .. map .. "'...", pfm.LOG_CATEGORY_PFM)
	local mapName = game.get_map_name()
	self:AddAsset(mapName, asset.TYPE_MAP, true)
	self:AddAsset(mapName .. "/lightmap_atlas", asset.TYPE_TEXTURE)

	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE) }) do
		local probeC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local path = util.Path.CreateFilePath(probeC:GetIBLMaterialFilePath())
		path:PopFront()
		local mat = game.load_material(path:GetString())
		if mat ~= nil then
			self:AddMaterial(mat)
		end
	end

	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_LIGHT_MAP) }) do
		local lightMapC = ent:GetComponent(ents.COMPONENT_LIGHT_MAP)
		local matName = lightMapC:GetLightmapMaterialName()
		if #matName > 0 then
			self:AddMaterial(matName)
		end
	end

	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE) }) do
		local lightMapDataCacheC = ent:GetComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
		local dataCache = lightMapDataCacheC:GetLightMapDataCacheFilePath()
		if #dataCache > 0 then
			self:AddFile(dataCache)
		end
	end

	for _, ent in ipairs(ents.get_all()) do
		if ent:IsMapEntity() then
			local mdl = ent:GetModel()
			if mdl ~= nil then
				self:AddModel(mdl)
			end
		end
	end
end
function pfm.ProjectPacker:GetFiles()
	return self.m_assetFileMap
end
function pfm.ProjectPacker:Pack(fileName)
	local fileName = file.remove_file_extension(fileName) .. ".zip"
	local result, tFilesNotFound = util.pack_zip_archive(fileName, self.m_assetFileMap)
	if result == false then
		console.print_warning("Could not pack zip archive '" .. fileName .. "'!")
		return
	end
	if #tFilesNotFound > 0 then
		console.print_warning("Failed to pack " .. #tFilesNotFound .. " to zip-archive:")
		console.print_table(tFilesNotFound)
	end
	util.open_path_in_explorer(util.get_addon_path(), fileName)
end

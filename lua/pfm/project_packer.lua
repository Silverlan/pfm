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

function pfm.ProjectPacker:AddFile(f) self.m_assetFileMap[f] = f end
function pfm.ProjectPacker:AddAsset(f,type)
	f = asset.find_file(f,type)
	if(f == nil) then return end
	self:AddFile(asset.relative_path_to_absolute_path(f,type))
end
function pfm.ProjectPacker:AddMaterial(mat)
	local matName = util.Path(mat:GetName())
	self:AddAsset(matName:GetString(),asset.TYPE_MATERIAL)
	local db = mat:GetDataBlock()
	for _,key in ipairs(db:GetKeys()) do
		if(db:GetValueType(key) == "texture") then
			local texInfo = mat:GetTextureInfo(key)
			if(texInfo ~= nil) then
				self:AddFile(asset.relative_path_to_absolute_path(util.Path(texInfo:GetName()):GetString(),asset.TYPE_TEXTURE))
			end
		end
	end

	--[[if(db:HasValue("animation")) then
		self:AddFile(asset.relative_path_to_absolute_path(file.remove_file_extension(db:GetString("animation")) .. ".psd",asset.TYPE_MATERIAL))
	end]]
end
function pfm.ProjectPacker:AddModel(mdl)
	if(type(mdl) == "string") then
		mdl = game.load_model(mdl)
		if(mdl == nil) then return end
	end
	for _,mat in ipairs(mdl:GetMaterials()) do
		self:AddMaterial(mat)
	end
	self:AddAsset(mdl:GetName(),asset.TYPE_MODEL)

	for _,mdlName in ipairs(mdl:GetIncludeModels()) do
		local mdlInclude = game.load_model(mdlName)
		if(mdlInclude ~= nil) then self:AddModel(mdlInclude) end
	end
end
function pfm.ProjectPacker:AddSound(snd)
	self:AddAsset(snd,asset.TYPE_AUDIO)
end
function pfm.ProjectPacker:AddFilmClip(filmClip)
	for _,actor in ipairs(filmClip:GetActorList()) do
		for _,component in ipairs(actor:GetComponents():GetTable()) do
			local type = component:GetType()
			if(type == fudm.ELEMENT_TYPE_PFM_MODEL) then
				local mdlName = component:GetModelName()
				if(#mdlName > 0) then
					local mdl = game.load_model(mdlName)
					if(mdl ~= nil) then self:AddModel(mdl) end
				end
			elseif(type == fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM) then
				local ptSystemName = component:GetParticleSystemName()
				local ptFileName = ents.ParticleSystemComponent.find_particle_system_file(ptSystemName)
				if(ptFileName ~= nil) then
					self:AddFile(ptFileName)
					local ptSystemDef = ents.ParticleSystemComponent.get_particle_system_definition(ptSystemName)
					if(ptSystemDef ~= nil) then
						local mat = ptSystemDef["material"]
						mat = (mat ~= nil) and game.load_material(mat) or nil
						if(mat ~= nil) then
							self:AddMaterial(mat)
						end
					end
				end
			end
		end
	end
	for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
				self:AddFilmClip(filmClip)
			end
			for _,audioClip in ipairs(track:GetAudioClips():GetTable()) do
				local sound = audioClip:GetSound()
				local soundName = sound:GetSoundName()
				if(#soundName > 0) then self:AddSound(soundName) end
			end
		end
	end
end
function pfm.ProjectPacker:AddSession(session)
	for _,filmClip in ipairs(session:GetClips():GetTable()) do
		self:AddFilmClip(filmClip)
	end
end
function pfm.ProjectPacker:AddMap(map)
	local mapName = game.get_map_name()
	self:AddAsset(mapName,asset.TYPE_MAP)
	self:AddAsset(mapName .. "/lightmap_atlas",asset.TYPE_TEXTURE)

	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE)}) do
		local probeC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local path = util.Path.CreateFilePath(probeC:GetIBLMaterialFilePath())
		path:PopFront()
		local mat = game.load_material(path:GetString())
		if(mat ~= nil) then self:AddMaterial(mat) end
	end

	for _,ent in ipairs(ents.get_all()) do
		if(ent:IsMapEntity()) then
			local mdl = ent:GetModel()
			if(mdl ~= nil) then
				self:AddModel(mdl)
			end
		end
	end
end
function pfm.ProjectPacker:GetFiles() return self.m_assetFileMap end
function pfm.ProjectPacker:Pack(fileName)
	local fileName = file.remove_file_extension(fileName) .. ".zip"
	local result,tFilesNotFound = util.pack_zip_archive(fileName,self.m_assetFileMap)
	if(result == false) then
		console.print_warning("Could not pack zip archive '" .. fileName .. "'!")
		return
	end
	if(#tFilesNotFound > 0) then
		console.print_warning("Failed to pack " .. #tFilesNotFound .. " to zip-archive:")
		console.print_table(tFilesNotFound)
	end
	util.open_path_in_explorer(util.get_addon_path(),fileName)
end

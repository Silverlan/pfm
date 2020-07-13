--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.WIFilmmaker:PackProject(fileName)
	local project = self:GetProject()
	local name = project:GetName()
	local session = self:GetSession()

	local assetFileMap = {}
	local function add_file(f) assetFileMap[f] = true end -- Using a map allows us to get rid of duplicates more easily
	local function add_material(mat)
		local matName = util.Path(mat:GetName())
		add_file("materials/" .. matName:GetString())
		local db = mat:GetDataBlock()
		for _,key in ipairs(db:GetKeys()) do
			if(db:GetValueType(key) == "texture") then
				local texInfo = mat:GetTextureInfo(key)
				if(texInfo ~= nil) then
					add_file("materials/" .. util.Path(texInfo:GetName()):GetString())
				end
			end
		end

		if(db:HasValue("animation")) then
			add_file("materials/" .. file.remove_file_extension(db:GetString("animation")) .. ".psd")
		end
	end
	local function add_model(mdl)
		for _,mat in ipairs(mdl:GetMaterials()) do
			add_material(mat)
		end
		add_file("models/" .. util.Path(mdl:GetName()):GetString())

		for _,mdlName in ipairs(mdl:GetIncludeModels()) do
			local mdlInclude = game.load_model(mdlName)
			if(mdlInclude ~= nil) then add_model(mdlInclude) end
		end
	end
	local function add_film_clip(filmClip)
		for _,actor in ipairs(filmClip:GetActorList()) do
			for _,component in ipairs(actor:GetComponents():GetTable()) do
				local type = component:GetType()
				if(type == udm.ELEMENT_TYPE_PFM_MODEL) then
					local mdlName = component:GetModelName()
					if(#mdlName > 0) then
						local mdl = game.load_model(mdlName)
						if(mdl ~= nil) then add_model(mdl) end
					end
				elseif(type == udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM) then
					local ptSystemName = component:GetParticleSystemName()
					local ptFileName = ents.ParticleSystemComponent.find_particle_system_file(ptSystemName)
					if(ptFileName ~= nil) then
						add_file(ptFileName)
						local ptSystemDef= ents.ParticleSystemComponent.get_particle_system_definition(ptSystemName)
						if(ptSystemDef ~= nil) then
							local mat = ptSystemDef["material"]
							mat = (mat ~= nil) and game.load_material(mat) or nil
							if(mat ~= nil) then
								add_material(mat)
							end
						end
					end
				end
			end
		end
		for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
			for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
				for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
					add_film_clip(filmClip)
				end
			end
		end
	end
	for _,filmClip in ipairs(session:GetClips():GetTable()) do
		add_film_clip(filmClip)
	end
	local mapName = game.get_map_name()
	add_file("maps/" .. mapName .. ".wld")

	for _,ent in ipairs(ents.get_all()) do
		if(ent:IsMapEntity()) then
			local mdl = ent:GetModel()
			if(mdl ~= nil) then
				add_model(mdl)
			end
		end
	end

	fileName = file.remove_file_extension(fileName) .. ".zip"
	local assetFiles = {}
	for f,_ in pairs(assetFileMap) do
		table.insert(assetFiles,f)
	end
	util.pack_zip_archive(fileName,assetFiles)
	util.open_path_in_explorer(util.get_addon_path(),fileName)

	-- TODO: Pack session file
	-- TODO: Pack audio files
end

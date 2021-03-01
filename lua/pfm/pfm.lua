--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.impl = pfm.impl or {}

pfm.impl.projects = pfm.impl.projects or {}

pfm.PROJECT_FILE_IDENTIFIER = "PFM"
pfm.PROJECT_FILE_FORMAT_VERSION = 2

include("/util/log.lua")
include("/udm/udm.lua")
include("udm")
include("math.lua")
include("unirender.lua")
include("message_popup.lua")
include("tree/pfm_tree.lua")

util.register_class("pfm.Project")
function pfm.Project:__init()
	self.m_udmRoot = fudm.create_element(fudm.ELEMENT_TYPE_ROOT,"root")
	self.m_sessions = {}
	self.m_uniqueId = util.generate_uuid_v4()

	self:SetName("new_project") -- TODO
end

function pfm.Project:SetName(name) self.m_projectName = name end
function pfm.Project:GetName() return self.m_projectName end
function pfm.Project:GetUniqueId() return self.m_uniqueId end

function pfm.Project:Save(fileName)
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_WRITE,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end

	f:WriteString(pfm.PROJECT_FILE_IDENTIFIER,false)
	f:WriteUInt32(pfm.PROJECT_FILE_FORMAT_VERSION)
	f:WriteUInt64(0) -- Placeholder for flags
	f:WriteString(self.m_uniqueId)

	local elements = {}
	local function collect_elements(el)
		elements[el] = true
		if(el:IsElement() == false) then return end
		for name,child in pairs(el:GetChildren()) do
			if(elements[child] == nil) then
				collect_elements(child)
			end
		end
	end
	collect_elements(self.m_udmRoot)

	local elementList = {}
	for el in pairs(elements) do
		-- References need to be first in the list
		if(el:GetType() == fudm.ELEMENT_TYPE_REFERENCE) then table.insert(elementList,1,el)
		else table.insert(elementList,el) end
	end

	-- Save elements
	f:WriteUInt32(#elementList)
	for idx,el in ipairs(elementList) do
		elements[el] = idx -1

		fudm.save(f,el)
	end

	-- Save child information
	for _,el in ipairs(elementList) do
		if(el:IsElement()) then
			local children = el:GetChildren()
			local numChildren = 0
			for _ in pairs(children) do numChildren = numChildren +1 end
			f:WriteUInt16(numChildren)
			for name,child in pairs(children) do
				f:WriteString(tostring(name))
				f:WriteUInt32(elements[child])
			end
		end
	end

	f:Close()
	return true
end

function pfm.Project:Load(fileName)
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end

	local ident = f:ReadString(#pfm.PROJECT_FILE_IDENTIFIER)
	if(ident ~= pfm.PROJECT_FILE_IDENTIFIER) then
		f:Close()
		return false
	end

	local version = f:ReadUInt32()
	if(version < 1 or version > pfm.PROJECT_FILE_FORMAT_VERSION) then
		f:Close()
		return false
	end

	local flags = f:ReadUInt64() -- Currently unused
	if(version > 1) then self.m_uniqueId = f:ReadString()
	else self.m_uniqueId = util.get_string_hash(util.Path.CreateFilePath(fileName):GetString()) end

	local numElements = f:ReadUInt32()
	local elements = {}
	for i=1,numElements do
		local el = fudm.load(f)
		table.insert(elements,el)
	end

	-- Read child information
	for _,el in ipairs(elements) do
		if(el:IsElement()) then
			if(el:GetType() == fudm.ELEMENT_TYPE_ROOT) then
				self.m_udmRoot = el
			end
			if(el:GetType() == fudm.ELEMENT_TYPE_PFM_SESSION) then
				table.insert(self.m_sessions,el)
			end
			local numChildren = f:ReadUInt16()
			for i=1,numChildren do
				local name = f:ReadString()
				local childIdx = f:ReadUInt32()
				local child = elements[childIdx +1]
				el:SetProperty(name,child)
			end
			el:OnLoaded()
		end
	end

	self.m_udmRoot:LoadFromBinary(f)
	f:Close()
	return true
end

function pfm.Project:GetSessions() return self.m_sessions end

function pfm.Project:AddSession(session)
	if(type(session) == "string") then
		local name = session
		session = fudm.create_element(fudm.ELEMENT_TYPE_PFM_SESSION)
		session:ChangeName(name)
	end
	self:GetUDMRootNode():AddChild(session)
	table.insert(self.m_sessions,session)
	return session
end

function pfm.Project:GetUDMRootNode() return self.m_udmRoot end

function pfm.Project:DebugPrint(node,t,name)
	if(node == nil) then
		self:DebugPrint(self:GetUDMRootNode(),t,name)
		return
	end
	node:DebugPrint(t,name)
end

function pfm.Project:DebugDump(f,node,t,name)
	if(node == nil) then
		self:DebugDump(f,self:GetUDMRootNode(),t,name)
		return
	end
	node:DebugDump(f,t,name)
end

function pfm.Project:CollectAssetFiles()
	local assetFileMap = {}
	local function add_file(f) assetFileMap[f] = f end
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
				if(type == fudm.ELEMENT_TYPE_PFM_MODEL) then
					local mdlName = component:GetModelName()
					if(#mdlName > 0) then
						local mdl = game.load_model(mdlName)
						if(mdl ~= nil) then add_model(mdl) end
					end
				elseif(type == fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM) then
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
				for _,audioClip in ipairs(track:GetAudioClips():GetTable()) do
					local sound = audioClip:GetSound()
					local soundName = sound:GetSoundName()
					if(#soundName > 0) then add_file("sounds/" .. soundName) end
				end
			end
		end
	end
	for _,session in ipairs(self:GetSessions()) do
		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			add_film_clip(filmClip)
		end
	end
	local mapName = game.get_map_name()
	add_file("maps/" .. mapName .. ".wld")
	local pathLightmapAtlas = asset.find_file("maps/" .. mapName .. "/lightmap_atlas",asset.TYPE_TEXTURE)
	if(pathLightmapAtlas ~= nil) then add_file("materials/" .. pathLightmapAtlas) end

	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_REFLECTION_PROBE)}) do
		local probeC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local path = util.Path.CreateFilePath(probeC:GetIBLMaterialFilePath())
		path:PopFront()
		local mat = game.load_material(path:GetString())
		if(mat ~= nil) then add_material(mat) end
	end

	for _,ent in ipairs(ents.get_all()) do
		if(ent:IsMapEntity()) then
			local mdl = ent:GetModel()
			if(mdl ~= nil) then
				add_model(mdl)
			end
		end
	end
	-- TODO: Pack project file
	-- TODO: Pack audio files
	return assetFileMap
end

pfm.create_project = function()
	local project = pfm.Project()
	table.insert(pfm.impl.projects,project)
	return project
end

pfm.create_empty_project = function()
	local project = pfm.create_project()

	local session = project:AddSession("session")
	local filmClip = session:GetActiveClip()
	filmClip:ChangeName("new_project")
	session:GetClips():PushBack(filmClip)

	local subClipTrackGroup = fudm.create_element(fudm.ELEMENT_TYPE_PFM_TRACK_GROUP)
	subClipTrackGroup:ChangeName("subClipTrackGroup")
	filmClip:GetTrackGroupsAttr():PushBack(subClipTrackGroup)

	local filmTrack = fudm.create_element(fudm.ELEMENT_TYPE_PFM_TRACK)
	filmTrack:ChangeName("Film")
	subClipTrackGroup:GetTracksAttr():PushBack(filmTrack)

	local shot1 = session:AddFilmClip()
	shot1:GetTimeFrame():SetDuration(60.0)

	return project
end

pfm.load_project = function(fileName)
	local project = pfm.create_project()
	if(project:Load(fileName) == false) then return end
	return project
end

pfm.get_projects = function() return pfm.impl.projects end

pfm.get_key_binding = function(identifier)
	return "TODO"
end

pfm.get_project_manager = function() return pfm.impl.projectManager end
pfm.set_project_manager = function(pm) pfm.impl.projectManager = pm end

pfm.tag_render_scene_as_dirty = function(dirty)
	local pm = pfm.get_project_manager()
	if(util.is_valid(pm) == false or pm.TagRenderSceneAsDirty == nil) then return end
	pm:TagRenderSceneAsDirty(dirty)
end

pfm.translate_flex_controller_value = function(fc,val)
	return fc.min +val *(fc.max -fc.min)
end

pfm.find_inanimate_actors = function(session)
	local function get_film_clips(filmClip,filmClips)
		filmClips[filmClip] = true
		for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
			for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
				for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
					get_film_clips(filmClip,filmClips)
				end
			end
		end
	end
	local filmClips = {}
	for _,clip in ipairs(session:GetClips():GetTable()) do
		get_film_clips(clip,filmClips)
	end
	local filmClipList = {}
	for filmClip,_ in pairs(filmClips) do
		table.insert(filmClipList,filmClip)
	end

	local iteratedChannels = {}
	local function collect_actors(filmClip,actors)
		for _,trackGroup in ipairs(filmClip:GetTrackGroups():GetTable()) do
			for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
				for _,channelClip in ipairs(track:GetChannelClips():GetTable()) do
					for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
						if(iteratedChannels[channel] == nil) then
							iteratedChannels[channel] = true
							local el = channel:GetToElement()
							if(el ~= nil) then
								local iterated = {}
								iterated[el] = true
								local parent = el:FindParentElement()
								while(parent ~= nil and parent:GetType() ~= fudm.ELEMENT_TYPE_PFM_ACTOR) do
									parent = el:FindParentElement()
									if(parent ~= nil) then
										if(iterated[parent]) then parent = nil
										else iterated[parent] = true end
									end
								end
								if(parent ~= nil) then
									local numValues = 0
									if(actors[parent] == nil) then
										local log = channel:GetLog()
										for _,layer in ipairs(log:GetLayers():GetTable()) do
											local values = layer:GetValues()
											numValues = numValues +#values
										end
									end
									actors[parent] = math.max(actors[parent] or 0,numValues)
								end
							end
						end
					end
				end
			end
		end
	end
	local actors = {}
	for _,filmClip in ipairs(filmClipList) do
		collect_actors(filmClip,actors)
	end

	local actorList = {}
	for actor,numValues in pairs(actors) do
		if(numValues > 1) then table.insert(actorList,actor) end
	end
	return actorList
end

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.impl = pfm.impl or {}

pfm.impl.projects = pfm.impl.projects or {}

pfm.PROJECT_FILE_IDENTIFIER = "PFM"
pfm.PROJECT_FILE_FORMAT_VERSION = 2

pfm.PATREON_JOIN_URL = "https://www.patreon.com/silverlan/join"
pfm.PATREON_SETTINGS_URL = "https://wiki.pragma-engine.com/supporter/login.php"

pfm.VERSION = util.Version(0,4,2)
pfm.VERSION_DATE = "21-06-22"
pfm.PROJECT_TITLE = "PFM"

include("/util/log.lua")
include("/util/color_scheme.lua")
include("/udm/udm.lua")
include("/udm/schema_api.lua")
include("udm")
include("math.lua")
include("unirender.lua")
include("message_popup.lua")
include("tree/pfm_tree.lua")
include("project_packer.lua")
include("udm_converter.lua")

-- Load and initialize schema
pfm.udm = pfm.udm or {}
local schema,err = udm.Schema.load("pfm.udms")
if(schema == false) then
	console.print_warning("Failed to load PFM UDM schemas: " .. err)
	return
end
pfm.udm.SCHEMA = schema
pfm.udm.SCHEMA:SetLibrary(pfm.udm)

local res,err = udm.generate_lua_api_from_schema(pfm.udm.SCHEMA,pfm.udm)
if(res ~= true) then
	console.print_warning("Failed to generate PFM UDM API: " .. err)
	return
end
--

pfm.udm.get_schema = function() return pfm.udm.SCHEMA end

include("/udm/pfm_util")

util.register_class("pfm.Project")
pfm.Project.FORMAT_EXTENSION_BINARY = "pfmp_b"
pfm.Project.FORMAT_EXTENSION_ASCII = "pfmp"
pfm.Project.get_format_extensions = function() return {pfm.Project.FORMAT_EXTENSION_ASCII,pfm.Project.FORMAT_EXTENSION_BINARY} end
pfm.Project.get_full_project_file_name = function(baseName)
	baseName = file.remove_file_extension(baseName,pfm.Project.get_format_extensions())
	return "projects/" .. baseName .. "." .. pfm.Project.FORMAT_EXTENSION_BINARY
end
function pfm.Project:__init()
	self:SetName("new_project")
end

function pfm.Project:SetName(name) self.m_projectName = name end
function pfm.Project:GetName() return self.m_projectName end

function pfm.Project:Close()
	if(self.m_closed) then return end
	self.m_closed = true
	self:GetSession():Remove()
end

function pfm.Project:SaveLegacy(fileName)
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

function pfm.Project:Save(fileName,legacy)
	if(legacy) then return self:SaveLegacy(fileName) end

	file.create_path(file.get_file_path(fileName))
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_WRITE,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	local udmData = udm.create("PFMP",1)
	udmData:GetAssetData():GetData():SetValue("session",self:GetSession():GetRootUdmData())
	-- udmData:SaveAscii(f,bit.bor(udm.ASCII_SAVE_FLAG_BIT_INCLUDE_HEADER,udm.ASCII_SAVE_FLAG_BIT_DONT_COMPRESS_LZ4_ARRAYS))
	udmData:Save(f)
	f:Close()

	return true
end

function pfm.Project:LoadLegacy(f,fileName)
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

	debug.start_profiling_task("pfm_load")
	local numElements = f:ReadUInt32()
	local elements = {}
	for i=1,numElements do
		local el = fudm.load(f)
		table.insert(elements,el)
	end

	-- Read child information
	for _,el in ipairs(elements) do
		if(el:IsElement()) then
			local type = el:GetType()
			if(type == fudm.ELEMENT_TYPE_ROOT) then
				self.m_udmRoot = el
			end
			if(type == fudm.ELEMENT_TYPE_PFM_SESSION) then
				table.insert(self.m_sessions,el)
			end
			local numChildren = f:ReadUInt16()
			for i=1,numChildren do
				local name = f:ReadString()
				local childIdx = f:ReadUInt32()
				local child = elements[childIdx +1]
				if(type == fudm.ELEMENT_TYPE_PFM_SESSION and name == "activeClip") then child = fudm.create_reference(child) end
				el:SetProperty(name,child)
			end
			el:OnLoaded()
		end
	end

	self.m_udmRoot:LoadFromBinary(f)
	f:Close()
	debug.stop_profiling_task()
	return true
end

function pfm.Project:Load(fileName)
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end

	local ident = f:ReadString(#pfm.PROJECT_FILE_IDENTIFIER)
	f:Seek(0)
	if(ident == pfm.PROJECT_FILE_IDENTIFIER) then
		return self:LoadLegacy(f,fileName)
	end
	debug.start_profiling_task("pfm_load")

	local udmFile,err = udm.load(f)
	f:Close()
	if(udmFile == false) then
		debug.stop_profiling_task()
		return false,err
	end
	local udmData = udmFile:GetAssetData():GetData()
	if(udmData:Get("session"):IsValid() == false) then
		debug.stop_profiling_task()
		return false,"Project file contains no session!"
	end
	local session = udm.create_property_from_schema(pfm.udm.SCHEMA,"Session",nil,udmData:Get("session"):ClaimOwnership())
	debug.stop_profiling_task()

	self.m_session = session
	return true
end

function pfm.Project:SetSession(session) self.m_session = session end
function pfm.Project:GetSession() return self.m_session end

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
	local packer = pfm.ProjectPacker()
	packer:AddSession(self:GetSession())
	packer:AddMap(game.get_map_name())
	-- TODO: Pack project file
	-- TODO: Pack audio files
	return packer:GetFiles()
end

pfm.create_project = function()
	local project = pfm.Project()
	table.insert(pfm.impl.projects,project)
	return project
end

pfm.create_empty_project = function()
	local project = pfm.create_project()
	local session = udm.create_property_from_schema(pfm.udm.SCHEMA,"Session")
	project:SetSession(session)
	
	local filmClip = session:AddClip()
	filmClip:SetName("new_project")
	session:SetActiveClip(filmClip)

	local trackGroup = filmClip:AddTrackGroup()
	trackGroup:SetName("subClipTrackGroup")

	local track = trackGroup:AddTrack()
	track:SetName("Film")

	local shot1 = track:AddFilmClip("shot1")
	shot1:GetTimeFrame():SetDuration(60.0)
	filmClip:GetTimeFrame():SetDuration(60.0)

	local channelTrackGroup = shot1:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")
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
		for _,trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _,track in ipairs(trackGroup:GetTracks()) do
				for _,filmClip in ipairs(track:GetFilmClips()) do
					get_film_clips(filmClip,filmClips)
				end
			end
		end
	end
	local filmClips = {}
	for _,clip in ipairs(session:GetClips()) do
		get_film_clips(clip,filmClips)
	end
	local filmClipList = {}
	for filmClip,_ in pairs(filmClips) do
		table.insert(filmClipList,filmClip)
	end

	local iteratedChannels = {}
	local function collect_actors(filmClip,actors)
		for _,trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _,track in ipairs(trackGroup:GetTracks()) do
				for _,channelClip in ipairs(track:GetChannelClips()) do
					for _,channel in ipairs(channelClip:GetChannels()) do
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

local colScheme = util.ColorScheme()
colScheme:SetColor("black",Color.CreateFromHexColor("000000"))
colScheme:SetColor("white",Color.CreateFromHexColor("ffffff"))
colScheme:SetColor("red",Color.CreateFromHexColor("ff3352"))
colScheme:SetColor("green",Color.CreateFromHexColor("8bdc00"))
colScheme:SetColor("blue",Color.CreateFromHexColor("2890ff"))
colScheme:SetColor("pink",Color.CreateFromHexColor("fcb8cb"))

colScheme:SetColor("lightRed",Color.CreateFromHexColor("fca3b0"))
colScheme:SetColor("lightGreen",Color.CreateFromHexColor("badf7b"))
colScheme:SetColor("lightBlue",Color.CreateFromHexColor("8bc3ff"))
colScheme:SetColor("orange",Color.CreateFromHexColor("ffc343"))

pfm.get_color_scheme = function()
	return colScheme
end

pfm.get_color_scheme_color = function(name)
	return colScheme:GetColor(name)
end

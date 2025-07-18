-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.impl = pfm.impl or {}

pfm.impl.projects = pfm.impl.projects or {}

pfm.PROJECT_FILE_IDENTIFIER = "PFM"
pfm.PROJECT_FILE_FORMAT_VERSION = 2

pfm.VERSION = util.Version(0, 8, 3)
pfm.VERSION_DATE = "24-05-12"
pfm.PROJECT_TITLE = "PFM"

include("/util/log.lua")
include("/util/color_scheme.lua")
include("/udm/schema_api.lua")
include("/sfm.lua")
include("udm")
include("math.lua")
include("unirender.lua")
include("message_popup.lua")
include("tree/pfm_tree.lua")
include("project_packer.lua")
include("undoredo.lua")
include("events.lua")

-- Load and initialize schema
pfm.udm = pfm.udm or {}
local schema, err = udm.Schema.load("pfm.udms")
if schema == false then
	console.print_warning("Failed to load PFM UDM schemas: " .. err)
	return
end
pfm.udm.SCHEMA = schema
pfm.udm.SCHEMA:SetLibrary(pfm.udm)

pfm.set_target_session = function(session)
	pfm.impl.targetSession = session
end

pfm.reference = function(o)
	return tostring(o:GetUniqueId())
end

pfm.dereference = function(val)
	if type(val) == "table" then
		for i, v in ipairs(val) do
			val[i] = pfm.dereference(v)
		end
		return val
	end
	local ref = pfm.Reference(val)
	local uuid = ref:GetUniqueId()

	local pm = pfm.get_project_manager()
	local session = pfm.impl.targetSession or ((pm ~= nil) and pm:GetSession() or nil)
	return udm.dereference(session:GetSchema(), uuid)
end

util.register_class("pfm.Reference")
function pfm.Reference:__init(val)
	local t = util.get_type_name(val)
	if t == "string" then
		self.m_uniqueId = val
	elseif t == "Reference" then
		self.m_uniqueId = val:GetUniqueId()
	elseif t == "Uuid" then
		self.m_uniqueId = tostring(val)
	else
		self.m_uniqueId = tostring(val:GetUniqueId())
	end
end
function pfm.Reference:GetUniqueId()
	return self.m_uniqueId
end
function pfm.Reference:GetValue() end
pfm.get_unique_id = function(val)
	return pfm.Reference(val):GetUniqueId()
end

local res, err = udm.generate_lua_api_from_schema(pfm.udm.SCHEMA, pfm.udm)
if res ~= true then
	console.print_warning("Failed to generate PFM UDM API: " .. err)
	return
end
--

pfm.udm.get_schema = function()
	return pfm.udm.SCHEMA
end

include("/udm/pfm_util")

util.register_class("pfm.Project")
pfm.Project.FORMAT_EXTENSION_BINARY = "pfmp_b"
pfm.Project.FORMAT_EXTENSION_ASCII = "pfmp"
pfm.Project.DEFAULT_BOOKMARK_SET_NAME = "default"
pfm.Project.KEYFRAME_BOOKMARK_SET_NAME = "keyframe"
pfm.Project.get_project_root_path = function()
	return "projects/"
end
pfm.Project.get_format_extensions = function()
	return { pfm.Project.FORMAT_EXTENSION_ASCII, pfm.Project.FORMAT_EXTENSION_BINARY }
end
pfm.Project.get_full_project_file_name = function(baseName, withProjectsPrefix, saveAsAscii)
	if withProjectsPrefix == nil then
		withProjectsPrefix = true
	end
	baseName = file.remove_file_extension(baseName, pfm.Project.get_format_extensions())
	local res = baseName
		.. "."
		.. (saveAsAscii and pfm.Project.FORMAT_EXTENSION_ASCII or pfm.Project.FORMAT_EXTENSION_BINARY)
	if withProjectsPrefix then
		res = "projects/" .. res
	end
	return res
end
function pfm.Project:__init()
	self:SetName("new_project")
end

function pfm.Project:SetName(name)
	self.m_projectName = name
end
function pfm.Project:GetName()
	return self.m_projectName
end

function pfm.Project:Close()
	if self.m_closed then
		return
	end
	self.m_closed = true
	self:GetSession():Remove()
end

function pfm.Project:SaveLegacy(fileName)
	local f = file.open(fileName, bit.bor(file.OPEN_MODE_WRITE, file.OPEN_MODE_BINARY))
	if f == nil then
		return false
	end

	f:WriteString(pfm.PROJECT_FILE_IDENTIFIER, false)
	f:WriteUInt32(pfm.PROJECT_FILE_FORMAT_VERSION)
	f:WriteUInt64(0) -- Placeholder for flags
	f:WriteString(self.m_uniqueId)

	local elements = {}
	local function collect_elements(el)
		elements[el] = true
		if el:IsElement() == false then
			return
		end
		for name, child in pairs(el:GetChildren()) do
			if elements[child] == nil then
				collect_elements(child)
			end
		end
	end
	collect_elements(self.m_udmRoot)

	local elementList = {}
	for el in pairs(elements) do
		-- References need to be first in the list
		if el:GetType() == fudm.ELEMENT_TYPE_REFERENCE then
			table.insert(elementList, 1, el)
		else
			table.insert(elementList, el)
		end
	end

	-- Save elements
	f:WriteUInt32(#elementList)
	for idx, el in ipairs(elementList) do
		elements[el] = idx - 1

		fudm.save(f, el)
	end

	-- Save child information
	for _, el in ipairs(elementList) do
		if el:IsElement() then
			local children = el:GetChildren()
			local numChildren = 0
			for _ in pairs(children) do
				numChildren = numChildren + 1
			end
			f:WriteUInt16(numChildren)
			for name, child in pairs(children) do
				f:WriteString(tostring(name))
				f:WriteUInt32(elements[child])
			end
		end
	end

	f:Close()
	return true
end

function pfm.Project:Save(fileName, legacy)
	local absPath = file.find_absolute_path(fileName)
	if absPath ~= nil then
		fileName = absPath
	end

	local saveAsAscii = (file.get_file_extension(fileName) == pfm.Project.FORMAT_EXTENSION_ASCII)
	if legacy then
		return self:SaveLegacy(fileName)
	end

	file.create_path(file.get_file_path(fileName))
	local fileMode = file.OPEN_MODE_WRITE
	if saveAsAscii == false then
		fileMode = bit.bor(fileMode, file.OPEN_MODE_BINARY)
	end
	local f, err = file.open(fileName, fileMode)
	if f == nil then
		return false, err
	end
	local udmData = udm.create("PFMP", 1)
	udmData:GetAssetData():GetData():SetValue("session", self:GetSession():GetRootUdmData())
	local res, err
	if saveAsAscii then
		res, err = udmData:SaveAscii(
			f,
			bit.bor(
				udm.ASCII_SAVE_FLAG_DEFAULT,
				udm.ASCII_SAVE_FLAG_BIT_INCLUDE_HEADER,
				udm.ASCII_SAVE_FLAG_BIT_DONT_COMPRESS_LZ4_ARRAYS
			)
		)
	else
		res, err = udmData:Save(f)
	end
	f:Close()
	if res == false then
		console.print_warning("Failed to save PFM project: " .. err)
		return false, err
	end

	return true
end

function pfm.Project:LoadLegacy(f, fileName)
	local ident = f:ReadString(#pfm.PROJECT_FILE_IDENTIFIER)
	if ident ~= pfm.PROJECT_FILE_IDENTIFIER then
		f:Close()
		return false
	end

	local version = f:ReadUInt32()
	if version < 1 or version > pfm.PROJECT_FILE_FORMAT_VERSION then
		f:Close()
		return false
	end

	local flags = f:ReadUInt64() -- Currently unused
	if version > 1 then
		self.m_uniqueId = f:ReadString()
	else
		self.m_uniqueId = util.get_string_hash(util.Path.CreateFilePath(fileName):GetString())
	end

	debug.start_profiling_task("pfm_load")
	local numElements = f:ReadUInt32()
	local elements = {}
	for i = 1, numElements do
		local el = fudm.load(f)
		table.insert(elements, el)
	end

	-- Read child information
	for _, el in ipairs(elements) do
		if el:IsElement() then
			local type = el:GetType()
			if type == fudm.ELEMENT_TYPE_ROOT then
				self.m_udmRoot = el
			end
			if type == fudm.ELEMENT_TYPE_PFM_SESSION then
				table.insert(self.m_sessions, el)
			end
			local numChildren = f:ReadUInt16()
			for i = 1, numChildren do
				local name = f:ReadString()
				local childIdx = f:ReadUInt32()
				local child = elements[childIdx + 1]
				if type == fudm.ELEMENT_TYPE_PFM_SESSION and name == "activeClip" then
					child = fudm.create_reference(child)
				end
				el:SetProperty(name, child)
			end
			el:OnLoaded()
		end
	end

	self.m_udmRoot:LoadFromBinary(f)
	f:Close()
	debug.stop_profiling_task()
	return true
end
function pfm.Project:LoadUdmData(fileName)
	local f = file.open(fileName, bit.bor(file.OPEN_MODE_READ, file.OPEN_MODE_BINARY))
	if f == nil then
		return false
	end

	local ident = f:ReadString(#pfm.PROJECT_FILE_IDENTIFIER)
	f:Seek(0)
	if ident == pfm.PROJECT_FILE_IDENTIFIER then
		return self:LoadLegacy(f, fileName)
	end
	debug.start_profiling_task("pfm_load")

	local udmFile, err = udm.load(f)
	f:Close()
	if udmFile == false then
		debug.stop_profiling_task()
		return false, err
	end
	return udmFile
end
function pfm.Project:Load(fileName, ignoreMap)
	local udmFile, err = self:LoadUdmData(fileName)
	if udmFile == false then
		return udmFile, err
	end
	local udmData = udmFile:GetAssetData():GetData()
	if udmData:Get("session"):IsValid() == false then
		debug.stop_profiling_task()
		return false, "Project file contains no session!"
	end
	local udmSession = udmData:Get("session"):ClaimOwnership()
	local udmSettings = udmSession:Get("settings")
	if ignoreMap ~= true then
		local mapName = udmSettings:GetValue("mapName", udm.TYPE_STRING)
		if mapName ~= nil then
			mapName = asset.get_normalized_path(mapName, asset.TYPE_MAP)
		end
		local curMapName = asset.get_normalized_path(game.get_map_name(), asset.TYPE_MAP)
		if mapName ~= nil and #mapName > 0 and curMapName ~= mapName then
			print(
				"Map of loaded project ("
					.. mapName
					.. ") does not match current map ("
					.. curMapName
					.. ")! Changing..."
			)
			pfm.get_project_manager():ChangeMap(mapName, fileName)
			return false
		end
	end
	local session = udm.create_property_from_schema(pfm.udm.SCHEMA, "Session", nil, udmSession)
	debug.stop_profiling_task()

	self.m_session = session
	return true
end

function pfm.Project:SetSession(session)
	self.m_session = session
end
function pfm.Project:GetSession()
	return self.m_session
end

function pfm.Project:GetUDMRootNode()
	return self.m_udmRoot
end

function pfm.Project:DebugPrint(node, t, name)
	if node == nil then
		self:DebugPrint(self:GetUDMRootNode(), t, name)
		return
	end
	node:DebugPrint(t, name)
end

function pfm.Project:DebugDump(f, node, t, name)
	if node == nil then
		self:DebugDump(f, self:GetUDMRootNode(), t, name)
		return
	end
	node:DebugDump(f, t, name)
end

function pfm.Project:CollectAssetFiles()
	local packer = pfm.ProjectPacker()
	packer:AddSession(self:GetSession())
	packer:AddMap(game.get_map_name())
	-- TODO: Pack project file
	return packer:GetFiles()
end

pfm.create_project = function()
	local project = pfm.Project()
	table.insert(pfm.impl.projects, project)
	return project
end

pfm.create_empty_project = function()
	local project = pfm.create_project()
	local session = udm.create_property_from_schema(pfm.udm.SCHEMA, "Session")
	project:SetSession(session)

	local filmClip = session:AddClip()
	filmClip:SetName("new_project")

	-- Default bookmark set
	local bms = filmClip:AddBookmarkSet()
	bms:SetName(pfm.Project.DEFAULT_BOOKMARK_SET_NAME)
	filmClip:SetActiveBookmarkSet(bms)

	session:SetActiveClip(filmClip)

	local trackGroup = filmClip:AddTrackGroup()
	trackGroup:SetName("subClipTrackGroup")

	local track = trackGroup:AddTrack()
	track:SetName("Film")

	local shot1 = track:AddFilmClip()
	shot1:SetName("shot1")
	shot1:GetTimeFrame():SetDuration(60.0)
	filmClip:GetTimeFrame():SetDuration(60.0)

	local channelTrackGroup = shot1:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")
	return project
end

pfm.load_project = function(fileName, ignoreMap)
	local project = pfm.create_project()
	local res, err = project:Load(fileName, ignoreMap)
	if res == false then
		return res, err
	end
	return project
end

pfm.get_projects = function()
	return pfm.impl.projects
end

pfm.clear_static_geometry_cache = function()
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		pm:ClearStaticGeometryCache()
	end
end

pfm.get_git_sha = function(gitInfoFileName, len)
	len = len or 7
	local gitInfo = file.read(gitInfoFileName)
	if gitInfo == nil then
		return
	end
	local pos = gitInfo:find("commit:")
	if pos == nil then
		return
	end
	local sha = gitInfo:sub(pos + 7, pos + (7 + len))
	sha = string.remove_whitespace(sha)
	return sha
end

pfm.get_key_binding = function(cmd)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		for id, layer in pairs(pm:GetInputBindingLayers()) do
			local boundKeys = layer:FindBoundKeys(cmd)
			if #boundKeys > 0 then
				return boundKeys[1]:upper()
			end
		end
	end
	return locale.get_text("unbound")
end

pfm.get_project_manager = function()
	return pfm.impl.projectManager
end
pfm.set_project_manager = function(pm)
	pfm.impl.projectManager = pm
end

pfm.is_editor = function()
	local pm = pfm.get_project_manager()
	if util.is_valid(pm) == false then
		return false
	end
	return pm:IsEditor()
end

pfm.tag_render_scene_as_dirty = function(dirty)
	local pm = pfm.get_project_manager()
	if util.is_valid(pm) == false or pm.TagRenderSceneAsDirty == nil then
		return
	end
	pm:TagRenderSceneAsDirty(dirty)
end

pfm.translate_flex_controller_value = function(fc, val)
	return fc.min + val * (fc.max - fc.min)
end

pfm.is_animated_model = function(mdl)
	local isAnimatedActor = false
	for _, meshGroup in ipairs(mdl:GetMeshGroups()) do
		for _, mesh in ipairs(meshGroup:GetMeshes()) do
			for _, subMesh in ipairs(mesh:GetSubMeshes()) do
				if subMesh:HasVertexWeights() then
					-- Check if any vertices are weighted to more than one bone. If there aren't any,
					-- we'll assume it's a static actor.
					for _, vw in ipairs(subMesh:GetVertexWeights()) do
						local n = 0
						for i = 1, 4 do
							if vw.boneIds:Get(i - 1) ~= -1 then
								n = n + 1
							end
						end
						if n > 1 then
							isAnimatedActor = true
							break
						end
					end
				end
				if isAnimatedActor then
					break
				end
			end
			if isAnimatedActor then
				break
			end
		end
		if isAnimatedActor then
			break
		end
	end
	return isAnimatedActor
end

pfm.is_character_model = function(mdl)
	if
		mdl:GetEyeballCount() > 0 --[[or #mdl:GetPhonemes() > 0]]
	then
		return true
	end
	return false
end

pfm.is_articulated_model = function(mdl)
	if mdl:GetMetaRig() ~= nil then
		return true
	end
	local isArticulatedActor = (mdl:GetFlexCount() > 0)
	if isArticulatedActor then
		return true
	end
	return pfm.is_animated_model(mdl)
end

pfm.find_inanimate_actors = function(session)
	local function get_film_clips(filmClip, filmClips)
		filmClips[filmClip] = true
		for _, trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _, track in ipairs(trackGroup:GetTracks()) do
				for _, filmClip in ipairs(track:GetFilmClips()) do
					get_film_clips(filmClip, filmClips)
				end
			end
		end
	end
	local filmClips = {}
	for _, clip in ipairs(session:GetClips()) do
		get_film_clips(clip, filmClips)
	end
	local filmClipList = {}
	for filmClip, _ in pairs(filmClips) do
		table.insert(filmClipList, filmClip)
	end

	local iteratedChannels = {}
	local function collect_actors(filmClip, actors)
		local scene = filmClip:GetScene()
		for _, actor in ipairs(scene:GetActors()) do
			actors[actor] = 0
		end
		for _, trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _, track in ipairs(trackGroup:GetTracks()) do
				for _, channelClip in ipairs(track:GetAnimationClips()) do
					local anim = channelClip:GetAnimation()
					local actor = channelClip:GetActor()
					if anim ~= nil and actor ~= nil and actor:IsVisible() then
						local numValues = 0
						for _, channel in ipairs(anim:GetChannels()) do
							numValues = numValues + channel:GetValueCount()
						end
						actors[actor] = numValues
					end
				end
			end
		end
	end
	local actors = {}
	for _, filmClip in ipairs(filmClipList) do
		collect_actors(filmClip, actors)
	end

	local actorList = {}
	for actor, numValues in pairs(actors) do
		if numValues <= 1 then
			table.insert(actorList, actor)
		end
	end
	return actorList
end

local colScheme = util.ColorScheme()
colScheme:SetColor("black", Color.CreateFromHexColor("000000"))
colScheme:SetColor("grey", Color.CreateFromHexColor("363636"))
colScheme:SetColor("darkGrey", Color.CreateFromHexColor("262626"))
colScheme:SetColor("white", Color.CreateFromHexColor("ffffff"))
colScheme:SetColor("red", Color.CreateFromHexColor("ff3352"))
colScheme:SetColor("green", Color.CreateFromHexColor("8bdc00"))
colScheme:SetColor("blue", Color.CreateFromHexColor("2890ff"))
colScheme:SetColor("pink", Color.CreateFromHexColor("fcb8cb"))
colScheme:SetColor("intenseRed", Color.CreateFromHexColor("FF0C0C"))
colScheme:SetColor("intenseGreen", Color.CreateFromHexColor("13E013"))
colScheme:SetColor("intenseBlue", Color.CreateFromHexColor("0056E0"))

colScheme:SetColor("lightRed", Color.CreateFromHexColor("fca3b0"))
colScheme:SetColor("lightGreen", Color.CreateFromHexColor("badf7b"))
colScheme:SetColor("lightBlue", Color.CreateFromHexColor("8bc3ff"))
colScheme:SetColor("orange", Color.CreateFromHexColor("ffc343"))
colScheme:SetColor("darkOrange", Color.CreateFromHexColor("ff8c00"))

colScheme:SetColor("turquoise", Color.CreateFromHexColor("00ffff"))
colScheme:SetColor("yellow", Color.CreateFromHexColor("ffff00"))
colScheme:SetColor("pink", Color.CreateFromHexColor("ff00ff"))

colScheme:SetColor("rawRed", Color.CreateFromHexColor("ff0000"))
colScheme:SetColor("rawGreen", Color.CreateFromHexColor("00ff00"))
colScheme:SetColor("rawBlue", Color.CreateFromHexColor("0000ff"))

colScheme:SetColor("yellow2", Color.CreateFromHexColor("eec94b"))

pfm.get_color_scheme = function()
	return colScheme
end

pfm.get_color_scheme_color = function(name)
	return colScheme:GetColor(name)
end

util.register_class("pfm.LocStr")
function pfm.LocStr:__init(locId, args)
	self.m_localeId = locId
	self.m_localeArgs = args
end
function pfm.LocStr:GetLocaleIdentifier()
	return self.m_localeId
end
function pfm.LocStr:GetText(args)
	return locale.get_text(self.m_localeId, args or self.m_localeArgs or {})
end

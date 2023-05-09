--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.FileIndexTable")

util.register_class("pfm.FileIndexTable.Indexer")
function pfm.FileIndexTable.Indexer:__init(fit, extensions, externalExtensions)
	self.m_fit = fit
	self.m_queue = {}
	self.m_traversed = {}
	self.m_maxQueueCount = 0

	self.m_extensions = {}
	for _, ext in ipairs(extensions) do
		self.m_extensions[ext] = true
	end

	self.m_externalExtensions = {}
	for _, ext in ipairs(externalExtensions) do
		self.m_externalExtensions[ext] = true
	end

	self.m_allExtensions = {}
	for ext, _ in pairs(self.m_extensions) do
		self.m_allExtensions[ext] = true
	end
	for ext, _ in pairs(self.m_externalExtensions) do
		self.m_allExtensions[ext] = true
	end
end
function pfm.FileIndexTable.Indexer:GetRootPath()
	return self.m_fit:GetRootPath()
end
function pfm.FileIndexTable.Indexer:Start()
	if util.is_valid(self.m_cbThink) then
		return
	end
	self.m_cbThink = game.add_callback("Think", function()
		if self:RunBatch() then
			self:Stop()
			self.m_fit:OnIndexerComplete()

			print("File index table for '" .. self.m_fit:GetName() .. "' has been generated!")
		end
	end)
end
function pfm.FileIndexTable.Indexer:Stop()
	if util.is_valid(self.m_cbThink) then
		self.m_cbThink:Remove()
	end
end
function pfm.FileIndexTable.Indexer:RunBatch()
	local numBatches = 50
	while #self.m_queue > 0 and numBatches > 0 do
		local path = self.m_queue[1]
		self:CollectFiles(path)
		table.remove(self.m_queue, 1)
		numBatches = numBatches - 1

		self:UpdateProgress()
	end
	self:UpdateProgress()
	return #self.m_queue == 0
end
function pfm.FileIndexTable.Indexer:UpdateProgress()
	local progress
	if self.m_maxQueueCount == 0 then
		progress = 1
	else
		progress = 1 - (#self.m_queue / self.m_maxQueueCount)
	end
	self.m_fit:OnProgressChanged(progress)
end
function pfm.FileIndexTable.Indexer:CollectSubFiles(path, tFiles, tDirs, extensions, isAddonPath)
	for _, f in ipairs(tFiles) do
		local ext = file.get_file_extension(f)
		if ext ~= nil and extensions[ext] == true then
			f = file.remove_file_extension(f)
			if self.m_traversed[path .. f] == nil then
				self.m_traversed[path .. f] = true
				local relPath = path
				if isAddonPath then
					relPath = util.Path.CreatePath(path)
					relPath:PopFront()
					relPath:PopFront()
					relPath = relPath:GetString()
				end
				self.m_fit:AddFile(relPath .. f)
			end
		end
	end
	for _, d in ipairs(tDirs) do
		table.insert(self.m_queue, path .. d .. "/")
		self.m_maxQueueCount = math.max(self.m_maxQueueCount, #self.m_queue)
	end
end
function pfm.FileIndexTable.Indexer:CollectFiles(path)
	if self.m_traversed[path] ~= nil then
		return
	end
	self.m_traversed[path] = true

	local tFiles, tDirs = file.find(path .. "*")
	local isAddonPath = (path:sub(0, 7) == "addons/")
	self:CollectSubFiles(path, tFiles, tDirs, isAddonPath and self.m_allExtensions or self.m_extensions, isAddonPath)
	if isAddonPath then
		return
	end
	tFiles, tDirs = file.find_external_game_asset_files(path .. "*")
	self:CollectSubFiles(path, tFiles, tDirs, self.m_externalExtensions)
end
function pfm.FileIndexTable.Indexer:AddToQueue(path)
	table.insert(self.m_queue, path)
end

function pfm.FileIndexTable:__init(name, rootPath, extensions, externalExtensions)
	self.m_name = name
	self.m_rootPath = rootPath
	self.m_extensions = extensions
	self.m_externalExtensions = externalExtensions

	self.m_tFileNames = {}
	self.m_tFilePaths = {}
	self.m_tFileHashes = {}

	self.m_tPaths = {}
	self.m_tPathToIndex = {}
	self.m_initialized = false
end
function pfm.FileIndexTable:Remove()
	if self.m_indexer ~= nil then
		self.m_indexer:Stop()
	end
end
function pfm.FileIndexTable:GetRootPath()
	return self.m_rootPath
end
function pfm.FileIndexTable:GetName()
	return self.m_name
end
function pfm.FileIndexTable:GetCacheFileName()
	return "cache/pfm/file_index_table_" .. self:GetName() .. ".fit_b"
end
function pfm.FileIndexTable:GetFileNames()
	return self.m_tFileNames
end
function pfm.FileIndexTable:GetFilePaths()
	return self.m_tFilePaths
end
function pfm.FileIndexTable:GetFileHashes()
	return self.m_tFileHashes
end
function pfm.FileIndexTable:GetFileName(i)
	return self.m_tFileNames[i]
end
function pfm.FileIndexTable:GetFilePath(i)
	return self.m_tPaths[self.m_tFilePaths[i]]
end
function pfm.FileIndexTable:OnProgressChanged(progress)
	if util.is_valid(self.m_progressBar) then
		self.m_progressBar:SetProgress(progress)
	end
end
function pfm.FileIndexTable:AddFile(fileName)
	local npath = util.Path.CreateFilePath(fileName)
	local hash = tonumber(util.get_string_hash(npath:GetString()))
	if self.m_tFileHashes[hash] ~= nil then
		return
	end -- Duplicate file
	self.m_tFileHashes[hash] = #self.m_tFileNames + 1

	local path = npath:GetPath()
	fileName = npath:GetFileName()

	table.insert(self.m_tFileNames, fileName)

	if self.m_tPathToIndex[path] == nil then
		table.insert(self.m_tPaths, path)
		self.m_tPathToIndex[path] = #self.m_tPaths
	end
	table.insert(self.m_tFilePaths, self.m_tPathToIndex[path])
end
local FORMAT_IDENTIFIER = "PFIT"
local FORMAT_VERSION = 1
function pfm.FileIndexTable:LoadFromCache()
	local f = file.open(self:GetCacheFileName(), bit.bor(file.OPEN_MODE_READ, file.OPEN_MODE_BINARY))
	if f == nil then
		pfm.log(
			"Unable to load file index table: File '" .. self:GetCacheFileName() .. "' not found!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end

	local udmData, err = udm.load(f)
	f:Close()
	if udmData == false then
		pfm.log("Failed to load file index table: " .. err, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local assetData = udmData:GetAssetData()
	assetData = assetData:GetData()

	self.m_tPaths = assetData:GetArrayValues("pathTable", udm.TYPE_STRING)
	self.m_tFileNames = assetData:GetArrayValues("fileTable", udm.TYPE_STRING)
	self.m_tFilePaths = assetData:GetArrayValues("filePathIndices", udm.TYPE_UINT32)
	local tHashes = assetData:GetArrayValues("fileHashes", udm.TYPE_UINT64)
	self.m_tFileHashes = {}
	for i, hash in ipairs(tHashes) do
		self.m_tFileHashes[hash] = i
	end
	return true
end
function pfm.FileIndexTable:SaveToCache()
	file.create_path(file.get_file_path(self:GetCacheFileName()))

	local udmData, err = udm.create(FORMAT_IDENTIFIER, FORMAT_VERSION)
	if udmData == false then
		pfm.log(
			"Unable to save file index table '" .. self:GetCacheFileName() .. "': " .. err,
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end

	local assetData = udmData:GetAssetData():GetData()
	assetData:SetArrayValues("pathTable", udm.TYPE_STRING, self.m_tPaths, udm.TYPE_ARRAY_LZ4)
	assetData:SetArrayValues("fileTable", udm.TYPE_STRING, self.m_tFileNames, udm.TYPE_ARRAY_LZ4)
	assetData:SetArrayValues("filePathIndices", udm.TYPE_UINT32, self.m_tFilePaths, udm.TYPE_ARRAY_LZ4)

	local tHashes = {}
	for hash, i in pairs(self.m_tFileHashes) do
		tHashes[i] = hash
	end
	assetData:SetArrayValues("fileHashes", udm.TYPE_UINT64, tHashes, udm.TYPE_ARRAY_LZ4)

	--[[
	-- TODO: Use a file map once Array:Reserve and compressed elements have been implemented for UDM
	local testFileMap = {}
	for i,n in ipairs(self.m_tFileNames) do
		local p = self.m_tPaths[self.m_tFilePaths[i] ]
		p = p:sub(1,-2)
		local components = string.split(p,"/")
		local t = testFileMap
		for _,c in ipairs(components) do
			t[c] = t[c] or {}
			if(type(t[c]) == "string") then t[c] = {} end -- There's a file and a directory with the same name; Prioritize the directory
			t = t[c]
		end
		table.insert(t,n)
	end

	-- TODO: Compress?
	local function addDir(udmParent,dirData)
		for name,sub in pairs(dirData) do
			if(type(sub) == "string") then
				print(udmParent,name,sub)
				udmParent:SetValue(name,sub)
			else
				local udmChild = udmParent:Get(name)
				print("udmChild: ",udmChild,udmChild:IsValid())
				if(udmChild:IsValid() == false) then udmChild = udmParent:Add(name) end
				addDir(udmChild,sub)
			end
		end
	end
	addDir(assetData,testFileMap)]]

	local f = file.open(self:GetCacheFileName(), bit.bor(file.OPEN_MODE_WRITE, file.OPEN_MODE_BINARY))
	if f == nil then
		pfm.log(
			"Unable to open file '" .. self:GetCacheFileName() .. "' for writing!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end
	local res, err = udmData:Save(f)
	f:Close()
	if res == false then
		pfm.log(
			"Failed to save file index table as '" .. self:GetCacheFileName() .. "': " .. err,
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end
	return true
end
function pfm.FileIndexTable:__finalize()
	util.remove(self.m_progressBar)
end
function pfm.FileIndexTable:OnIndexerComplete()
	self:SaveToCache()
	util.remove(self.m_progressBar)
end
function pfm.FileIndexTable:InitializeIndexer()
	if self.m_indexer ~= nil then
		return self.m_indexer
	end
	self.m_indexer = pfm.FileIndexTable.Indexer(self, self.m_extensions, self.m_externalExtensions)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) then
		self.m_progressBar =
			pm:AddProgressStatusBar("fit_" .. self:GetName(), locale.get_text("pfm_generate_fit", { self:GetName() }))
	end
	return self.m_indexer
end
function pfm.FileIndexTable:ReloadPath(path)
	local indexer = self:InitializeIndexer()
	indexer:AddToQueue(path)
	indexer:Start()
end
function pfm.FileIndexTable:LoadOrGenerate()
	if self.m_initialized then
		return
	end
	self.m_initialized = true
	if self:LoadFromCache() == true then
		return
	end
	print("No file index table found for '" .. self:GetName() .. "'! Generating...")
	pfm.create_popup_message(
		"Generating '" .. self:GetName() .. "' file index cache. This may cause PFM to run slowly for a few minutes.",
		3
	)
	self:Generate()
end
function pfm.FileIndexTable:Generate()
	self:ReloadPath(self:GetRootPath())
end

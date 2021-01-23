--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.FileIndexTable")

util.register_class("pfm.FileIndexTable.Indexer")
function pfm.FileIndexTable.Indexer:__init(fit,extensions,externalExtensions)
	self.m_fit = fit
	self.m_queue = {}
	self.m_traversed = {}

	self.m_extensions = {}
	for _,ext in ipairs(extensions) do
		self.m_extensions[ext] = true
	end

	self.m_externalExtensions = {}
	for _,ext in ipairs(externalExtensions) do
		self.m_externalExtensions[ext] = true
	end

	self.m_allExtensions = {}
	for ext,_ in pairs(self.m_extensions) do self.m_allExtensions[ext] = true end
	for ext,_ in pairs(self.m_externalExtensions) do self.m_allExtensions[ext] = true end
end
function pfm.FileIndexTable.Indexer:GetRootPath() return self.m_fit:GetRootPath() end
function pfm.FileIndexTable.Indexer:Start()
	self.m_cbThink = game.add_callback("Think",function()
		if(self:RunBatch()) then
			self:Stop()
			self.m_fit:OnIndexerComplete()
		end
	end)
end
function pfm.FileIndexTable.Indexer:Stop()
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove() end
end
function pfm.FileIndexTable.Indexer:RunBatch()
	local numBatches = 5
	while(#self.m_queue > 0 and numBatches > 0) do
		local path = self.m_queue[1]
		self:CollectFiles(path)
		table.remove(self.m_queue,1)
		numBatches = numBatches -1
	end
	return #self.m_queue == 0
end
function pfm.FileIndexTable.Indexer:CollectSubFiles(path,tFiles,tDirs,extensions,isAddonPath)
	for _,f in ipairs(tFiles) do
		local ext = file.get_file_extension(f)
		if(ext ~= nil and extensions[ext] == true) then
			f = file.remove_file_extension(f)
			if(self.m_traversed[path .. f] == nil) then
				self.m_traversed[path .. f] = true
				local relPath = path
				if(isAddonPath) then
					relPath = util.Path.CreatePath(path)
					relPath:PopFront()
					relPath:PopFront()
					relPath = relPath:GetString()
				end
				self.m_fit:AddFile(relPath .. f)
			end
		end
	end
	for _,d in ipairs(tDirs) do
		table.insert(self.m_queue,path .. d .. "/")
	end
end
function pfm.FileIndexTable.Indexer:CollectFiles(path)
	if(self.m_traversed[path] ~= nil) then return end
	self.m_traversed[path] = true

	local tFiles,tDirs = file.find(path .. "*")
	local isAddonPath = (path:sub(0,7) == "addons/")
	self:CollectSubFiles(path,tFiles,tDirs,isAddonPath and self.m_allExtensions or self.m_extensions,isAddonPath)
	if(isAddonPath) then return end
	tFiles,tDirs = file.find_external_game_asset_files(path .. "*")
	self:CollectSubFiles(path,tFiles,tDirs,self.m_externalExtensions)
end
function pfm.FileIndexTable.Indexer:AddToQueue(path)
	table.insert(self.m_queue,path)
end



function pfm.FileIndexTable:__init(name,rootPath,extensions,externalExtensions)
	self.m_name = name
	self.m_rootPath = rootPath
	self.m_extensions = extensions
	self.m_externalExtensions = externalExtensions

	self.m_tFileNames = {}
	self.m_tFilePaths = {}

	self.m_tPaths = {}
	self.m_tPathToIndex = {}
	self.m_initialized = false
end
function pfm.FileIndexTable:Remove()
	if(self.m_indexer ~= nil) then self.m_indexer:Stop() end
end
function pfm.FileIndexTable:GetRootPath() return self.m_rootPath end
function pfm.FileIndexTable:GetName() return self.m_name end
function pfm.FileIndexTable:GetCacheFileName() return "cache/pfm/file_index_table_" .. self:GetName() .. ".bin" end
function pfm.FileIndexTable:GetFileNames() return self.m_tFileNames end
function pfm.FileIndexTable:GetFilePaths() return self.m_tFilePaths end
function pfm.FileIndexTable:GetFileName(i) return self.m_tFileNames[i] end
function pfm.FileIndexTable:GetFilePath(i) return self.m_tPaths[self.m_tFilePaths[i]] end
function pfm.FileIndexTable:AddFile(fileName)
	local path = file.get_file_path(fileName)
	fileName = file.get_file_name(fileName)
	table.insert(self.m_tFileNames,fileName)

	if(self.m_tPathToIndex[path] == nil) then
		table.insert(self.m_tPaths,path)
		self.m_tPathToIndex[path] = #self.m_tPaths
	end
	table.insert(self.m_tFilePaths,self.m_tPathToIndex[path])
end
function pfm.FileIndexTable:LoadFromCache()
	local f = file.open(self:GetCacheFileName(),bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	print("Loading file index table '" .. self:GetName() .. "' from cache...")
	local id = f:ReadString(6)
	if(id ~= "PFMFIT") then return false end
	local version = f:ReadUInt32()
	if(version < 0 or version > 0) then return false end
	local numFileNames = f:ReadUInt32()
	for i=1,numFileNames do
		table.insert(self.m_tFileNames,f:ReadString())
		table.insert(self.m_tFilePaths,f:ReadUInt32())
	end

	local numPaths = f:ReadUInt32()
	for i=1,numPaths do
		table.insert(self.m_tPaths,f:ReadString())
	end
	f:Close()
	return true
end
function pfm.FileIndexTable:SaveToCache()
	file.create_path(file.get_file_path(self:GetCacheFileName()))
	local f = file.open(self:GetCacheFileName(),bit.bor(file.OPEN_MODE_WRITE,file.OPEN_MODE_BINARY))
	if(f == nil) then return false end
	print("Saving file index table '" .. self:GetName() .. "' to cache...")
	f:WriteString("PFMFIT",false)
	f:WriteUInt32(0)
	f:WriteUInt32(#self.m_tFileNames)
	for i=1,#self.m_tFileNames do
		f:WriteString(self.m_tFileNames[i])
		f:WriteUInt32(self.m_tFilePaths[i])
	end

	f:WriteUInt32(#self.m_tPaths)
	for _,path in ipairs(self.m_tPaths) do
		f:WriteString(path)
	end
	f:Close()
	return true
end
function pfm.FileIndexTable:OnIndexerComplete()
	self:SaveToCache()
end
function pfm.FileIndexTable:InitializeIndexer()
	if(self.m_indexer ~= nil) then return self.m_indexer end
	self.m_indexer = pfm.FileIndexTable.Indexer(self,self.m_extensions,self.m_externalExtensions)
	return self.m_indexer
end
function pfm.FileIndexTable:ReloadPath(path)
	local indexer = self:InitializeIndexer()
	indexer:AddToQueue(path)
	indexer:Start()
end
function pfm.FileIndexTable:LoadOrGenerate()
	if(self.m_initialized) then return end
	self.m_initialized = true
	if(self:LoadFromCache() == true) then return end
	print("No file index table found for '" .. self:GetName() .. "'! Generating...")
	self:Generate()
end
function pfm.FileIndexTable:Generate()
	self:ReloadPath(self:GetRootPath())
end

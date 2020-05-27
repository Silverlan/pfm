--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/gridbox.lua")
include("/gui/wibasefileexplorer.lua")
include("/gui/asseticon.lua")
include("/gui/icongridview.lua")

util.register_class("gui.AssetExplorer",gui.IconGridView,gui.BaseFileExplorer)
function gui.AssetExplorer:__init()
	gui.IconGridView.__init(self)
	gui.BaseFileExplorer.__init(self)
end
function gui.AssetExplorer:OnInitialize()
	gui.IconGridView.OnInitialize(self)

	self.m_favorites = {} -- TODO: Load/Save from/to file
	self:AddCallback("OnIconSelected",function(self,icon)
		self:CallCallbacks("OnFileClicked",icon:GetText())
	end)
	self:AddCallback("PopulateContextMenu",function(self,pContext)
		pContext:AddItem(locale.get_text("pfm_asset_import_all"),function()
			for _,icon in ipairs(self:GetIcons()) do
				if(icon:IsValid() and icon:IsDirectory() == false) then
					local assetPath = util.Path(icon:GetAsset())
					assetPath:PopFront()
					if(asset.exists(assetPath:GetString(),self:GetAssetType()) == false) then
						icon:Reload(true)
					end
				end
			end
			self:Refresh()
		end)
	end)

	self:SetIconFactory(function(parent)
		return gui.create("WIAssetIcon",parent)
	end)
	self:SetFileFinder(function(path)
		local tFiles,tDirs = file.find(path)

		local tFilesExtUnique = {}
		for _,f in ipairs(tFiles) do
			f = file.remove_file_extension(f) .. "." .. self.m_extension
			tFilesExtUnique[f] = true
		end

		local tFilesExt,tDirsExt = file.find_external_game_asset_files(path .. "*")

		local function add_files(tFiles)
			for _,f in ipairs(tFiles) do
				f = file.remove_file_extension(f) .. "." .. self.m_extension
				tFilesExtUnique[f] = true
			end
		end
		for _,ext in ipairs(self.m_extExtensions) do
			add_files(file.find_external_game_asset_files(path .. "." .. ext))
		end
		
		local tDirsExtUnique = {}
		for _,f in ipairs(tDirsExt) do
			tDirsExtUnique[f] = true
		end
		for _,f in ipairs(tDirs) do
			tDirsExtUnique[f] = true
		end
		
		tFiles = {}
		tDirs = {}
		for f,_ in pairs(tFilesExtUnique) do
			table.insert(tFiles,f)
		end
		table.sort(tFiles)
		
		for d,_ in pairs(tDirsExtUnique) do
			table.insert(tDirs,d)
		end
		table.sort(tDirs)
		return tFiles,tDirs
	end)
end
function gui.AssetExplorer:SetAssetType(type) self.m_assetType = type end
function gui.AssetExplorer:GetAssetType() return self.m_assetType end
function gui.AssetExplorer:SetFileExtensions(extension,extExtensions)
	self.m_extension = extension
	self.m_extExtensions = extExtensions
end
function gui.AssetExplorer:AddToFavorites(mdl)
	self.m_favorites[mdl] = true
end
function gui.AssetExplorer:IsInFavorites(mdl)
	return self.m_favorites[mdl] == true
end
function gui.AssetExplorer:RemoveFromFavorites(mdl)
	self.m_favorites[mdl] = nil
end
function gui.AssetExplorer:GetFavorites() return self.m_favorites end
function gui.AssetExplorer:OnUpdate()
	self:ListFiles()
end
function gui.AssetExplorer:AddIcon(assetName,isDirectory,fDirClickHandler)
	if(#assetName == 0) then return end
	local el = gui.IconGridView.AddIcon(self,assetName)
	if(el == nil) then return end
	local path
	local isAbsolutePath = (assetName:sub(1,1) == "/")
	if(isAbsolutePath) then
		assetName = assetName:sub(2)
		path = file.get_file_path(assetName)
		assetName = file.get_file_name(assetName)
	else path = self:GetAbsolutePath() end

	el:SetAsset(path,assetName,isDirectory)

	if(el:IsDirectory()) then
		el:AddCallback("OnDoubleClick",function(el)
			if(util.is_valid(self) == false) then return end
			if(fDirClickHandler ~= nil) then fDirClickHandler()
			else
				local relPath = util.Path(path)
				relPath:MakeRelative(self:GetRootPath())
				self:SetPath(relPath:GetString() .. assetName)
				self:Update()
			end
			--self:CallCallbacks("OnFileSelected",fPath)
		end)
	else
		if(el:GetAssetType() == asset.TYPE_PARTICLE_SYSTEM) then
			el:AddCallback("OnDoubleClick",function(el)
				if(util.is_valid(self) == false) then return end
				local ptFileName,ptName = el:GetParticleSystemFileName()
				if(ptFileName ~= nil) then
					tool.get_filmmaker():OpenParticleEditor(ptFileName,ptName)
					return
				end
				local ptPath = util.Path(el:GetAsset())
				ptPath:PopFront()
				if(asset.exists(ptPath:GetString(),asset.TYPE_PARTICLE_SYSTEM) == false) then
					-- Attempt to import the particle system from a Source Engine PCF file
					-- TODO: This should be done automatically by 'precache_particle_system'!
					local sePath = util.Path(ptPath)
					sePath:RemoveFileExtension()
					sePath = sePath +".pcf"
					sfm.convert_particle_systems("particles/" .. sePath:GetString())
				end
				game.precache_particle_system(ptPath:GetString())

				local relPath = util.Path(path)
				relPath:MakeRelative(self:GetRootPath())
				self:SetPath(relPath:GetString() .. assetName)
				self:Update()
			end)
		end
		el:AddCallback("PopulateContextMenu",function(el,pContext)
			local tSelected = self:GetSelectedIcons()
			local tSelectedDirs = {}
			local tSelectedFiles = {}
			local tExternalFiles = {}

			local numInFavorites = 0
			if(self:IsIconSelected(el) == false) then tSelected = {el} end
			for _,el in ipairs(tSelected) do
				local path = el:GetRelativeAsset()
				if(self:IsInFavorites(path)) then numInFavorites = numInFavorites +1 end
				if(el:IsDirectory()) then table.insert(tSelectedDirs,el)
				else
					table.insert(tSelectedFiles,el)
					if(asset.exists(path,self:GetAssetType()) == false) then
						table.insert(tExternalFiles,el)
					end
				end
			end

			if(#tExternalFiles > 0) then
				pContext:AddItem(locale.get_text("pfm_asset_import"),function()
					for _,el in ipairs(tExternalFiles) do
						if(el:IsValid()) then
							el:Reload(true)
						end
					end
				end)
			else
				pContext:AddItem(locale.get_text("pfm_asset_icon_reload"),function()
					for _,el in ipairs(tSelectedFiles) do
						if(el:IsValid()) then
							el:Reload()
						end
					end
				end)
			end

			if(#tSelectedFiles > 0) then
				pContext:AddItem(locale.get_text("pfm_asset_export"),function()
					local exportSuccessful = false
					for _,el in ipairs(tSelectedFiles) do
						if(el:IsValid()) then
							local path = el:GetRelativeAsset()
							if(asset.exists(path,self:GetAssetType()) == false) then
								el:Reload(true)
							end
							local result,err = self:ExportAsset(path)
							if(result) then exportSuccessful = true
							else console.print_warning("Unable to export asset: ",err) end
						end
					end
					if(exportSuccessful) then
						if(#tSelectedFiles == 1) then
							local path = tSelectedFiles[1]:GetRelativeAsset()
							util.open_path_in_explorer("export/" .. file.remove_file_extension(path))
						else
							util.open_path_in_explorer("export/")
						end
					end
				end)
			end

			if(numInFavorites == #tSelected) then
				pContext:AddItem(locale.get_text("pfm_asset_icon_remove_from_favorites"),function()
					for _,el in ipairs(tSelected) do
						if(el:IsValid()) then
							local path = el:GetRelativeAsset()
							self:RemoveFromFavorites(path)
							if(self.m_inFavorites) then
								self:ReloadPath()
								self:ScheduleUpdate()
							end
						end
					end
				end)
			else
				pContext:AddItem(locale.get_text("pfm_asset_icon_add_to_favorites"),function()
					for _,el in ipairs(tSelected) do
						if(el:IsValid()) then
							local path = el:GetRelativeAsset()
							self:AddToFavorites(path)
						end
					end
				end)
			end
			if(#tSelectedFiles == 1) then
				local assetPath = tSelectedFiles[1]:GetAsset()
				pContext:AddItem(locale.get_text("pfm_copy_path"),function()
					util.set_clipboard_string(assetPath .. "." .. self.m_extension)
				end)

				local path = tSelectedFiles[1]:GetRelativeAsset()
				if(asset.exists(path,self:GetAssetType())) then
					pContext:AddItem(locale.get_text("pfm_open_in_explorer"),function()
						util.open_path_in_explorer(file.get_file_path(assetPath),file.get_file_name(assetPath) .. "." .. self.m_extension)
					end)
				end
			end
			self:PopulateContextMenu(pContext,tSelectedFiles)
		end)
	end
	return el
end
function gui.AssetExplorer:PopulateContextMenu(pContext,tSelectedFiles) end
function gui.AssetExplorer:ListFiles()
	for _,icon in ipairs(self.m_icons) do
		if(icon:IsValid()) then icon:RemoveSafely() end
	end
	self.m_icons = {}

	if(self.m_inFavorites) then
		self:AddIcon("..",true,function()
			self.m_inFavorites = nil
			self:Update()
		end)
		for f,b in pairs(self:GetFavorites()) do
			self:AddIcon(f,false)
		end
		self.m_iconContainer:Update()
		return
	end
	local tFiles,tDirectories
	if(self:GetAssetType() == asset.TYPE_PARTICLE_SYSTEM) then
		local path = util.Path(self:GetPath())
		local back = path:GetBack()
		back = back:sub(0,#back -1)
		local ext = file.get_file_extension(back)
		if(ext ~= nil and string.compare(ext,"wpt")) then
			local ptPath = path:GetString()
			ptPath = ptPath:sub(0,#ptPath -1)
			local headerData = ents.ParticleSystemComponent.read_header_data(ptPath)
			if(headerData ~= nil) then
				tFiles = headerData.particleSystemNames
				tDirectories = {".."}
			end
		end
	end
	if(tFiles == nil) then tFiles,tDirectories = self:FindFiles() end
	if(self:IsAtRoot()) then
		self:AddIcon("favorites",true,function()
			self.m_inFavorites = true
			self:Update()
		end)
	end
	for _,d in ipairs(tDirectories) do
		self:AddIcon(d,true)
	end
	for _,f in ipairs(tFiles) do
		self:AddIcon(f,false)
	end
	self.m_iconContainer:Update()
end
gui.register("WIAssetExplorer",gui.AssetExplorer)

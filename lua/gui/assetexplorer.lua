--[[
    Copyright (C) 2021 Silverlan

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
			local ext = file.get_file_extension(f)
			if(self.m_extensionMap[ext]) then
				-- f = file.remove_file_extension(f) .. "." .. self.m_extension
				tFilesExtUnique[f] = true
			end
		end

		local tFilesExt,tDirsExt = file.find_external_game_asset_files(path .. "*")

		local function add_files(tFiles)
			for _,f in ipairs(tFiles) do
				f = file.remove_file_extension(f) .. "." .. self.m_extensions[1]
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
function gui.AssetExplorer:SetFileExtensions(extensions,extExtensions)
	if(type(extensions) ~= "table") then extensions = {extensions} end
	self.m_extensions = extensions
	self.m_extExtensions = extExtensions

	self.m_extensionMap = {}
	for _,ext in ipairs(extensions) do self.m_extensionMap[ext] = true end
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
function gui.AssetExplorer:CreateAssetIcon(path,assetName,isDirectory,importAsset)
	local oPath = util.Path(path)
	local front = oPath:GetFront()
	local el
	if(isDirectory) then el = gui.create("WIDirectoryAssetIcon",self) -- TODO
	elseif(string.compare(front,"materials",false)) then el = gui.create("WIMaterialAssetIcon")
	elseif(string.compare(front,"models",false)) then el = gui.create("WIModelAssetIcon")
	elseif(string.compare(front,"particles",false)) then el = gui.create("WIParticleAssetIcon") end
	if(el == nil) then return end
	el:SetAsset(path,assetName,importAsset)
	return el
end
function gui.AssetExplorer:AddItem(assetName,isDirectory,fDirClickHandler)
	if(#assetName == 0) then return end
	local path
	local isAbsolutePath = (assetName:sub(1,1) == "/")
	if(isAbsolutePath) then
		assetName = assetName:sub(2)
		path = file.get_file_path(assetName)
		assetName = file.get_file_name(assetName)
	else path = self:GetAbsolutePath() end
	local el = self:CreateAssetIcon(path,assetName,isDirectory)
	if(el == nil) then
		console.print_warning("Unable to populate asset explorer with item '" .. assetName .. "': Unable to create icon for type!")
		return
	end
	gui.IconGridView.AddIcon(self,assetName,el)
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

			local hasExternalFiles = (#tExternalFiles > 0)
			if(hasExternalFiles) then
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

			if(#tSelectedFiles > 0 and hasExternalFiles == false) then
				local exportable = {}
				for _,el in ipairs(tSelectedFiles) do
					if(el:IsValid() and el:IsExportable()) then
						table.insert(exportable,el)
					end
				end
				if(#exportable > 0) then
					pContext:AddItem(locale.get_text("pfm_asset_export"),function()
						local exportSuccessful = false
						for _,el in ipairs(exportable) do
							if(el:IsValid()) then
								local path = el:GetRelativeAsset()
								if(asset.exists(path,self:GetAssetType()) == false) then
									el:Reload(true)
								end

								local success,errMsg = el:Export(path)
								if(success) then exportSuccessful = true
								else console.print_warning("Unable to export asset: ",errMsg) end
							end
						end
						if(exportSuccessful) then
							if(#exportable == 1) then
								local path = exportable[1]:GetRelativeAsset()
								util.open_path_in_explorer("export/" .. file.remove_file_extension(path))
							else
								util.open_path_in_explorer("export/")
							end
						end
					end)
				end
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
					local path = file.remove_file_extension(assetPath)
					util.set_clipboard_string(path .. "." .. self.m_extensions[1])
				end)

				local path = tSelectedFiles[1]:GetRelativeAsset()
				if(asset.exists(path,self:GetAssetType())) then
					pContext:AddItem(locale.get_text("pfm_open_in_explorer"),function()
						util.open_path_in_explorer(file.get_file_path(assetPath),file.get_file_name(assetPath) .. "." .. self.m_extensions[1])
					end)

					if(self:GetAssetType() == asset.TYPE_MODEL) then
						pContext:AddItem(locale.get_text("pfm_open_in_model_editor"),function()
							local dialog,frame,el = gui.open_model_dialog(function(dialogResult,mdlName) end)

							if(util.is_valid(el) == false) then return end
							local path = util.Path.CreatePath(assetPath)
							path:PopFront()
							el:SetModel(path:GetString())
						end)
					end
				end
			end
			self:PopulateContextMenu(pContext,tSelectedFiles,tExternalFiles)
		end)
	end
	return el
end
function gui.AssetExplorer:PopulateContextMenu(pContext,tSelectedFiles,tExternalFiles) end
function gui.AssetExplorer:AddAsset(assetName,isDirectory,fDirClickHandler)
	return self:AddItem(assetName,isDirectory,fDirClickHandler)
end
function gui.AssetExplorer:ListFiles()
	for _,icon in ipairs(self.m_icons) do
		if(icon:IsValid()) then icon:RemoveSafely() end
	end
	self.m_icons = {}

	if(self.m_inFavorites) then
		self:AddAsset("..",true,function()
			self.m_inFavorites = nil
			self:Update()
		end)
		for f,b in pairs(self:GetFavorites()) do
			self:AddAsset(f,false)
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
		self:AddAsset(locale.get_text("favorites"),true,function()
			self.m_inFavorites = true
			self:Update()
		end)
	end
	for _,d in ipairs(tDirectories) do
		self:AddAsset(d,true)
	end
	table.sort(tFiles,function(a,b) return a:lower() < b:lower() end)
	for _,f in ipairs(tFiles) do
		self:AddAsset(f,false)
	end
	self.m_iconContainer:Update()
end
gui.register("WIAssetExplorer",gui.AssetExplorer)

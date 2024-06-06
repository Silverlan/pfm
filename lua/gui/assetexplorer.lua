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

util.register_class("gui.AssetExplorer", gui.IconGridView, gui.BaseFileExplorer)
function gui.AssetExplorer:__init()
	gui.IconGridView.__init(self)
	gui.BaseFileExplorer.__init(self)
end
function gui.AssetExplorer:OnInitialize()
	gui.IconGridView.OnInitialize(self)

	self.m_pathToAssetIcon = {}
	self.m_special = {
		["fav"] = {},
		["new"] = {},
	} -- TODO: Load/Save from/to file
	self:AddCallback("OnIconSelected", function(self, icon)
		self:CallCallbacks("OnFileClicked", icon:GetText(), icon:IsDirectory())
	end)
	self:AddCallback("PopulateContextMenu", function(self, pContext)
		pContext
			:AddItem(locale.get_text("pfm_asset_import_all"), function()
				for _, icon in ipairs(self:GetIcons()) do
					if icon:IsValid() and icon:IsDirectory() == false then
						self:ImportAsset(icon)
					end
				end
			end)
			:SetName("import_all_assets")
		self:PopulateContextMenu(pContext, {}, {})
	end)

	self:SetIconFactory(function(parent)
		return gui.create("WIAssetIcon", parent)
	end)
	self:SetFileFinder(function(path)
		return self:CollectFiles(path)
	end)
	self:SetShowExternalAssets(true)
end
function gui.AssetExplorer:CollectFiles(path)
	local tFiles, tDirs = file.find(path)
	local rootPath = path:sub(1, #path - 1)

	local relRootPath = util.Path.CreatePath(rootPath)
	relRootPath:MakeRelative(self:GetRootPath())
	relRootPath = relRootPath:GetString()

	-- In some cases there may be multiple files with the same name for the same asset, but each file with a different type.
	-- In this case we'll only show the version that has a native type and hide the others.
	-- If there is no native version, we'll show all available versions.
	local tFilesExtUnique = {}
	local tNativeFilesNoExt = {}
	for _, f in ipairs(tFiles) do
		local ext = file.get_file_extension(f)
		if self.m_extensionMap[ext] then
			-- f = file.remove_file_extension(f) .. "." .. self.m_extension
			--local filePath = util.Path.CreateFilePath(rootPath .. file.remove_file_extension(f))
			--filePath:PopFront()
			if
				self.m_nativeExtensionMap[ext]
				or asset.exists(relRootPath .. file.remove_file_extension(f), self:GetAssetType()) == false
			then
				tFilesExtUnique[f] = true
				if self.m_nativeExtensionMap[ext] then
					tNativeFilesNoExt[file.remove_file_extension(f, self.m_nativeExtensions)] = true
				end
			end
		end
	end

	local tDirsExtUnique = {}
	if self.m_showExternalAssets then
		local tFilesExt, tDirsExt = file.find_external_game_asset_files(path .. "*")

		local function add_files(tFiles)
			for _, f in ipairs(tFiles) do
				local fNoExt = file.remove_file_extension(f)
				if tNativeFilesNoExt[fNoExt] == nil then
					tFilesExtUnique[f] = true
				end
			end
		end
		for _, ext in ipairs(self.m_extExtensions) do
			add_files(file.find_external_game_asset_files(path .. "." .. ext))
		end
		for _, f in ipairs(tDirsExt) do
			tDirsExtUnique[f] = true
		end
	end

	for _, f in ipairs(tDirs) do
		tDirsExtUnique[f] = true
	end

	tFiles = {}
	tDirs = {}
	for f, _ in pairs(tFilesExtUnique) do
		table.insert(tFiles, f)
	end
	table.sort(tFiles)

	for d, _ in pairs(tDirsExtUnique) do
		if self.m_showExternalAssets or file.is_empty(rootPath .. d) == false then
			table.insert(tDirs, d)
		end
	end
	table.sort(tDirs)
	return tFiles, tDirs
end
function gui.AssetExplorer:Setup()
	local gsd = pfm.get_project_manager():GetGlobalStateData()
	local udmCatalog = gsd:Get("catalogs"):Get(self:GetIdentifier())
	for _, fav in ipairs(udmCatalog:GetArrayValues("favorites", udm.TYPE_STRING)) do
		self:AddToFavorites(fav, false)
	end
end
function gui.AssetExplorer:GetIdentifier()
	return "asset_explorer"
end
function gui.AssetExplorer:SetShowExternalAssets(show)
	self.m_showExternalAssets = show
	self:ScheduleUpdate()
end
function gui.AssetExplorer:SetAssetType(type)
	self.m_assetType = type
end
function gui.AssetExplorer:GetAssetType()
	return self.m_assetType
end
function gui.AssetExplorer:SetFileExtensions(extensions, extExtensions, nativeExtensions)
	if type(extensions) ~= "table" then
		extensions = { extensions }
	end
	self.m_extensions = extensions
	self.m_extExtensions = extExtensions
	self.m_nativeExtensions = nativeExtensions

	self.m_extensionMap = {}
	self.m_nativeExtensionMap = {}
	for _, ext in ipairs(extensions) do
		self.m_extensionMap[ext] = true
	end
	for _, ext in ipairs(nativeExtensions) do
		self.m_nativeExtensionMap[ext] = true
	end
end
local function find_in_gsd_favorites(udmCatalog, assetName)
	local favorites = udmCatalog:GetArrayValues("favorites", udm.TYPE_STRING)
	for i, fav in ipairs(favorites) do
		if fav == assetName then
			return i - 1
		end
	end
end
function gui.AssetExplorer:AddToSpecial(id, mdl, addToGlobalState)
	if addToGlobalState == nil then
		addToGlobalState = true
	end
	local v = self.m_special[id]
	if v == nil then
		return
	end
	v[mdl] = true

	if addToGlobalState and id == "fav" then
		local gsd = pfm.get_project_manager():GetGlobalStateData()

		local identifier = self:GetIdentifier()
		local udmCatalog = gsd:Get("catalogs"):Get(identifier)

		local i = find_in_gsd_favorites(udmCatalog, mdl)
		if i == nil then
			if udmCatalog:Get("favorites"):IsValid() == false then
				udmCatalog:AddArray("favorites", 0, udm.TYPE_STRING)
			end
			local udmFavorites = udmCatalog:Get("favorites")
			udmFavorites:Resize(udmFavorites:GetSize() + 1)
			udmFavorites:SetValue(udmFavorites:GetSize() - 1, udm.TYPE_STRING, mdl)
			pfm.get_project_manager():SaveGlobalStateData()
		end

		local el = self:GetAssetIcon(mdl)
		if util.is_valid(el) then
			el:AddIcon("favorite", "star", "pfm_asset_icon_remove_from_favorites", function()
				self:RemoveFromFavorites(mdl)
			end)
		end
	end
end
function gui.AssetExplorer:GetAssetIcon(id)
	return self.m_pathToAssetIcon[id]
end
function gui.AssetExplorer:OnPathChanged(path)
	self.m_inSpecial = nil
end
function gui.AssetExplorer:IsInSpecial(id, mdl)
	local v = self.m_special[id]
	if v == nil then
		return false
	end
	return v[mdl] == true
end
function gui.AssetExplorer:RemoveFromSpecial(id, mdl)
	local v = self.m_special[id]
	if v == nil then
		return
	end
	v[mdl] = nil

	if id == "fav" then
		local gsd = pfm.get_project_manager():GetGlobalStateData()
		local identifier = self:GetIdentifier()
		local udmCatalog = gsd:Get("catalogs"):Get(identifier)
		local i = find_in_gsd_favorites(udmCatalog, mdl)
		if i ~= nil then
			local udmFavorites = udmCatalog:Get("favorites")
			udmFavorites:RemoveValue(i)
			pfm.get_project_manager():SaveGlobalStateData()
		end

		local el = self:GetAssetIcon(mdl)
		if util.is_valid(el) then
			el:RemoveIcon("favorite")
		end
	end
end
function gui.AssetExplorer:SetInactive(inactive)
	self.m_inactive = inactive or false
end
function gui.AssetExplorer:GetSpecial(id)
	return self.m_special[id]
end
function gui.AssetExplorer:AddToFavorites(mdl, addToGlobalState)
	self:AddToSpecial("fav", mdl, addToGlobalState)

	if self.m_inSpecial == "fav" then
		self:ReloadPath()
		self:ScheduleUpdate()
	end
end
function gui.AssetExplorer:IsInFavorites(mdl)
	return self:IsInSpecial("fav", mdl)
end
function gui.AssetExplorer:RemoveFromFavorites(mdl)
	self:RemoveFromSpecial("fav", mdl)

	if self.m_inSpecial == "fav" then
		self:ReloadPath()
		self:ScheduleUpdate()
	end
end
function gui.AssetExplorer:GetFavorites()
	return self:GetSpecial("fav")
end
function gui.AssetExplorer:OnUpdate()
	self:ListFiles()
end
function gui.AssetExplorer:CreateAssetIcon(path, assetName, isDirectory, importAsset)
	local oPath = util.Path(path)
	local front = oPath:GetFront()
	local el
	if isDirectory then
		el = gui.create("WIDirectoryAssetIcon", self) -- TODO
	elseif string.compare(front, "materials", false) then
		el = gui.create("WIMaterialAssetIcon")
	elseif string.compare(front, "models", false) then
		el = gui.create("WIModelAssetIcon")
	elseif string.compare(front, "particles", false) then
		el = gui.create("WIParticleAssetIcon")
	end
	if el == nil then
		return
	end
	el:SetAsset(path, assetName, importAsset)
	self:OnAssetIconCreated(path, assetName, el)

	local relPath = el:GetRelativeAsset()
	self.m_pathToAssetIcon[relPath] = el
	if self:IsInFavorites(relPath) then
		el:AddIcon("favorite", "star", "pfm_asset_icon_remove_from_favorites", function()
			self:RemoveFromFavorites(relPath)
		end)
	end

	return el
end
function gui.AssetExplorer:OnAssetIconCreated(path, assetName, el) end
function gui.AssetExplorer:ImportAsset(el)
	local assetPath = el:GetAsset()
	assetPath = file.get_file_path(assetPath)

	local assetName = el:GetAssetName()
	assetName = file.remove_file_extension(assetName, self.m_extExtensions)
	assetName = assetName .. "." .. self.m_extensions[1]

	local nativePath = file.remove_file_extension(el:GetRelativeAsset(), self.m_extExtensions)
	if asset.exists(nativePath, self:GetAssetType()) == false then
		-- Re-apply asset with import-flag
		el:SetAsset(assetPath, assetName, true, el:GetAttributeData(), true)
	end
end
function gui.AssetExplorer:AddItem(assetName, isDirectory, fDirClickHandler)
	if #assetName == 0 then
		return
	end
	local path
	local isAbsolutePath = (assetName:sub(1, 1) == "/")
	if isAbsolutePath then
		assetName = assetName:sub(2)
		path = file.get_file_path(assetName)
		assetName = file.get_file_name(assetName)
	else
		path = self:GetAbsolutePath()
	end
	local el = self:CreateAssetIcon(path, assetName, isDirectory)
	if el == nil then
		console.print_warning(
			"Unable to populate asset explorer with item '" .. assetName .. "': Unable to create icon for type!"
		)
		return
	end
	gui.IconGridView.AddIcon(self, assetName, el)
	if el:IsDirectory() then
		el:AddCallback("OnDoubleClick", function(el)
			if util.is_valid(self) == false then
				return
			end
			if fDirClickHandler ~= nil then
				fDirClickHandler()
			else
				local relPath = util.Path(path)
				relPath:MakeRelative(self:GetRootPath())
				self:SetPath(relPath:GetString() .. assetName)
				self:Update()
			end
			--self:CallCallbacks("OnFileSelected",fPath)
		end)
	else
		el:AddCallback("PopulateContextMenu", function(el, pContext)
			local tSelected = self:GetSelectedIcons()
			local tSelectedDirs = {}
			local tSelectedFiles = {}
			local tExternalFiles = {}

			local numInFavorites = 0
			if self:IsIconSelected(el) == false then
				tSelected = { el }
			end
			for _, el in ipairs(tSelected) do
				local path = el:GetRelativeAsset()
				if self:IsInFavorites(path) then
					numInFavorites = numInFavorites + 1
				end
				if el:IsDirectory() then
					table.insert(tSelectedDirs, el)
				else
					table.insert(tSelectedFiles, el)
					local exists = asset.exists(path, self:GetAssetType())
					if exists == false and self:GetAssetType() == asset.TYPE_PARTICLE_SYSTEM then
						local ptPath = util.Path(path)
						local ptName = ptPath:GetBack()
						ptPath:PopBack()
						local ptFileName = ptPath:GetBack()
						ptFileName = ptFileName:sub(1, #ptFileName - 1)
						local ext = file.get_file_extension(ptFileName)
						if ext ~= nil and asset.is_supported_extension(ext, asset.TYPE_PARTICLE_SYSTEM) then
							ptFileName = file.remove_file_extension(ptFileName)
							exists = asset.exists(ptFileName, self:GetAssetType())
						end
					end
					if exists == false then
						table.insert(tExternalFiles, el)
					end
				end
			end

			local hasExternalFiles = (#tExternalFiles > 0)
			if hasExternalFiles then
				pContext
					:AddItem(locale.get_text("pfm_asset_import"), function()
						for _, el in ipairs(tExternalFiles) do
							if el:IsValid() then
								self:ImportAsset(el)
							end
						end
					end)
					:SetName("import_asset")
			else
				pContext
					:AddItem(locale.get_text("pfm_asset_icon_reload"), function()
						for _, el in ipairs(tSelectedFiles) do
							if el:IsValid() then
								el:Reload()
							end
						end
					end)
					:SetName("reload_icon")
				if pfm.get_project_manager():IsDeveloperModeEnabled() then
					pContext:AddItem("Reset Icon", function()
						for _, el in ipairs(tSelectedFiles) do
							if el:IsValid() then
								local iconLocation = el:GetIconLocation()
								local mat = game.load_material(iconLocation)
								if util.is_valid(mat) then
									mat:GetData():RemoveValue("pfm_model_view")
									mat:Save()
								end
								el:Reload()
							end
						end
					end)
				end
				if #tSelected == 1 then
					pContext
						:AddItem(locale.get_text("pfm_asset_icon_copy_path_to_clipboard"), function()
							util.set_clipboard_string(tSelectedFiles[1]:GetIconLocation())
						end)
						:SetName("copy_icon_path_to_clipboard")
				end
			end

			if #tSelectedFiles > 0 and hasExternalFiles == false then
				local exportable = {}
				for _, el in ipairs(tSelectedFiles) do
					if el:IsValid() and el:IsExportable() then
						table.insert(exportable, el)
					end
				end
				if #exportable > 0 then
					pContext
						:AddItem(locale.get_text("pfm_asset_export"), function()
							local exportSuccessful = false
							for _, el in ipairs(exportable) do
								if el:IsValid() then
									local path = el:GetRelativeAsset()
									if asset.exists(path, self:GetAssetType()) == false then
										el:Reload(true)
									end

									local success, errMsg = el:Export(path)
									if success then
										exportSuccessful = true
									else
										console.print_warning("Unable to export asset: ", errMsg)
									end
								end
							end
							if exportSuccessful then
								if #exportable == 1 then
									local path = exportable[1]:GetRelativeAsset()
									util.open_path_in_explorer("export/" .. file.remove_file_extension(path))
								else
									util.open_path_in_explorer("export/")
								end
							end
						end)
						:SetName("export_asset")
				end
			end

			if self:IsSpecialDirectoryEnabled("favorites") then
				if numInFavorites == #tSelected then
					pContext
						:AddItem(locale.get_text("pfm_asset_icon_remove_from_favorites"), function()
							for _, el in ipairs(tSelected) do
								if el:IsValid() then
									local path = el:GetRelativeAsset()
									self:RemoveFromFavorites(path)
								end
							end
						end)
						:SetName("remove_from_favorites")
				else
					pContext
						:AddItem(locale.get_text("pfm_asset_icon_add_to_favorites"), function()
							for _, el in ipairs(tSelected) do
								if el:IsValid() then
									local path = el:GetRelativeAsset()
									self:AddToFavorites(path)
								end
							end
						end)
						:SetName("add_to_favorites")
				end
			end
			if #tSelectedFiles == 1 then
				local assetPath = tSelectedFiles[1]:GetAsset()
				pContext
					:AddItem(locale.get_text("pfm_copy_path"), function()
						local path = file.remove_file_extension(assetPath)
						util.set_clipboard_string(path .. "." .. self.m_extensions[1])
					end)
					:SetName("copy_path")

				local path = tSelectedFiles[1]:GetRelativeAsset()
				if asset.exists(path, self:GetAssetType()) then
					pContext
						:AddItem(locale.get_text("pfm_open_in_explorer"), function()
							local filePath = util.Path.CreateFilePath(assetPath)
							filePath:PopFront()
							filePath = asset.find_file(filePath:GetString(), asset.TYPE_MODEL)
							if filePath == nil then
								return
							end
							filePath = asset.get_asset_root_directory(asset.TYPE_MODEL) .. "/" .. filePath
							util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
						end)
						:SetName("open_in_explorer")

					--[[if(self:GetAssetType() == asset.TYPE_MODEL) then
						pContext:AddItem(locale.get_text("pfm_open_in_model_editor"),function()
							local dialog,frame,el = gui.open_model_dialog(function(dialogResult,mdlName) end)

							if(util.is_valid(el) == false) then return end
							local path = util.Path.CreatePath(assetPath)
							path:PopFront()
							el:SetModel(path:GetString())
						end)
					end]]
				end
			end
			self:PopulateContextMenu(pContext, tSelectedFiles, tExternalFiles)
		end)
	end
	return el
end
function gui.AssetExplorer:PopulateContextMenu(pContext, tSelectedFiles, tExternalFiles) end
function gui.AssetExplorer:AddAsset(assetName, isDirectory, fDirClickHandler)
	return self:AddItem(assetName, isDirectory, fDirClickHandler)
end
function gui.AssetExplorer:SetSpecialDirectoryEnabled(specialDir, enabled)
	self.m_specialDirEnabled = self.m_specialDirEnabled or {}
	self.m_specialDirEnabled[specialDir] = enabled
end
function gui.AssetExplorer:IsSpecialDirectoryEnabled(specialDir)
	if self.m_specialDirEnabled == nil then
		return true
	end
	if self.m_specialDirEnabled[specialDir] == nil then
		return true
	end
	return self.m_specialDirEnabled[specialDir]
end
function gui.AssetExplorer:OnPopulated() end
function gui.AssetExplorer:ListFiles()
	if self.m_inactive then
		return
	end
	debug.start_profiling_task("pfm_asset_explorer_list")
	for _, icon in ipairs(self.m_icons) do
		if icon:IsValid() then
			icon:RemoveSafely()
		end
	end
	self.m_icons = {}

	if self.m_inSpecial ~= nil then
		self:AddAsset("..", true, function()
			self.m_inSpecial = nil
			self:Update()
		end)
		for f, b in pairs(self:GetSpecial(self.m_inSpecial)) do
			self:AddAsset(f, false)
		end
		self.m_iconContainer:Update()
		debug.stop_profiling_task()
		return
	end
	local tFiles, tDirectories, preSorted
	if self:GetAssetType() == asset.TYPE_PARTICLE_SYSTEM then
		local path = util.Path(self:GetPath())
		local back = path:GetBack()
		back = back:sub(0, #back - 1)
		local ext = file.get_file_extension(back)
		if ext ~= nil and asset.is_supported_extension(ext, asset.TYPE_PARTICLE_SYSTEM) then
			local ptPath = path:GetString()
			ptPath = ptPath:sub(0, #ptPath - 1)
			local headerData = ents.ParticleSystemComponent.read_header_data(ptPath)
			if headerData ~= nil then
				tFiles = headerData.particleSystemNames
				tDirectories = { ".." }
			end
		end
	end
	if tFiles == nil then
		tFiles, tDirectories, preSorted = self:FindFiles()
	end
	if self:IsAtRoot() then
		if self:IsSpecialDirectoryEnabled("favorites") then
			self:AddAsset(locale.get_text("favorites"), true, function()
				self:GoToSpecialDirectory("fav")
			end)
		end
		if self:IsSpecialDirectoryEnabled("new") then
			self:AddAsset(locale.get_text("new"), true, function()
				self:GoToSpecialDirectory("new")
			end)
		end
	end
	for _, d in ipairs(tDirectories) do
		self:AddAsset(d, true)
	end
	if preSorted ~= true then
		table.sort(tFiles, function(a, b)
			return a:lower() < b:lower()
		end)
	end
	for _, f in ipairs(tFiles) do
		self:AddAsset(f, false)
	end
	self:OnPopulated()
	self.m_iconContainer:Update()
	debug.stop_profiling_task()
end
function gui.AssetExplorer:GoToSpecialDirectory(id)
	self.m_inSpecial = id
	self:Update()
end
gui.register("WIAssetExplorer", gui.AssetExplorer)

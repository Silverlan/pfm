--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")
include("/util/util_asset_import.lua")

util.register_class("gui.ModelExplorer", gui.AssetExplorer)
function gui.ModelExplorer:__init()
	gui.AssetExplorer.__init(self)
end
function gui.ModelExplorer:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetAssetType(asset.TYPE_MODEL)
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_MODEL)
	table.insert(extensions, 1, asset.FORMAT_MODEL_ASCII)
	table.insert(extensions, 1, asset.FORMAT_MODEL_BINARY)
	self:SetFileExtensions(extensions, asset.get_supported_import_file_extensions(asset.TYPE_MODEL), {
		asset.FORMAT_MODEL_ASCII,
		asset.FORMAT_MODEL_BINARY,
	})
	self:SetFileDropInputEnabled(true)
end
function gui.ModelExplorer:InitDragOverlay()
	util.remove(self.m_dragOverlay)
	local pos, size = self:GetVisibleBounds()
	self.m_dragOverlay = gui.create("WIDragAndDropOverlay", self, pos.x, pos.y, size.x, size.y, 0, 0, 1, 1)
	self.m_dragOverlay:SetZPos(100000)
	return self.m_dragOverlay
end
function gui.ModelExplorer:OnFilesDropped(tFiles)
	local basePath = util.Path.CreatePath(self:GetPath())
	local function import_dropped_files(importAsSingleModel)
		if self:IsValid() == false then
			return
		end
		for _, fname in ipairs(tFiles) do
			local dirName = file.remove_file_extension(fname)
			dirName = string.replace(dirName, ".", "_")
			local outputPath = basePath

			util.import_assets(fname, {
				modelImportCallback = function(assetType, assetPath)
					if assetType == asset.TYPE_MODEL then
						self:AddToSpecial("new", assetPath)
					end
				end,
				onComplete = function()
					if self:IsValid() then
						self:ScheduleUpdate()
					end
				end,
				basePath = outputPath:GetString(),
				dropped = true,
				importAsCollection = not importAsSingleModel,
			})
		end
		self:SetPath(basePath:GetString())
	end
	local pContext = gui.open_context_menu()
	if util.is_valid(pContext) then
		pContext:SetPos(input.get_cursor_pos())
		pContext
			:AddItem(locale.get_text("pfm_import_as_single_model"), function()
				import_dropped_files(true)
			end)
			:SetName("import_as_single_model")
		pContext
			:AddItem(locale.get_text("pfm_import_as_collection"), function()
				import_dropped_files(false)
			end)
			:SetName("import_as_collection")
		pContext:Update()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_HANDLED
end
function gui.ModelExplorer:GetIdentifier()
	return "model_explorer"
end
function gui.ModelExplorer:PopulateContextMenu(pContext, tSelectedFiles, tExternalFiles)
	self:CallCallbacks("PopulateIconContextMenu", pContext, tSelectedFiles, tExternalFiles)
end
gui.register("WIModelExplorer", gui.ModelExplorer)

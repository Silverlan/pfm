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
	self:SetFileExtensions(extensions, asset.get_supported_import_file_extensions(asset.TYPE_MODEL))

	self:AddCallback("OnFilesDropped", function(el, tFiles)
		local basePath = util.Path.CreatePath(self:GetPath())
		for _, fname in ipairs(tFiles) do
			local f = game.open_dropped_file(fname, true)
			if f ~= nil then
				local function import_model(importAsSingleModel)
					if self:IsValid() == false then
						return
					end
					local dirName = file.remove_file_extension(fname)
					dirName = string.replace(dirName, ".", "_")
					local outputPath = basePath + util.Path.CreatePath(dirName)
					self:SetPath(outputPath:GetString())

					util.import_assets(f, {
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
				local pContext = gui.open_context_menu()
				if util.is_valid(pContext) then
					pContext:SetPos(input.get_cursor_pos())
					pContext:AddItem(locale.get_text("pfm_import_as_single_model"), function()
						import_model(true)
					end)
					pContext:AddItem(locale.get_text("pfm_import_as_collection"), function()
						import_model(false)
					end)
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
			end
		end
		return util.EVENT_REPLY_HANDLED
	end)
end
function gui.ModelExplorer:GetIdentifier()
	return "model_explorer"
end
function gui.ModelExplorer:PopulateContextMenu(pContext, tSelectedFiles, tExternalFiles)
	self:CallCallbacks("PopulateIconContextMenu", pContext, tSelectedFiles, tExternalFiles)
end
gui.register("WIModelExplorer", gui.ModelExplorer)

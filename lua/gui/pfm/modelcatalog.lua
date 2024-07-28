--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/modelexplorer.lua")
include("/gui/pfm/base_catalog.lua")

local Element = util.register_class("gui.PFMModelCatalog", gui.PFMBaseCatalog)
function Element:InitializeFileIndexTable()
	self:SetFitPaths({ "addons/imported/models/", "addons/converted/models/" })

	return pfm.FileIndexTable(
		"models",
		"models/",
		{ asset.FORMAT_MODEL_BINARY, asset.FORMAT_MODEL_ASCII },
		asset.get_supported_import_file_extensions(asset.TYPE_MODEL)
	)
end
function Element:OnInitialize()
	gui.PFMBaseCatalog.OnInitialize(self)
end
function Element:InitializeExplorer(explorer)
	explorer:SetRootPath("models")
	local extensions = asset.get_supported_import_file_extensions(asset.TYPE_MODEL)
	table.insert(extensions, asset.FORMAT_MODEL_BINARY)
	table.insert(extensions, asset.FORMAT_MODEL_ASCII)
	explorer:SetExtensions(extensions)
	explorer:AddCallback("OnFilesDropped", function(explorer, tFiles)
		local reloadDirectory = false
		for _, fileName in ipairs(tFiles) do
			local f = game.open_dropped_file(fileName, true)
			if f ~= nil then
				local outputPath = explorer:GetPath()
				if asset.exists(outputPath .. file.get_file_name(fileName), asset.TYPE_MODEL) == false then
					local mdl, errMsg = asset.import_model(f, outputPath)
					if mdl ~= false then
						reloadDirectory = true
					else
						console.print_warning("Unable to import model '" .. fileName .. "': " .. errMsg)
					end
				end
			end
		end
		if reloadDirectory == true then
			explorer:Refresh()
			explorer:Update()
		end
		return util.EVENT_REPLY_HANDLED
	end)
end
function Element:CreateIconExplorer(baseElement)
	local explorer = gui.create("WIModelExplorer", baseElement, 0, 0, self:GetWidth(), self:GetHeight())
	explorer:SetName("model_explorer")
	return explorer
end
gui.register("WIPFMModelCatalog", Element)

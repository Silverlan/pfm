--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIBaseFilmmaker

function Element:RestoreProject()
	local udmData, err = udm.load("temp/pfm/restore/restore.udm")
	local originalProjectFileName
	if udmData == false then
		pfm.log("Failed to restore project: Unable to open restore file!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		return false
	end
	udmData = udmData:GetAssetData():GetData()
	local restoreData = udmData:ClaimOwnership()
	originalProjectFileName = restoreData:GetValue("originalProjectFileName", udm.TYPE_STRING)
	local restoreProjectFileName = restoreData:GetValue("restoreProjectFileName", udm.TYPE_STRING)
	if restoreProjectFileName == nil then
		pfm.log("Failed to restore project: Invalid restore data!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		return false
	end
	local fileName = restoreProjectFileName
	if self:LoadProject(fileName, true) == false then
		pfm.log(
			"Failed to restore project: Unable to load restore project!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_ERROR
		)
		self:CloseProject()
		self:CreateEmptyProject()
		return false
	end
	local newProjectMapName = restoreData:GetValue("newProjectMapName")
	if newProjectMapName ~= nil then
		local session = self:GetSession()
		if session ~= nil then
			local settings = session:GetSettings()
			settings:SetMapName(asset.get_normalized_path(newProjectMapName, asset.TYPE_MAP))
		end
	end
	self:SetProjectFileName(originalProjectFileName)
	file.delete_directory("temp/pfm/restore")
end

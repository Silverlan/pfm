--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIBaseFilmmaker

function Element:RestoreStateFromData(restoreData) end
function Element:RestoreProject()
	local udmData, err = udm.load("temp/pfm/restore/restore.udm")
	if udmData == false then
		pfm.log("Failed to restore project: Unable to open restore file!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
		return false
	end
	udmData = udmData:GetAssetData():GetData()
	local restoreData = udmData:ClaimOwnership()
	self:RestoreStateFromData(restoreData)
	file.delete_directory("temp/pfm/restore")
end

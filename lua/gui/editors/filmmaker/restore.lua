-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = gui.WIBaseFilmmaker

function Element:RestoreStateFromData(restoreData) end
function Element:RestoreProject()
	local udmData, err = udm.load("temp/pfm/restore/restore.udm")
	if udmData == false then
		self:LogErr("Failed to restore project: Unable to open restore file!")
		return false
	end
	udmData = udmData:GetAssetData():GetData()
	local restoreData = udmData:ClaimOwnership()
	self:RestoreStateFromData(restoreData)
	file.delete_directory("temp/pfm/restore")
end

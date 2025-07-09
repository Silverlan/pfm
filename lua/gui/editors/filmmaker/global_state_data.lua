-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = gui.WIBaseFilmmaker

local fileName = "data/pfm/global_state_data.udm"
function Element:LoadGlobalStateData()
	local udmData, err = udm.load(fileName)
	if udmData == false then
		self.m_globalStateData = udm.create_element()
		return false
	end
	self.m_globalStateData = udmData:GetAssetData():GetData():Get("global_state_data"):ClaimOwnership()
	return true
end

function Element:SaveGlobalStateData()
	local udmData = udm.create()
	local assetData = udmData:GetAssetData():GetData()
	local udmGsd = assetData:Add("global_state_data")
	udmGsd:Merge(self.m_globalStateData:Get(), udm.MERGE_FLAG_BIT_DEEP_COPY)
	file.create_path(file.get_file_path(fileName))
	local res, err = udmData:SaveAscii(fileName)
	if res == false then
		self:LogWarn("Failed to save global state data as '" .. fileName .. "': " .. err)
	else
		self:LogInfo("Successfully saved global state data as '" .. fileName .. "'!")
	end
end

function Element:GetGlobalStateData()
	return self.m_globalStateData
end

function Element:SetFileDialogPath(id, path)
	local gsd = self:GetGlobalStateData()
	local udmPreferences = gsd:Get("preferences")
	udmPreferences:SetValue(id, udm.TYPE_STRING, path)
	self:SaveGlobalStateData()
end

function Element:GetFileDialogPath(id)
	local gsd = self:GetGlobalStateData()
	local udmPreferences = gsd:Get("preferences")
	if udmPreferences:IsValid() == false then
		return
	end
	return udmPreferences:GetValue(id, udm.TYPE_STRING)
end

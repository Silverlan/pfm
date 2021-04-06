--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/popup.lua")

util.register_class("pfm.ComponentManager")
function pfm.ComponentManager:__init()
	self:LoadComponents()
end

function pfm.ComponentManager:LoadComponentsFile(fileName,binary)
	local flags = file.OPEN_MODE_READ
	if(binary) then flags = bit.bor(flags,file.OPEN_MODE_BINARY) end
	local f = file.open(fileName,flags)
	if(f == nil) then
		pfm.log("Unable to load component config: File '" .. fileName .. "' not found!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local udmData,err = udm.load(f)
	f:Close()
	if(udmData == false) then
		pfm.log("Failed to load component config: " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local assetData = udmData:GetAssetData()
	assetData = assetData:GetData()

	local udmComponents = assetData:Get("components")
	if(not udmComponents:IsValid()) then return true end
	if(self.m_udmComponents == nil) then self.m_udmComponents = udmComponents:ClaimOwnership()
	else self.m_udmComponents:Get():Merge(udmComponents) end
	return true
end

function pfm.ComponentManager:LoadComponents()
	local configPath = "cfg/pfm/components/"

	local tFiles,_ = file.find(configPath .. "*.udm")
	for _,fileName in ipairs(tFiles) do
		self:LoadComponentsFile(configPath .. fileName,false)
	end
	
	tFiles,_ = file.find(configPath .. "*.udm_b")
	for _,fileName in ipairs(tFiles) do
		self:LoadComponentsFile(configPath .. fileName,true)
	end
end

function pfm.ComponentManager:GetComponents() return self.m_udmComponents and self.m_udmComponents:Get() or udm.LinkedPropertyWrapper() end

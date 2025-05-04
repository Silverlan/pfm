--[[
    Copyright (C) 2025 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local IconCache = util.register_class("gui.PFMIconCache")

function IconCache:__init()
	self.m_cache = {}
end

function IconCache:GenerateMaterial(iconPath, iconData, styleSheet)
	iconPath = util.FilePath(iconPath):GetString()
	local udmData, err = udm.create()
	local assetData = udmData:GetAssetData():GetData()
	local shaderData = assetData:Add("wguitextured")
	local textures = shaderData:Add("textures")
	local albedoMap = textures:Add("albedo_map")
	albedoMap:SetValue("texture", udm.TYPE_STRING, iconPath)
	albedoMap:SetValue("cache", udm.TYPE_BOOLEAN, false)
	if iconData ~= nil then
		if iconData.width ~= nil then
			albedoMap:SetValue("width", udm.TYPE_UINT32, iconData.width)
		end
		if iconData.height ~= nil then
			albedoMap:SetValue("height", udm.TYPE_UINT32, iconData.height)
		end
		local nineSliceData = iconData.nineSlice
		if nineSliceData ~= nil then
			local properties = shaderData:Add("properties")
			local nineSlice = properties:Add("9slice")
			if nineSliceData.leftInset ~= nil then
				nineSlice:SetValue("leftInset", udm.TYPE_UINT32, nineSliceData.leftInset)
			end
			if nineSliceData.rightInset ~= nil then
				nineSlice:SetValue("rightInset", udm.TYPE_UINT32, nineSliceData.rightInset)
			end
			if nineSliceData.topInset ~= nil then
				nineSlice:SetValue("topInset", udm.TYPE_UINT32, nineSliceData.topInset)
			end
			if nineSliceData.bottomInset ~= nil then
				nineSlice:SetValue("bottomInset", udm.TYPE_UINT32, nineSliceData.bottomInset)
			end
		end
	end

	if styleSheet ~= nil then
		local styleSheetData = albedoMap:Add("styleSheet")
		for k, vars in pairs(styleSheet) do
			local c = styleSheetData:Add(k)
			for name, value in pairs(vars) do
				c:SetValue(name, udm.TYPE_STRING, value)
			end
		end
	end

	local mat = asset.create_material(udmData:GetAssetData())
	self.m_cache[iconPath] = mat
	return mat
end

function IconCache:Load(iconPath, iconData, styleSheet)
	iconPath = util.FilePath(iconPath):GetString()
	local mat
	if self.m_cache[iconPath] == nil then
		mat = self:GenerateMaterial(iconPath, iconData, styleSheet)
	else
		mat = self.m_cache[iconPath]
	end
	return mat
end

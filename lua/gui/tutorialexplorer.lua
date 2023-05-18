--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("assetexplorer.lua")

local Element = util.register_class("gui.TutorialExplorer", gui.AssetExplorer)
function Element:OnInitialize()
	gui.AssetExplorer.OnInitialize(self)

	self:SetFileExtensions({ "udm" }, {})

	self:AddCallback("OnIconAdded", function(self, el)
		if el.InitializeVideo == nil then
			return
		end
		el:AddCallback("OnCursorEntered", function()
			self:ShowPreview(el)
		end)
		el:AddCallback("OnCursorExited", function()
			self:HidePreview()
		end)
	end)
	self:SetSpecialDirectoryEnabled("favorites", false)
	self:SetSpecialDirectoryEnabled("new", false)
end
function Element:OnPopulated()
	local t = {}
	for i, item in ipairs(self.m_iconContainer:GetChildren()) do
		table.insert(t, { item, item:GetText(), i })
	end
	table.sort(t, function(a, b)
		if a[1]:IsDirectory() and not b[1]:IsDirectory() then
			return true
		end
		if not a[1]:IsDirectory() and b[1]:IsDirectory() then
			return false
		end
		return a[2] < b[2]
	end)
	local order = {}
	for _, data in ipairs(t) do
		table.insert(order, data[3])
	end
	self.m_iconContainer:SetChildOrder(order)
end
function Element:CreateAssetIcon(path, assetName, isDirectory, importAsset)
	if isDirectory then
		return gui.AssetExplorer.CreateAssetIcon(self, path, assetName, isDirectory, importAsset)
	end

	local el = gui.create("WITutorialAssetIcon", self)
	el:SetAsset(path, assetName, importAsset)
	el:SetMouseInputEnabled(true)
	el:AddCallback("OnDoubleClick", function(el)
		local ptPath = util.Path(el:GetAsset())
		ptPath:PopFront()
		self:LoadTutorial(el:GetAsset())
	end)
	return el
end
function Element:LoadTutorial(asset)
	local path = util.Path.CreateFilePath(asset)
	path:PopFront()
	time.create_simple_timer(0.0, function()
		local pm = tool.get_filmmaker()
		if util.is_valid(pm) then
			pm:LoadTutorial(path:GetString())
		end
	end)
end
function Element:OnRemove() end
gui.register("WITutorialExplorer", Element)

-----------------

local Element = util.register_class("gui.TutorialAssetIcon", gui.AssetIcon)
function Element:OnInitialize()
	gui.AssetIcon.OnInitialize(self)
end
function Element:GetUdmData()
	return self.m_udmData
end
function Element:ApplyAsset(path, importAsset)
	local assetPath = self:GetAsset()
	local udmData, err = udm.load(assetPath)
	if udmData ~= false then
		udmData = udmData:GetAssetData():GetData()
		udmData = udmData:GetChildren()
		udmData = select(2, pairs(udmData)(udmData))
		self.m_udmData = udmData:ClaimOwnership()
		local icon = udmData:GetValue("icon", udm.TYPE_STRING) or ""
		if #icon > 0 then
			self:SetMaterial(icon)
		end

		local name = udmData:GetValue("name", udm.TYPE_STRING)
		if name ~= nil then
			local res, text = locale.get_text("pfm_tutorial_" .. name, true)
			if res ~= false then
				local posInSeries = udmData:GetValue("position_in_series", udm.TYPE_UINT32)
				if posInSeries ~= nil then
					text = string.fill_zeroes(tostring(posInSeries), 2) .. " - " .. text
				end
				self:SetText(text)
			end
		end
	else
		self:SetMaterial("error", self:GetWidth(), self:GetHeight())
	end
end
function Element:GetTypeIdentifier()
	return "tutorial"
end
gui.register("WITutorialAssetIcon", Element)

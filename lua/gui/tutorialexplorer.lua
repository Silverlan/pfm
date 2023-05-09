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
	local pm = tool.get_filmmaker()
	pm:LoadProject(asset)
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
		local title = udmData:GetValue("title", udm.TYPE_STRING) or ""
		if #title > 0 then
			self:SetText(title)
		end
	else
		self:SetMaterial("error", self:GetWidth(), self:GetHeight())
	end
end
function Element:GetTypeIdentifier()
	return "tutorial"
end
gui.register("WITutorialAssetIcon", Element)

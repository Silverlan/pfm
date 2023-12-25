--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/draganddrop.lua")
include("/gui/editableentry.lua")
include("/pfm/file_index_table.lua")

console.register_variable(
	"pfm_show_external_assets",
	udm.TYPE_BOOLEAN,
	true,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, the asset browsers will show assets that are not native to Pragma and have been found in external locations."
)

local Element = util.register_class("gui.PFMBaseCatalog", gui.Base)
function Element:OnRemove()
	util.remove(self.m_cbShowExternalAssets)
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)

	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(54, 54, 54))

	self.m_contents = gui.create("WIVBox", self.m_bg, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents:SetName("contents")
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	self.m_fit = self:InitializeFileIndexTable()

	self.m_teLocation = gui.create("WITextEntry", self.m_contents, 0, 0, self:GetWidth(), 24)
	self.m_teLocation:AddCallback("OnTextEntered", function(pEntry)
		self.m_explorer:SetPath(pEntry:GetText())
		self.m_explorer:Update()
	end)
	self.m_teLocationWrapper = self.m_teLocation:Wrap("WIEditableEntry")
	self.m_teLocationWrapper:SetText(locale.get_text("explorer_location"))

	local p = gui.create("WIPFMControlsMenu", self.m_contents)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p

	if self.m_externalAssetsEnabled ~= false then
		local elShowExternalAssets, wrapper = p:AddDropDownMenu(
			locale.get_text("pfm_show_external_assets"),
			"show_external_assets",
			{
				{ "0", locale.get_text("no") },
				{ "1", locale.get_text("yes") },
			},
			console.get_convar_bool("pfm_show_external_assets") and "1" or "0",
			function()
				local b = toboolean(
					self.m_elShowExternalAssets:GetOptionValue(self.m_elShowExternalAssets:GetSelectedOption())
				)
				console.run("pfm_show_external_assets", b and "1" or "0")

				self.m_explorer:SetShowExternalAssets(b)
			end
		)
		self.m_cbShowExternalAssets = console.add_change_callback("pfm_show_external_assets", function(old, new)
			elShowExternalAssets:SelectOption(new and "1" or "0")
		end)
		self.m_elShowExternalAssets = elShowExternalAssets
		self.m_elShowExternalAssetsWrapper = wrapper
		p:Update()
		p:SizeToContents()
	end

	local scrollContainer =
		gui.create("WIScrollContainer", self.m_contents, 0, 0, self:GetWidth(), self:GetHeight() - 72)
	scrollContainer:SetName("scroll_container")
	scrollContainer:SetContentsWidthFixed(true)
	--[[scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)]]

	if self.m_fit ~= nil then
		self.m_teFilter = gui.create("WITextEntry", self.m_contents, 0, 0, self:GetWidth(), 24)
		self.m_teFilter:AddCallback("OnTextEntered", function(pEntry)
			self.m_explorer:Refresh()
			self.m_explorer:ListFiles()
		end)
		local wrapper = self.m_teFilter:Wrap("WIEditableEntry")
		wrapper:SetText(locale.get_text("filter"))
		wrapper:SetName("filter")
	end

	local explorer = self:InitializeExplorer(scrollContainer)
	explorer:Setup()
	explorer:SetAutoAlignToParent(true, false)
	explorer:AddCallback("OnPathChanged", function(explorer, path)
		self.m_teLocation:SetText(path)
	end)
	if self.m_fit ~= nil then
		explorer:SetFilter(function(tFiles, tDirs)
			local filter = self.m_teFilter:GetText()
			if #filter == 0 then
				return tFiles, tDirs
			end
			local tMatches, similarities = string.find_similar_elements(filter, self.m_fit:GetFileNames(), 60)
			tFiles = {}
			tDirs = {}
			local threshold = -60
			-- If the filter is very short (3 characters or less), we need to increase the threshold value,
			-- otherwise we won't get any results at all
			if #filter == 3 then
				threshold = -50
			elseif #filter == 2 then
				threshold = -20
			elseif #filter == 1 then
				threshold = -5
			end
			for i, idx in ipairs(tMatches) do
				local sim = similarities[i]
				if sim < threshold then
					table.insert(tFiles, "/" .. self.m_fit:GetFilePath(idx) .. self.m_fit:GetFileName(idx))
				end
			end
			return tFiles, tDirs, true --[[ preSorted ]]
		end)
	else
		explorer:SetInactive(true)
	end
	self.m_explorer = explorer

	self.m_contents:Update()
	scrollContainer:SetAnchor(0, 0, 1, 1)
	self.m_teLocation:SetAnchor(0, 0, 1, 1)
	if self.m_fit ~= nil then
		self.m_teFilter:SetAnchor(0, 0, 1, 1)
	end

	self:EnableThinking()
	p:ResetControls()
end
function Element:SetExternalAssetsEnabled(enabled)
	self.m_externalAssetsEnabled = enabled
end
function Element:GetFilterElement()
	return self.m_teFilter
end
function Element:GetExplorer()
	return self.m_explorer
end
function Element:OnThink()
	-- Lazy initialization
	if self.m_fit ~= nil then
		self.m_fit:LoadOrGenerate()
		for _, path in ipairs(self.m_fitPaths) do
			self.m_fit:ReloadPath(path)
		end
	end
	self.m_explorer:SetInactive(false)
	self.m_explorer:Update()

	self:DisableThinking()
end
function Element:SetFitPaths(paths)
	self.m_fitPaths = paths
end
function Element:InitializeFileIndexTable() end
function Element:InitializeExplorer(baseElement)
	error("Function needs to be implemented by derived classes.")
end

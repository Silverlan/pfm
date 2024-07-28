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
Element.VIEW_MODE_ICON = 0
Element.VIEW_MODE_LIST = 1
function Element:OnRemove()
	util.remove(self.m_cbShowExternalAssets)
	util.remove(self.m_tooltipIcon)
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
		self:SetPath(pEntry:GetText())
	end)
	self.m_teLocationWrapper = self.m_teLocation:Wrap("WIEditableEntry")
	self.m_teLocationWrapper:SetText(locale.get_text("explorer_location"))

	local p = gui.create("WIPFMControlsMenu", self.m_contents)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p

	self.m_mode = Element.VIEW_MODE_ICON

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

	-- Explorer Mode
	local elExplorerMode, wrapper = p:AddDropDownMenu(
		locale.get_text("pfm_view_mode"),
		"explorer_mode",
		{
			{ tostring(Element.VIEW_MODE_ICON), locale.get_text("pfm_view_mode_icons") },
			{ tostring(Element.VIEW_MODE_LIST), locale.get_text("pfm_view_mode_list") },
		},
		tostring(Element.VIEW_MODE_ICON),
		function()
			local mode = self.m_elExplorerMode:GetOptionValue(self.m_elExplorerMode:GetSelectedOption())
			self:SetMode(toint(mode))
		end
	)
	self.m_elExplorerMode = elExplorerMode
	p:Update()
	p:SizeToContents()

	local scrollContainer =
		gui.create("WIScrollContainer", self.m_contents, 0, 0, self:GetWidth(), self:GetHeight() - 24 * 4)
	scrollContainer:SetName("scroll_container")
	scrollContainer:SetContentsWidthFixed(true)
	--[[scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)]]

	local explorer = self:CreateIconExplorer(scrollContainer)
	explorer:Setup()
	explorer:SetAutoAlignToParent(true, false)
	self:InitializeExplorer(explorer)
	self.m_explorer = explorer

	local listExplorer = gui.create("WIFileExplorer", self.m_contents)
	listExplorer:SetEnabledColumns({
		gui.WIFileExplorer.COLUMN_NAME,
		gui.WIFileExplorer.COLUMN_TYPE,
		gui.WIFileExplorer.COLUMN_DATE_MODIFIED,
	})
	listExplorer:SetAutoAlignToParent(true, true)
	listExplorer:SetRootPath(explorer:GetRootPath())
	listExplorer:SetPath(explorer:GetPath())
	listExplorer:AddCallback("OnFileMouseEvent", function(listExplorer, row, filePath, button, state, mods)
		self:OnListFileMouseEvent(row, filePath, button, state, mods)
	end)
	listExplorer:AddCallback("OnFileRowAdded", function(listExplorer, row, fPath)
		local colIdx = listExplorer:GetColumnIndex(gui.WIFileExplorer.COLUMN_NAME)
		if colIdx ~= nil then
			local cellName = row:GetCell(colIdx)
			if util.is_valid(cellName) then
				cellName:SetTooltip(" ")
				cellName:AddCallback("OnShowTooltip", function(el, elTooltip)
					self:ShowTooltipIcon(elTooltip, fPath)
				end)
				cellName:AddCallback("OnHideTooltip", function(el, elTooltip)
					util.remove(self.m_tooltipIcon)
				end)
			end
		end
	end)
	self:InitializeExplorer(listExplorer)
	self.m_listExplorer = listExplorer

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

	for _, el in ipairs({ explorer, listExplorer }) do
		el:AddCallback("OnPathChanged", function(explorer, path)
			self.m_teLocation:SetText(path)
		end)
		if self.m_fit ~= nil then
			el:SetFilter(function(tFiles, tDirs)
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
			if el.SetInactive ~= nil then
				el:SetInactive(true)
			end
		end
	end

	listExplorer:SetVisible(false)

	self.m_contents:Update()
	scrollContainer:SetAnchor(0, 0, 1, 1)
	self.m_scrollContainer = scrollContainer
	self.m_teLocation:SetAnchor(0, 0, 1, 1)
	if self.m_fit ~= nil then
		self.m_teFilter:SetAnchor(0, 0, 1, 1)
	end

	self:EnableThinking()
	p:ResetControls()
end
function Element:ShowTooltipIcon(elTooltip, fPath)
	util.remove(self.m_tooltipIcon)
	local el =
		self.m_explorer:CreateAssetIconElement(file.get_file_path(fPath), file.get_file_name(fPath), false, false)
	el:SetParent(elTooltip)
	el:SetZPos(100000)
	el:SetTooltip("") -- Clear tooltip
	elTooltip:SizeToContents()
	self.m_tooltipIcon = el
end
function Element:OnListFileMouseEvent(row, filePath, button, state, mods)
	if button == input.MOUSE_BUTTON_RIGHT then
		if state == input.STATE_PRESS then
			-- TODO: Show asset context menu
		end
		return util.EVENT_REPLY_HANDLED
	end
end
function Element:GetMode()
	return self.m_mode
end
function Element:SetMode(mode)
	if mode == self.m_mode then
		return
	end
	self.m_mode = mode

	if mode == Element.VIEW_MODE_ICON then
		self.m_scrollContainer:SetVisible(true)
		self.m_listExplorer:SetVisible(false)
		self.m_explorer:SetPath(self.m_listExplorer:GetPath())
		self.m_explorer:Update()
	elseif mode == Element.VIEW_MODE_LIST then
		self.m_scrollContainer:SetVisible(false)
		self.m_listExplorer:SetVisible(true)
		self.m_listExplorer:SetPath(self.m_explorer:GetPath())
		self.m_listExplorer:Update()
	end
end
function Element:SetPath(path)
	local explorer = self:GetExplorer()
	explorer:SetPath(path)
	explorer:Update()
end
function Element:SetExternalAssetsEnabled(enabled)
	self.m_externalAssetsEnabled = enabled
end
function Element:GetFilterElement()
	return self.m_teFilter
end
function Element:GetIconExplorer()
	return self.m_explorer
end
function Element:GetListExplorer()
	return self.m_listExplorer
end
function Element:GetExplorer()
	if self.m_mode == Element.VIEW_MODE_ICON then
		return self.m_explorer
	end
	return self.m_listExplorer
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
function Element:CreateIconExplorer(baseElement)
	error("Function needs to be implemented by derived classes.")
end

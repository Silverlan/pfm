--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/materialexplorer.lua")
include("/gui/editableentry.lua")
include("/pfm/file_index_table.lua")

util.register_class("gui.PFMMaterialCatalog", gui.Base)

function gui.PFMMaterialCatalog:__init()
	gui.Base.__init(self)
end
function gui.PFMMaterialCatalog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)

	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(54, 54, 54))

	self.m_contents = gui.create("WIVBox", self.m_bg, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	local fit = pfm.FileIndexTable(
		"materials",
		"materials/",
		asset.get_supported_extensions(asset.TYPE_MATERIAL),
		{ "vmt", "vmat_c" }
	)
	self.m_fit = fit

	self.m_teLocation = gui.create("WITextEntry", self.m_contents, 0, 0, self:GetWidth(), 24)
	self.m_teLocation:AddCallback("OnTextEntered", function(pEntry)
		self.m_explorer:SetPath(pEntry:GetText())
		self.m_explorer:Update()
	end)
	self.m_teLocation:Wrap("WIEditableEntry"):SetText(locale.get_text("explorer_location"))

	local scrollContainer =
		gui.create("WIScrollContainer", self.m_contents, 0, 0, self:GetWidth(), self:GetHeight() - 48)
	scrollContainer:SetContentsWidthFixed(true)
	--[[scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)]]

	self.m_teFilter = gui.create("WITextEntry", self.m_contents, 0, 0, self:GetWidth(), 24)
	self.m_teFilter:AddCallback("OnTextEntered", function(pEntry)
		self.m_explorer:Refresh()
		self.m_explorer:ListFiles()
	end)
	self.m_teFilter:Wrap("WIEditableEntry"):SetText(locale.get_text("filter"))

	local explorer = gui.create("WIMaterialExplorer", scrollContainer, 0, 0, self:GetWidth(), self:GetHeight())
	explorer:SetAutoAlignToParent(true, false)
	explorer:SetRootPath("materials")
	explorer:SetExtensions(asset.get_supported_extensions(asset.TYPE_MATERIAL))
	explorer:AddCallback("OnPathChanged", function(explorer, path)
		self.m_teLocation:SetText(path)
	end)
	explorer:SetFilter(function(tFiles, tDirs)
		local filter = self.m_teFilter:GetText()
		if #filter == 0 then
			return tFiles, tDirs
		end
		local tMatches, similarities = string.find_similar_elements(filter, self.m_fit:GetFileNames(), 60)
		tFiles = {}
		tDirs = {}
		for i, idx in ipairs(tMatches) do
			local sim = similarities[i]
			if sim < -60 then
				table.insert(tFiles, "/" .. self.m_fit:GetFilePath(idx) .. self.m_fit:GetFileName(idx))
			end
		end
		return tFiles, tDirs, true --[[ preSorted ]]
	end)
	explorer:SetInactive(true)
	self.m_explorer = explorer

	self.m_contents:Update()
	scrollContainer:SetAnchor(0, 0, 1, 1)
	self.m_teLocation:SetAnchor(0, 0, 1, 1)
	self.m_teFilter:SetAnchor(0, 0, 1, 1)

	self:EnableThinking()
end
function gui.PFMMaterialCatalog:OnThink()
	-- Lazy initialization
	self.m_fit:LoadOrGenerate()
	self.m_fit:ReloadPath("addons/imported/materials/")
	self.m_fit:ReloadPath("addons/converted/materials/")
	self.m_explorer:SetInactive(false)
	self.m_explorer:Update()

	self:DisableThinking()
end
gui.register("WIPFMMaterialCatalog", gui.PFMMaterialCatalog)

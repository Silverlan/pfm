--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/gridbox.lua")
include("/gui/wibasefileexplorer.lua")
include("/gui/asseticon.lua")
include("/gui/icongridview.lua")

util.register_class("gui.ModelExplorer",gui.IconGridView,gui.BaseFileExplorer)
function gui.ModelExplorer:__init()
	gui.IconGridView.__init(self)
	gui.BaseFileExplorer.__init(self)
end
function gui.ModelExplorer:OnInitialize()
	gui.IconGridView.OnInitialize(self)

	self.m_favorites = {} -- TODO: Load/Save from/to file
	self:AddCallback("OnIconSelected",function(self,icon)
		self:CallCallbacks("OnFileClicked",icon:GetText())
	end)
	self:SetIconFactory(function(parent)
		return gui.create("WIAssetIcon",parent)
	end)
end
function gui.ModelExplorer:AddToFavorites(mdl)
	self.m_favorites[mdl] = true
end
function gui.ModelExplorer:IsInFavorites(mdl)
	return self.m_favorites[mdl] == true
end
function gui.ModelExplorer:RemoveFromFavorites(mdl)
	self.m_favorites[mdl] = nil
end
function gui.ModelExplorer:GetFavorites() return self.m_favorites end
function gui.ModelExplorer:OnUpdate()
	self:ListFiles()
end
function gui.ModelExplorer:AddIcon(assetName,fDirClickHandler)
	local el = gui.IconGridView.AddIcon(self,assetName)
	if(el == nil) then return end

	local path = self:GetAbsolutePath()
	el:SetAsset(path,assetName,(fDirClickHandler ~= nil) or file.is_directory(path .. assetName))

	if(el:IsDirectory()) then
		el:AddCallback("OnDoubleClick",function(el)
			if(util.is_valid(self) == false) then return end
			if(fDirClickHandler ~= nil) then fDirClickHandler()
			else
				self:SetPath(self:GetPath() .. assetName)
				self:Update()
			end
			--self:CallCallbacks("OnFileSelected",fPath)
		end)
	else
		el:AddCallback("PopulateContextMenu",function(el,pContext)
			local path = util.Path(el:GetAsset())
			path:MakeRelative(self:GetRootPath())
			path = path:GetString()
			if(self:IsInFavorites(path)) then
				pContext:AddItem(locale.get_text("pfm_asset_icon_remove_from_favorites"),function()
					self:RemoveFromFavorites(path)
					if(self.m_inFavorites) then
						self:ReloadPath()
						self:ScheduleUpdate()
					end
				end)
			else
				pContext:AddItem(locale.get_text("pfm_asset_icon_add_to_favorites"),function()
					self:AddToFavorites(path)
				end)
			end
			pContext:AddItem(locale.get_text("pfm_show_in_model_viewer"),function()
				local pDialog,frame,el = gui.open_model_dialog()
				el:SetModel(path)
			end)
		end)
	end
	return el
end
function gui.ModelExplorer:ListFiles()
	for _,icon in ipairs(self.m_icons) do
		if(icon:IsValid()) then icon:RemoveSafely() end
	end
	self.m_icons = {}

	if(self.m_inFavorites) then
		self:AddIcon("..",function()
			self.m_inFavorites = nil
			self:Update()
		end)
		for f,b in pairs(self:GetFavorites()) do
			self:AddIcon(f)
		end
		self.m_iconContainer:Update()
		return
	end
	local tFiles,tDirectories = self:FindFiles()
	if(self:IsAtRoot()) then
		self:AddIcon("favorites",function()
			self.m_inFavorites = true
			self:Update()
		end)
	end
	for _,d in ipairs(tDirectories) do
		self:AddIcon(d)
	end
	for _,f in ipairs(tFiles) do
		self:AddIcon(f)
	end
	self.m_iconContainer:Update()
end
gui.register("WIModelExplorer",gui.ModelExplorer)

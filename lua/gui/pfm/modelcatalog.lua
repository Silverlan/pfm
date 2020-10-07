--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/modelexplorer.lua")
include("/gui/draganddrop.lua")
include("/gui/editableentry.lua")
include("/pfm/file_index_table.lua")

util.register_class("gui.PFMModelCatalog",gui.Base)

function gui.PFMModelCatalog:__init()
	gui.Base.__init(self)
end
function gui.PFMModelCatalog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIVBox",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	local fit = pfm.FileIndexTable("models","models/",{"wmd"},{"mdl","vmdl_c","nif"})
	self.m_fit = fit

	self.m_teLocation = gui.create("WITextEntry",self.m_contents,0,0,self:GetWidth(),24)
	self.m_teLocation:AddCallback("OnTextEntered",function(pEntry)
		self.m_explorer:SetPath(pEntry:GetText())
		self.m_explorer:Update()
	end)
	self.m_teLocation:Wrap("WIEditableEntry"):SetText(locale.get_text("explorer_location"))

	local scrollContainer = gui.create("WIScrollContainer",self.m_contents,0,0,self:GetWidth(),self:GetHeight() -48)
	scrollContainer:SetContentsWidthFixed(true)
	--[[scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)]]

	self.m_teFilter = gui.create("WITextEntry",self.m_contents,0,0,self:GetWidth(),24)
	self.m_teFilter:AddCallback("OnTextEntered",function(pEntry)
		self.m_explorer:Refresh()
		self.m_explorer:ListFiles()
	end)
	self.m_teFilter:Wrap("WIEditableEntry"):SetText(locale.get_text("filter"))

	local explorer = gui.create("WIModelExplorer",scrollContainer,0,0,self:GetWidth(),self:GetHeight())
	explorer:SetAutoAlignToParent(true,false)
	explorer:SetRootPath("models")
	explorer:SetExtensions({"wmd"})
	explorer:AddCallback("OnPathChanged",function(explorer,path)
		self.m_teLocation:SetText(path)
	end)
	explorer:AddCallback("OnFilesDropped",function(explorer,tFiles)
		local reloadDirectory = false
		for _,fileName in ipairs(tFiles) do
			local f = game.open_dropped_file(fileName,true)
			if(f ~= nil) then
				local outputPath = explorer:GetPath()
				local modelName = file.remove_file_extension(outputPath .. file.get_file_name(fileName)) .. ".wmd"
				if(asset.exists(modelName,asset.TYPE_MODEL) == false) then
					local mdl,errMsg = asset.import_model(f,outputPath)
					if(mdl ~= false) then reloadDirectory = true
					else console.print_warning("Unable to import model '" .. fileName .. "': " .. errMsg) end
				end
			end
		end
		if(reloadDirectory == true) then
			explorer:Refresh()
			explorer:Update()
		end
		return util.EVENT_REPLY_HANDLED
	end)
	explorer:SetFilter(function(tFiles,tDirs)
		local filter = self.m_teFilter:GetText()
		if(#filter == 0) then return tFiles,tDirs end
		local tMatches,similarities = string.find_similar_elements(filter,self.m_fit:GetFileNames(),60)
		tFiles = {}
		tDirs = {}
		for i,idx in ipairs(tMatches) do
			local sim = similarities[i]
			if(i < 10 or sim < -60) then
				table.insert(tFiles,"/" .. self.m_fit:GetFilePath(idx) .. self.m_fit:GetFileName(idx))
			end
		end
		return tFiles,tDirs
	end)
	self.m_explorer = explorer

	self.m_contents:Update()
	scrollContainer:SetAnchor(0,0,1,1)
	self.m_teLocation:SetAnchor(0,0,1,1)
	self.m_teFilter:SetAnchor(0,0,1,1)

	self:EnableThinking()
end
function gui.PFMModelCatalog:GetExplorer() return self.m_explorer end
function gui.PFMModelCatalog:OnThink()
	-- Lazy initialization
	self.m_fit:LoadOrGenerate()
	self.m_explorer:Update()

	self:DisableThinking()
end
gui.register("WIPFMModelCatalog",gui.PFMModelCatalog)

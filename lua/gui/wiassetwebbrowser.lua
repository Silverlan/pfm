--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")

local Element = util.register_class("gui.AssetWebBrowser",gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512,512)

	local r = engine.load_library("chromium/pr_chromium")
	if(r ~= true) then
		console.print_warning("An error occured trying to load the 'pr_chromium' module: ",r)
		return
	end

	local r = gui.create("WIBase",self,0,0,512,512,0,0,1,1)

	local links = {}
	local linkMap = {}
	local function addLink(id,name,url)
		table.insert(links,{id = id,name = name,url = url})
		linkMap[id] = #links
	end
	addLink("pfm_wiki","PFM Wiki","https://wiki.pragma-engine.com/books/pragma-filmmaker")
	addLink("supporter_hub","Supporter Hub","https://supporter.pragma-engine.com")
	addLink("sfm_lab","SFM Lab","https://sfmlab.com/")
	addLink("open3d_lab","Open3DLab","https://open3dlab.com/")
	addLink("sfm_workshop","SFM Workshop","https://steamcommunity.com/workshop/browse/?appid=1840sour")
	addLink("pragma_workshop","Pragma Workshop","https://steamcommunity.com/app/947100/workshop/")

	local menu = gui.create("WIDropDownMenu",self)
	for _,link in ipairs(links) do
		menu:AddOption(link.name,link.id)
	end
	
	menu:AddCallback("OnOptionSelected",function()
		local i = linkMap[menu:GetOptionValue(menu:GetSelectedOption())]
		if(i == nil) then return end
		local linkData = links[i]
		if(util.is_valid(self.m_webBrowser)) then self.m_webBrowser:LoadUrl(linkData.url) end
	end)
	menu:SetWidth(self:GetWidth())
	menu:SetAnchor(0,0,1,0)

	self.m_webBrowser = self:InitializeBrowser(self,self:GetWidth(),self:GetHeight())
	if(util.is_valid(self.m_webBrowser)) then
		self.m_webBrowser:SetY(menu:GetBottom())

		self.m_webBrowser:AddCallback("SetSize",function()
			-- We don't want to reload the texture constantly if the element is being resized by a user,
			-- so we'll only update after the element hasn't been resized for at least 0.25 seconds
			self.m_tNextBrowserResize = time.real_time() +0.25
			self:SetThinkingEnabled(true)
		end)
		self.m_webBrowser:SetSize(self:GetWidth(),400)
		self.m_webBrowser:SetAnchor(0,0,1,1)

		local log = self:InitializeLog(self)
		log:SetSize(self:GetWidth(),self:GetHeight() -self.m_webBrowser:GetBottom())
		log:SetY(self.m_webBrowser:GetBottom())
		log:SetAnchor(0,1,1,1)
	end
end
function Element:OnFocusGained()
	if(util.is_valid(self.m_webBrowser)) then self.m_webBrowser:RequestFocus() end
end
function Element:OnThink()
	if(time.real_time() < self.m_tNextBrowserResize) then return end
	self.m_tNextBrowserResize = nil
	self:SetThinkingEnabled(false)

	local w = self.m_webBrowser:GetWidth()
	local h = self.m_webBrowser:GetHeight()

	-- TODO: For some reason if the width is not divisible by 8, the image will be skewed (some kind of stride alignment?)
	if((w %8) > 0) then w = w -(w %8) end
	self.m_webBrowser:SetBrowserViewSize(Vector2i(w,h))
	self.m_webBrowser:Update()
end
function Element:GetWebBrowser() return self.m_webBrowser end
function Element:InitializeBrowser(parent,w,h)
	local el = gui.create("WIWeb",parent)
	el:SetBrowserViewSize(Vector2i(w,h))
	el:SetSize(w,h)
	el:SetInitialUrl("https://sfmlab.com/")

	self.m_downloads = {}
	el:AddCallback("OnDownloadUpdate",function(el,id,state,percentage)
		if(util.is_valid(self.m_log) == false or self.m_downloads[id] == nil) then return end
		local path = self.m_downloads[id]
		if(state == chromium.DOWNLOAD_STATE_CANCELLED) then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been cancelled!")
			self.m_downloads[id] = nil
		elseif(state == chromium.DOWNLOAD_STATE_COMPLETE) then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been completed!")
			self:ImportDownloadAssets(path)
			self.m_downloads[id] = nil
		elseif(state == chromium.DOWNLOAD_STATE_INVALIDATED) then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been invalidated!")
			self.m_downloads[id] = nil
		else
			self.m_log:AppendText("\nDownload progress for '" .. file.get_file_name(path:GetString()) .. "': " .. percentage .. "%")
		end
	end)
	el:AddCallback("OnDownloadStarted",function(el,id,path)
		if(util.is_valid(self.m_log) == false) then return end
		self.m_log:AppendText("\nDownload started: " .. file.get_file_name(path:GetString()))
		self.m_downloads[id] = path
	end)
	return el
end
function Element:ImportDownloadAssets(path)
	local zipFile = util.ZipFile.open(path:GetString(),util.ZipFile.OPEN_MODE_READ)
	if(zipFile == nil) then
		self.m_log:AppendText("\nUnable to open zip-archive '" .. path:GetString() .. "': Unsupported archive format?")
		return
	end
	local files = zipFile:GetFileList()
	local tMaterials = {}
	local tModels = {}
	local tMaps = {}
	for _,f in ipairs(files) do
		local path = util.Path.CreateFilePath(f)
		if(path:IsFile()) then
			local nCur = 0
			local c,n = path:GetComponent(nCur)
			while(c ~= nil) do
				local t
				c = c:lower()
				if(c == "models") then t = tModels
				elseif(c == "materials") then t = tMaterials
				elseif(c == "maps") then t = tMaps end
				if(t ~= nil) then
					table.insert(t,{path:GetString():sub(nCur +1),f})
					break
				end
				nCur = n
				c,n = path:GetComponent(nCur)
			end
		end
	end

	local extractedFiles = {}
	for _,t in ipairs({tMaterials,tModels,tMaps}) do
		for _,f in ipairs(t) do
			local outPath = "addons/imported/" .. f[1]
			self.m_log:AppendText("\nExtracing file '" .. f[2] .. "' to '" .. outPath .. "'...")
			local result,msg = zipFile:ExtractFile(f[2],outPath)
			if(result == false) then
				self.m_log:AppendText("\n{[c:ff0000]}Failed to extract file: " .. msg .. "{[/c]}")
			else table.insert(extractedFiles,outPath) end
		end
	end

	local function find_assets(t,assetExt,type)
		local assets = {}
		for _,f in ipairs(t) do
			local ext = file.get_file_extension(f[1])
			if(ext ~= nil and ext:lower() == assetExt) then
				local path = util.Path.CreateFilePath(f[1])
				path:PopFront()
				path:RemoveFileExtension()
				self.m_log:AppendText("\nDetected " .. type .. ": '" .. path:GetString() .. "'")
				table.insert(assets,path:GetString())
			end
		end
		return assets
	end
	find_assets(tMaterials,"vmt","material")
	local mdlAssets = find_assets(tModels,"mdl","model")
	find_assets(tMaps,"bsp","map")

	zipFile = nil
	collectgarbage()

	local function import_next_model()
		if(#mdlAssets == 0) then
			self.m_log:AppendText("\nAll models have been imported successfully!")
			self.m_log:AppendText("\nRemoving temporary files...")
			-- We don't need to keep the materials or models around, because they have been
			-- converted to native formats. We do, however, need to keep the textures.
			for _,f in ipairs(extractedFiles) do
				local ext = file.get_file_extension(f)
				if(ext == nil or ext:lower() ~= "vtf") then
					file.delete(f)
				end
			end
			file.delete(path:GetString())
			return
		end
		local mdl = mdlAssets[1]
		table.remove(mdlAssets,1)
		time.create_simple_timer(0.25,function()
			self.m_log:AppendText("\nImporting model '" .. mdl .. "'...")
			local mdl = game.load_model(mdl)
			if(mdl ~= nil) then self.m_log:AppendText("\nModel has been imported successfully!")
			else self.m_log:AppendText("\n{[c:ff0000]}Failed to import model!{[/c]}") end
			asset.clear_unused(asset.TYPE_MODEL)
			asset.clear_unused(asset.TYPE_MATERIAL)
			asset.clear_unused(asset.TYPE_TEXTURE)
			import_next_model()
		end)
	end
	import_next_model()
end
function Element:InitializeLog(parent)
	local elBg = gui.create("WIRect",parent)

	local scrollContainer = gui.create("WIScrollContainer",elBg)
	scrollContainer:SetAutoStickToBottom(true)
	scrollContainer:SetAutoAlignToParent(true)

	local log = gui.create("WITextEntry",scrollContainer)
	log:SetMultiLine(true)
	log:SetEditable(false)
	log:SetSelectable(true)

	engine.create_font("chromium_log","vera/VeraMono",12)

	local elText = log:GetTextElement()
	elText:SetFont("chromium_log")
	elText:SetAutoBreakMode(gui.Text.AUTO_BREAK_WHITESPACE)
	elText:SetTagsEnabled(true)
	log:SetWidth(self:GetWidth())

	util.remove(log:FindDescendantByName("background"))
	util.remove(log:FindDescendantByName("background_outline"))

	elText:AppendText("Log")
	self.m_log = elText
	return elBg
end
gui.register("WIAssetWebBrowser",Element)

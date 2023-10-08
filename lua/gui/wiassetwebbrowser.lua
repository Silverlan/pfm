--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/gui/info_box.lua")
include("/util/util_asset_import.lua")

console.register_variable(
	"pfm_web_browser_enable_mature_content",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, no message prompt will be shown when visiting bookmarks with adult content."
)

local Element = util.register_class("gui.AssetWebBrowser", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 512)

	local r = engine.load_library("chromium/pr_chromium")
	if r ~= true then
		console.print_warning("An error occured trying to load the 'pr_chromium' module: ", r)
		return
	end

	self.m_contents = gui.create("WIVBox", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	local p = gui.create("WIPFMControlsMenu", self.m_contents)
	p:SetAutoFillContentsToWidth(true)
	p:SetAutoFillContentsToHeight(false)
	self.m_settingsBox = p

	local elBookmarks, wrapper
	elBookmarks, wrapper = p:AddDropDownMenu("Bookmarks", "bookmark", {}, "pfm_wiki", function(menu, option)
		local id = menu:GetOptionValue(option)
		local i = self.m_linkMap[id]
		if i == nil then
			return
		end
		local linkData = self.m_links[i]
		if util.is_valid(self.m_webBrowser) then
			if linkData.hasAdultContent then
				tool.get_filmmaker():ShowMatureContentPrompt(function()
					self.m_webBrowser:LoadUrl(linkData.url)
				end, function()
					elBookmarks:SelectOption("pfm_wiki")
				end)
			else
				self.m_webBrowser:LoadUrl(linkData.url)
			end
		end
	end)
	self.m_bookmarkMenu = elBookmarks
	wrapper:SetUseAltMode(true)
	local elUrl, wrapper = p:AddTextEntry("URL", "url", "", function(el)
		if util.is_valid(self.m_webBrowser) == false then
			return
		end
		self.m_webBrowser:LoadUrl(el:GetText())
	end)
	p:Update()
	p:SizeToContents()

	self.m_infoBox = gui.create_info_box(self.m_contents, "", gui.InfoBox.TYPE_WARNING)

	self.m_webBrowser = self:InitializeBrowser(self.m_contents, self:GetWidth(), self:GetHeight())
	if util.is_valid(self.m_webBrowser) then
		self.m_webBrowser:AddCallback("SetSize", function()
			-- We don't want to reload the texture constantly if the element is being resized by a user,
			-- so we'll only update after the element hasn't been resized for at least 0.25 seconds
			self.m_tNextBrowserResize = time.real_time() + 0.25
			self:SetThinkingEnabled(true)
		end)
		self.m_webBrowser:AddCallback("OnAddressChanged", function(el, addr)
			elUrl:SetText(addr)
		end)
		self.m_webBrowser:SetSize(self:GetWidth(), 400)

		local log = self:InitializeLog(self.m_contents)
		log:SetName("log")
		log:SetSize(self:GetWidth(), 80)
		self.m_contents:SetAutoFillTarget(self.m_webBrowser)
	end

	self:UpdateBookmarks()
	p:ResetControls()
end
function Element:OnRemove()
	util.remove(self.m_downloadProgressBar)
end
function Element:ReloadURL()
	if util.is_valid(self.m_webBrowser) == false then
		return
	end
	local url = self.m_webBrowser:GetUrl()
	self.m_webBrowser:LoadUrl(url)
end
function Element:GetUrl()
	if util.is_valid(self.m_webBrowser) == false then
		return ""
	end
	return self.m_webBrowser:GetUrl()
end
function Element:SetUrl(url)
	if util.is_valid(self.m_webBrowser) == false then
		return
	end
	self.m_webBrowser:LoadUrl(url)
end
function Element:UpdateInfoBox()
	if util.is_valid(self.m_webBrowser) == false then
		return
	end
	local url = self.m_webBrowser:GetUrl()
	local parts = chromium.parse_url(url)
	if parts == nil then
		return
	end
	self.m_infoBox:SetVisible(true)
	if parts.host == "sfmlab.com" then
		self.m_infoBox:SetText(
			locale.get_text(
				"pfm_web_browser_bookmark_info",
				{ "SFM Lab", '{[l:url "https://patreon.com/sfmlab/"]}https://patreon.com/sfmlab/{[/l]}' }
			)
		)
	elseif parts.host == "open3dlab.com" then
		self.m_infoBox:SetText(
			locale.get_text(
				"pfm_web_browser_bookmark_info",
				{ "Open3DLab", '{[l:url "https://patreon.com/sfmlab/"]}https://patreon.com/sfmlab/{[/l]}' }
			)
		)
	elseif parts.host == "smutba.se" then
		self.m_infoBox:SetText(
			locale.get_text(
				"pfm_web_browser_bookmark_info",
				{ "SmutBase", '{[l:url "https://patreon.com/sfmlab/"]}https://patreon.com/sfmlab/{[/l]}' }
			)
		)
	elseif parts.host == "lordaardvark.com" then
		self.m_infoBox:SetText(locale.get_text("pfm_web_browser_bookmark_info", {
			"This Website",
			'{[l:url "https://www.patreon.com/lordaardvarksfm"]}https://www.patreon.com/lordaardvarksfm{[/l]}',
		}))
	elseif parts.host == "wiki.pragma-engine.com" then
		self.m_infoBox:SetText("Placeholder")
	else
		self.m_infoBox:SetVisible(false)
	end
	self.m_infoBox:SizeToContents()
end
function Element:UpdateBookmarks()
	local p = self.m_settingsBox
	local links = {}
	local linkMap = {}
	local function addLink(id, name, url, hasAdultContent)
		table.insert(links, { id = id, name = name, url = url, hasAdultContent = hasAdultContent })
		linkMap[id] = #links
	end
	addLink("pfm_wiki", "PFM Wiki", "https://wiki.pragma-engine.com/books/pragma-filmmaker")
	addLink("lua_api", "Lua API", "https://wiki.pragma-engine.com/api/docs")
	addLink("supporter_hub", "Supporter Hub", "https://supporter.pragma-engine.com")
	addLink("sfm_lab", "SFM Lab", "https://sfmlab.com/", true)
	addLink("open3d_lab", "Open3DLab", "https://open3dlab.com/", true)
	addLink("smut_base", "SmutBase", "https://smutba.se/", true)
	addLink(
		"lord_aardvark",
		"Lord Aardvark",
		"https://lordaardvark.com/html/assets.html?cat=Models&sect=Characters",
		true
	)
	-- addLink("sfm_workshop","SFM Workshop","https://steamcommunity.com/workshop/browse/?appid=1840sour")
	-- addLink("pragma_workshop","Pragma Workshop","https://steamcommunity.com/app/947100/workshop/")

	self.m_links = links
	self.m_linkMap = linkMap
	self.m_bookmarkMenu:ClearOptions()
	for _, linkData in ipairs(links) do
		self.m_bookmarkMenu:AddOption(linkData.name, linkData.id):SetName(linkData.id)
	end
end
function Element:OnFocusGained()
	if util.is_valid(self.m_webBrowser) then
		self.m_webBrowser:RequestFocus()
	end
end
function Element:OnThink()
	if time.real_time() < self.m_tNextBrowserResize then
		return
	end
	self.m_tNextBrowserResize = nil
	self:SetThinkingEnabled(false)

	local w = self.m_webBrowser:GetWidth()
	local h = self.m_webBrowser:GetHeight()

	-- TODO: For some reason if the width is not divisible by 8, the image will be skewed (some kind of stride alignment?)
	if (w % 8) > 0 then
		w = w - (w % 8)
	end
	self.m_webBrowser:SetBrowserViewSize(Vector2i(w, h))
	self.m_webBrowser:Update()
end
function Element:GetWebBrowser()
	return self.m_webBrowser
end
function Element:InitializeBrowser(parent, w, h)
	local el = gui.create("WIWeb", parent)
	el:SetName("browser")
	el:SetBrowserViewSize(Vector2i(w, h))
	el:SetSize(w, h)
	el:SetInitialUrl("https://wiki.pragma-engine.com/books/pragma-filmmaker")

	self.m_downloads = {}
	el:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			el:RequestFocus()
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	el:AddCallback("OnLoadingStateChange", function(el, isLoading, canGoBack, canGoForward)
		self:UpdateInfoBox()
		--[[if isLoading == true then
			return
		end
		local url = el:GetUrl()
		local parts = chromium.parse_url(url)
		if parts == nil or parts.host ~= "sfmlab.com" then
			return
		end
		if self:IsFullNsfwContentEnabled() then
			-- Enable "18+" and "Furry" content
			for _, button in ipairs({ "nsfw", "furry" }) do
				el:ExecuteJavaScript(
					"var el = document.querySelector('[adultcontent=\"0\"]').shadowRoot.querySelector('[identifier=\""
						.. button
						.. "\"]');"
						.. "var event = new MouseEvent('click', {});"
						.. "var toggleState = el.getAttribute('togglestate');"
						.. "if(toggleState == '0')"
						.. "{"
						.. "	el.shadowRoot.querySelector('.toggle-switch-element').dispatchEvent(event);"
						.. "}"
						.. "else if(toggleState == '2')"
						.. "{"
						.. "	el.shadowRoot.querySelector('.toggle-switch-element').dispatchEvent(event);"
						.. "	el.shadowRoot.querySelector('.toggle-switch-element').dispatchEvent(event);"
						.. "}"
				)
			end
		end]]
	end)
	el:AddCallback("OnDownloadUpdate", function(el, id, state, percentage)
		if util.is_valid(self.m_log) == false or self.m_downloads[id] == nil then
			return
		end
		self:CallCallbacks("OnDownloadUpdate", id, state, percentage)
		local path = self.m_downloads[id]
		if state == chromium.DOWNLOAD_STATE_CANCELLED then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been cancelled!")
			self.m_downloads[id] = nil

			if id == self.m_downloadProgressBarDownloadId then
				util.remove(self.m_downloadProgressBar)
			end
		elseif state == chromium.DOWNLOAD_STATE_COMPLETE then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been completed!")
			self:ImportDownloadAssets(path)
			file.delete(path:GetString())
			self.m_downloads[id] = nil

			if id == self.m_downloadProgressBarDownloadId then
				util.remove(self.m_downloadProgressBar)
			end
		elseif state == chromium.DOWNLOAD_STATE_INVALIDATED then
			self.m_log:AppendText("\nDownload '" .. file.get_file_name(path:GetString()) .. "' has been invalidated!")
			self.m_downloads[id] = nil

			if id == self.m_downloadProgressBarDownloadId then
				util.remove(self.m_downloadProgressBar)
			end
		else
			self.m_log:AppendText(
				"\nDownload progress for '" .. file.get_file_name(path:GetString()) .. "': " .. percentage .. "%"
			)
			if util.is_valid(self.m_downloadProgressBar) and id == self.m_downloadProgressBarDownloadId then
				self.m_downloadProgressBar:SetProgress(percentage / 100.0)
			end
		end
	end)
	el:AddCallback("OnDownloadStarted", function(el, id, path)
		if util.is_valid(self.m_log) == false then
			return
		end
		self.m_log:AppendText("\nDownload started: " .. file.get_file_name(path:GetString()))
		self.m_downloads[id] = path

		local pm = tool.get_filmmaker()
		if util.is_valid(pm) then
			util.remove(self.m_downloadProgressBar)
			self.m_downloadProgressBar = pm:AddProgressStatusBar("download", locale.get_text("pfm_downloading_file"))
			self.m_downloadProgressBarDownloadId = id
		end

		self:CallCallbacks("OnDownloadStarted", id, path)
	end)
	return el
end
function Element:ImportDownloadAssets(path)
	util.import_assets(path:GetString(), {
		modelImportCallback = function(msg, severity)
			if severity ~= log.SEVERITY_INFO then
				msg = "\n{[c:ff0000]}" .. msg .. "{[/c]}"
			else
				msg = "\n" .. msg
			end
			self.m_log:AppendText(msg)
		end,
		onComplete = function()
			self:CallCallbacks("OnDownloadAssetsImported")
		end,
	})
end
function Element:InitializeLog(parent)
	local elBg = gui.create("WIRect", parent)

	local scrollContainer = gui.create("WIScrollContainer", elBg)
	scrollContainer:SetAutoStickToBottom(true)
	scrollContainer:SetAutoAlignToParent(true)

	local log = gui.create("WITextEntry", scrollContainer)
	log:SetMultiLine(true)
	log:SetEditable(false)
	log:SetSelectable(true)

	engine.create_font(
		"chromium_log",
		engine.get_default_font_set_name(),
		bit.bor(engine.FONT_FEATURE_FLAG_SANS_BIT, engine.FONT_FEATURE_FLAG_MONO_BIT),
		12
	)

	local elText = log:GetTextElement()
	elText:SetMaxLineCount(100)
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
gui.register("WIAssetWebBrowser", Element)

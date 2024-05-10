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

	self.m_webBrowser = self:InitializeBrowser(self, self:GetWidth(), self:GetHeight())
	if util.is_valid(self.m_webBrowser) then
		self.m_webBrowser:SetAnchor(0, 0, 1, 1)
		self.m_webBrowser:AddCallback("SetSize", function()
			-- We don't want to reload the texture constantly if the element is being resized by a user,
			-- so we'll only update after the element hasn't been resized for at least 0.25 seconds
			self.m_tNextBrowserResize = time.real_time() + 0.25
			self:SetThinkingEnabled(true)
		end)
	end
end
function Element:ReloadURL()
	if util.is_valid(self.m_webBrowser) == false then
		return
	end
	local url = self.m_lastUrl or self.m_webBrowser:GetUrl()
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
	self.m_lastUrl = url
	self.m_webBrowser:LoadUrl(url)
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
	el:AddCallback("OnDownloadUpdate", function(el, id, state, percentage)
		if self.m_downloads[id] == nil then
			return
		end
		local path = self.m_downloads[id]
		self:CallCallbacks("OnDownloadUpdate", id, state, percentage, path)

		if
			state == chromium.DOWNLOAD_STATE_CANCELLED
			or state == chromium.DOWNLOAD_STATE_COMPLETE
			or state == chromium.DOWNLOAD_STATE_INVALIDATED
		then
			self.m_downloads[id] = nil
		end
	end)
	el:AddCallback("OnDownloadStarted", function(el, id, path)
		self.m_downloads[id] = path
		self:CallCallbacks("OnDownloadStarted", id, path)
	end)
	return el
end

function Element:ImportDownloadAssets(path)
	util.import_assets(path:GetString(), {
		onComplete = function(importedAssets)
			self:CallCallbacks("OnDownloadAssetsImported", importedAssets)
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

-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/info_box.lua")
include("/gui/pfm/web_browser.lua")
include("/util/util_asset_import.lua")

console.register_variable(
	"pfm_web_browser_enable_mature_content",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, no message prompt will be shown when visiting bookmarks with adult content."
)

console.register_variable(
	"pfm_experimental_use_servo_browser_engine",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If enabled, servo will be used instead of chromium for the underlying browser engine to use for web-browser windows. Note that servo is currently experimental."
)

local Element = util.register_class("gui.AssetWebBrowser", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(512, 512)
	self:ScheduleUpdate()
end
function Element:InitializeBrowser()
	if(self.m_browserInitialized) then return end
	self.m_browserInitialized = true

	local browser = gui.create("pfm_web_browser", self)
	browser:SetAlignment(gui.ALIGNMENT_FILL)
	
	local useServo = console.get_convar_bool("pfm_experimental_use_servo_browser_engine")
	local engine = useServo and "servo" or "chromium"
	self:LogInfo("Using browser engine '{}'...", engine)
	if(engine == "chromium") then browser:SetBrowserEngine(gui.PFMWebBrowser.BROWSER_ENGINE_CHROMIUM)
	else browser:SetBrowserEngine(gui.PFMWebBrowser.BROWSER_ENGINE_SERVO) end

	browser:AddCallback("OnDownloadUpdate", function(browser, id, state, percentage, path)
		self:CallCallbacks("OnDownloadUpdate", id, state, percentage, path)
	end)
	browser:AddCallback("OnDownloadStarted", function(browser, id, path)
		self:CallCallbacks("OnDownloadStarted",id, path)
	end)
	
	self.m_browser = browser
end
function Element:OnUpdate()
	-- The browser is expensive, so we'll delay the initialization until needed
	self:InitializeBrowser()
end
function Element:ReloadURL()
	if util.is_valid(self.m_browser) == false then
		return
	end
	local url = self.m_lastUrl or self.m_browser:GetUrl()
	self.m_browser:SetUrl(url)
end
function Element:GetUrl()
	if util.is_valid(self.m_browser) == false then
		return ""
	end
	return self.m_browser:GetUrl()
end
function Element:SetUrl(url)
	if util.is_valid(self.m_browser) == false then
		self.m_initialUrl = url
		return
	end
	self.m_lastUrl = url
	self.m_browser:SetUrl(url)
end
function Element:OnFocusGained()
	if util.is_valid(self.m_browser) then
		self.m_browser:RequestFocus()
	end
end
function Element:GetWebBrowser()
	return self.m_browser
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
	scrollContainer:SetAlignment(gui.ALIGNMENT_FILL)

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
gui.register("asset_web_browser", Element)

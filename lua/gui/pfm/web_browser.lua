-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.PFMWebBrowser", gui.Base)
Element.BROWSER_ENGINE_CHROMIUM = 0
Element.BROWSER_ENGINE_SERVO = 1
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(64, 128)
	self:SetBrowserEngine(Element.BROWSER_ENGINE_CHROMIUM)
	self:ScheduleUpdate()
	
	self.m_downloads = {}
end
function Element:SetBrowserEngine(browserEngine)
	self.m_browserEngine = browserEngine
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
	self.m_browser:LoadUrl(url)
end
function Element:InitializeBrowserElement(className)
	local w = self:GetWidth()
	local h = self:GetHeight()
	local browser = gui.create(className, self)
	if(browser == nil) then
		self:LogErr("Failed to create browser GUI element of type {}.", className)
		return
	end
	browser:SetName("browser")
	browser:SetBrowserViewSize(Vector2i(w, h))
	browser:SetAlignment(gui.ALIGNMENT_FILL)
	browser:SetInitialUrl("https://wiki.pragma-engine.com/books/pragma-filmmaker")

	if(self.m_initialUrl ~= nil) then
		browser:SetInitialUrl(self.m_initialUrl)
		self.m_initialUrl = nil
	end

	browser:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			el:RequestFocus()
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	browser:AddCallback("OnSizeChanged", function()
		-- We don't want to reload the texture constantly if the element is being resized by a user,
		-- so we'll only update after the element hasn't been resized for at least 0.25 seconds
		self.m_tNextBrowserResize = time.real_time() + 0.25
		self:SetThinkingEnabled(true)
	end)
	browser:ScheduleUpdate()
	self.m_browser = browser
	return browser
end
function Element:InitializeBrowser()
	if(self.m_browserInitialized) then return end
	self.m_browserInitialized = true

	if(self.m_browserEngine == Element.BROWSER_ENGINE_CHROMIUM) then
		local r = engine.load_library("chromium/pr_chromium")
		if r ~= true then
			self:LogErr(string.fmt("Failed to initialize chromium module: {}", r))
			return
		end

		local browser = self:InitializeBrowserElement("WIWeb")
		if browser then
			browser:AddCallback("OnDownloadUpdate", function(el, id, state, percentage)
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
			browser:AddCallback("OnDownloadStarted", function(el, id, path)
				self.m_downloads[id] = path
				self:CallCallbacks("OnDownloadStarted", id, path)
			end)
		end
	elseif(self.m_browserEngine == Element.BROWSER_ENGINE_SERVO) then
		local r = engine.load_library("servo/pr_servo")
		if r ~= true then
			self:LogErr(string.fmt("Failed to initialize servo module: {}", r))
			return
		end

		self:InitializeBrowserElement("servo_browser")
	else self:LogErr(string.fmt("Invalid browser engine '{}'", tostring(self.m_browserEngine))) end
end
function Element:OnUpdate()
	self:InitializeBrowser()
end
function Element:OnThink()
	if self.m_tNextBrowserResize then
		if time.real_time() < self.m_tNextBrowserResize then
			return
		end
		self.m_tNextBrowserResize = nil

		if(util.is_valid(self.m_browser)) then
			local w = self.m_browser:GetWidth()
			local h = self.m_browser:GetHeight()

			-- TODO: (Chromium) For some reason if the width is not divisible by 8, the image will be skewed (some kind of stride alignment?)
			if (w % 8) > 0 then
				w = w - (w % 8)
			end
			self.m_browser:SetBrowserViewSize(Vector2i(w, h))
			self.m_browser:Update()
		end
	end

	if self.m_tNextBrowserResize == nil then
		self:SetThinkingEnabled(false)
	end
end
gui.register("pfm_web_browser", Element)

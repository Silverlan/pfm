-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/vbox.lua")

local Element = util.register_class("gui.CodeEditor", gui.Base)

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
		self.m_webBrowser:AddCallback("SetSize", function()
			-- We don't want to reload the texture constantly if the element is being resized by a user,
			-- so we'll only update after the element hasn't been resized for at least 0.25 seconds
			self.m_tNextBrowserResize = time.real_time() + 0.25
			self:SetThinkingEnabled(true)
		end)
		self.m_webBrowser:SetSize(self:GetWidth(), self:GetHeight())
		self.m_webBrowser:SetAnchor(0, 0, 1, 1)
	end

	local pm = tool.get_filmmaker()
	if pm:ShouldDisplayNotification("initial_code_editor_message", true) then
		pfm.open_message_prompt(
			locale.get_text("pfm_code_editor"),
			locale.get_text("pfm_initial_code_editor_message"),
			gui.PfmPrompt.BUTTON_OK,
			function(bt) end
		)
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
	el:SetBrowserViewSize(Vector2i(w, h))
	el:SetSize(w, h)
	el:SetInitialUrl("https://vscode.dev")

	self.m_downloads = {}
	el:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			el:RequestFocus()
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	el:AddCallback("OnLoadingStateChange", function(el, isLoading, canGoBack, canGoForward)
		if isLoading == true then
			return
		end
		-- TODO: Set up environment
	end)
	return el
end
gui.register("WIPFMCodeEditor", Element)

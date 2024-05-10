--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wipfmassetwebbrowser.lua")

local Element = util.register_class("gui.PFMWebBrowser", gui.Base)

function Element:OnFocusGained()
	if util.is_valid(self.m_browser) then
		self.m_browser:RequestFocus()
	end
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)

	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(54, 54, 54))

	self.m_contents = gui.create("WIVBox", self.m_bg, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents:SetFixedSize(true)

	local infoBox = gui.create_info_box(
		self.m_contents,
		locale.get_text("pfm_web_browser_info", { "{[l:model_catalog]}", "{[/l]}" })
	)
	infoBox:GetTextElement():AddCallback("HandleLinkTagAction", function(el, arg)
		local pm = pfm.get_project_manager()
		if util.is_valid(pm) then
			pm:OpenWindow("model_catalog")
			pm:GoToWindow("model_catalog")
		end
		return util.EVENT_REPLY_HANDLED
	end)

	self.m_browser = gui.create("WIPFMAssetWebBrowser", self.m_contents)
	infoBox:SizeToContents()
	self.m_infoBox = infoBox

	self.m_contents:Update()
	self.m_contents:SetAutoFillContents(true)

	self:SetThinkingEnabled(true)
	self.m_firstTimeInit = false
end
function Element:GetBrowser()
	return self.m_browser
end
function Element:OnThink()
	if self.m_firstTimeInit == false then
		self.m_firstTimeInit = true
		-- TODO: This is a work-around for a bug where the web-browser would not load the URL initially, and the info box would take up
		-- too much space on the GUI, hiding the browser.
		self.m_infoBox:SizeToContents()
		time.create_simple_timer(1.0, function()
			if self:IsValid() == false then
				return
			end
			self:GetBrowser():ReloadURL()
		end)
	end
end
gui.register("WIPFMWebBrowser", Element)

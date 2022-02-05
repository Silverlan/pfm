--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/wiassetwebbrowser.lua")

local Element = util.register_class("gui.PFMWebBrowser",gui.Base)

function Element:__init()
	gui.Base.__init(self)
end
function Element:OnFocusGained()
	if(util.is_valid(self.m_browser)) then self.m_browser:RequestFocus() end
end
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIVBox",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	local infoBox = gui.create_info_box(self.m_contents,locale.get_text("pfm_web_browser_info",{"{[l:model_catalog]}","{[/l]}"}))
	infoBox:GetTextElement():AddCallback("HandleLinkTagAction",function(el,arg)
		local pm = pfm.get_project_manager()
		if(util.is_valid(pm)) then
			pm:OpenWindow("model_catalog")
			pm:GoToWindow("model_catalog")
		end
		return util.EVENT_REPLY_HANDLED
	end)

	self.m_browser = gui.create("WIAssetWebBrowser",self.m_contents)
	self.m_contents:Update()
end
function Element:GetBrowser() return self.m_browser end
gui.register("WIPFMWebBrowser",Element)

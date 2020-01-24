--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/hbox.lua")
include("/pfm/fonts.lua")
include("/gui/marquee.lua")

util.register_class("gui.PFMInfobar",gui.Base)

function gui.PFMInfobar:__init()
	gui.Base.__init(self)
end
function gui.PFMInfobar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,24)

	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:SetColor(Color(38,38,38))

	local patronTickerContainer = gui.create("WIHBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	patronTickerContainer:SetAutoFillContents(true)

	gui.create("WIBase",patronTickerContainer,0,0,10,1) -- Gap

	local patronTickerLabel = gui.create("WIText",patronTickerContainer)
	patronTickerLabel:SetText(locale.get_text("pfm_patrons") .. ":")
	patronTickerLabel:SizeToContents()
	patronTickerLabel:CenterToParentY()
	patronTickerLabel:AddStyleClass("input_field_text")

	local patronTicker = gui.create("WITicker",patronTickerContainer)
	local text = ""
	local patrons = engine.get_info().patrons
	for i,patron in ipairs(patrons) do
		if(i > 1) then text = text .. ", "
		else text = text .. " " end
		text = text .. patron
	end
	local numAnonymous = engine.get_info().totalPatronCount -#patrons
	if(numAnonymous > 0) then text = text .. " and " .. numAnonymous .. " anonymous." end
	patronTicker:SetText(text)
	patronTicker:SetSize(64,self:GetHeight())
	patronTicker:SetAnchor(0,0,1,1)

	self.m_iconContainer = gui.create("WIHBox",self)

	local engineInfo = engine.get_info()
	self:AddIcon("wgui/patreon_logo",engineInfo.patreonURL,"Patreon")
	self:AddIcon("third_party/twitter_logo",engineInfo.twitterURL,"Twitter")
	self:AddIcon("third_party/reddit_logo",engineInfo.redditURL,"Reddit")
	self:AddIcon("third_party/discord_logo",engineInfo.discordURL,"Discord")
	self.m_iconContainer:Update()
	self.m_iconContainer:SetX(self:GetWidth() -self.m_iconContainer:GetWidth())
	self.m_iconContainer:SetAnchor(1,0,1,0)
end
function gui.PFMInfobar:AddIcon(material,url,tooltip)
	local icon = gui.create("WITexturedRect",self.m_iconContainer)
	icon:SetSize(self:GetHeight(),self:GetHeight())
	icon:SetMaterial(material)
	icon:SetMouseInputEnabled(true)
	icon:SetTooltip(tooltip)
	icon:SetCursor(gui.CURSOR_SHAPE_HAND)
	icon:AddCallback("OnMouseEvent",function(icon,button,state,mods)
		if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS) then
			util.open_url_in_browser(url)
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)

	gui.create("WIBase",self.m_iconContainer,0,0,5,1) -- Gap
end
gui.register("WIPFMInfobar",gui.PFMInfobar)

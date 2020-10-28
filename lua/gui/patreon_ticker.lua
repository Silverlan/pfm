--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("hbox.lua")

util.register_class("gui.PatreonTicker",gui.HBox)
function gui.PatreonTicker:__init()
	gui.HBox.__init(self)
end
function gui.PatreonTicker:OnInitialize()
	gui.HBox.OnInitialize(self)

	self:SetAutoFillContents(true)

	gui.create("WIBase",self,0,0,10,1) -- Gap

	local patronTickerLabel = gui.create("WIText",self)
	patronTickerLabel:SetText(locale.get_text("pfm_patrons") .. ":")
	patronTickerLabel:SizeToContents()
	patronTickerLabel:AddStyleClass("input_field_text")
	self.m_patronTickerLabel = patronTickerLabel

	local patronTicker = gui.create("WITicker",self,patronTickerLabel:GetWidth(),0,self:GetWidth() -patronTickerLabel:GetWidth(),self:GetHeight())
	patronTicker:SetAnchor(0,0,1,1)
	self.m_patronTicker = patronTicker

	local r = engine.load_library("curl/pr_curl")
	if(r ~= true) then
		print("WARNING: An error occured trying to load the 'pr_curl' module: ",r)
		return
	end
	self.m_patronRequest = curl.request("http://pragma-engine.com/patreon/request_patrons.php",{})
	self.m_patronRequest:Start()
	self:EnableThinking()
end
function gui.PatreonTicker:OnRemove()
	if(self.m_patronRequest ~= nil) then self.m_patronRequest:Cancel() end
end
function gui.PatreonTicker:OnUpdate()
	self.m_patronTickerLabel:CenterToParentY()
end
function gui.PatreonTicker:OnThink()
	if(self.m_patronRequest == nil or self.m_patronRequest:IsComplete() == false) then return end
	if(self.m_patronRequest:IsSuccessful()) then
		local patrons = string.split(self.m_patronRequest:GetResult(),";")
		local text = ""
		for i,patron in ipairs(patrons) do
			if(i > 1) then text = text .. ", "
			else text = text .. " " end
			text = text .. patron
		end
		patrons = table.randomize(patrons)
--[[ -- TODO
	local numAnonymous = engine.get_info().totalPatronCount -#patrons
	if(numAnonymous > 0) then text = text .. " and " .. numAnonymous .. " anonymous." end
]]
		self.m_patronTicker:SetText(text)
	end
	self.m_patronRequest = nil
	self:DisableThinking()
end
gui.register("PatreonTicker",gui.PatreonTicker)

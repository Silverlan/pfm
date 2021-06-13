--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("hbox.lua")

locale.load("pfm_misc.txt")

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
	patronTickerLabel:SetY(5)
	self.m_patronTickerLabel = patronTickerLabel

	local patronTicker = gui.create("WITicker",self,patronTickerLabel:GetWidth(),0,self:GetWidth() -patronTickerLabel:GetWidth(),self:GetHeight())
	patronTicker:SetAnchor(0,0,1,1)
	self.m_patronTicker = patronTicker

	self.m_curlRequests = {}

	local r = engine.load_library("curl/pr_curl")
	if(r ~= true) then
		print("WARNING: An error occured trying to load the 'pr_curl' module: ",r)
		return
	end
end
local function table_to_url_parameters(t)
	local params = ""
	local first = true
	for k,v in pairs(t) do
		if(first) then
			params = params .. "?"
			first = false
		else params = params .. "&" end
		params = params .. k .. "=" .. v
	end
	return params
end
function gui.PatreonTicker:SetQueryUrl(uri,args)
	args = args or {}
	for _,req in pairs(self.m_curlRequests) do req:Cancel() end
	self.m_curlRequests = {}

	self.m_queryUri = uri
	self:AddCurlRequest("supporters",uri .. table_to_url_parameters(args))
	args["query"] = "get_total_supporter_count"
	self:AddCurlRequest("supporter_count",uri .. table_to_url_parameters(args))
	self:EnableThinking()
end
function gui.PatreonTicker:AddCurlRequest(id,uri)
	local req = curl.request(uri,{})
	req:Start()
	self.m_curlRequests[id] = req
end
function gui.PatreonTicker:OnRemove()
	for _,req in pairs(self.m_curlRequests) do
		req:Cancel()
	end
end
function gui.PatreonTicker:OnUpdate()
	self.m_patronTickerLabel:CenterToParentY()
end
function gui.PatreonTicker:OnThink()
	for _,req in pairs(self.m_curlRequests) do
		if(req:IsComplete() == false) then return end
	end
	local query = self.m_curlRequests["supporters"]
	local queryCount = self.m_curlRequests["supporter_count"]
	if(query ~= nil and query:IsSuccessful()) then
		local patrons = string.split(query:GetResult(),";")
		local text = ""
		for i,patron in ipairs(patrons) do
			if(i > 1) then text = text .. ", "
			else text = text .. " " end
			text = text .. patron
		end
		patrons = table.randomize(patrons)
		local numPatrons = #patrons

		if(queryCount ~= nil and queryCount:IsSuccessful()) then
			local count = toint(queryCount:GetResult())
			count = math.max(count -numPatrons,0)
			if(count > 0) then
				local numAnonymous = count
				if(numAnonymous > 0) then text = text .. " and " .. numAnonymous .. " anonymous." end
			end
		end
		self.m_patronTicker:SetText(text)
	end
	self.m_curlRequests = {}
	self:DisableThinking()
end
gui.register("PatreonTicker",gui.PatreonTicker)

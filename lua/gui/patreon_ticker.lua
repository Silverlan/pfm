--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("hbox.lua")
include("/modules/json.lua")

locale.load("pfm_misc.txt")

console.register_variable(
	"pfm_supporter_ticker_show_all",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"If disabled, only active supporters will be shown in the ticker."
)

local Element = util.register_class("gui.SupporterTicker", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256, 64)

	self.m_marquee = gui.create("WIMarquee", self)
	self.m_marquee:SetMoveSpeed(20)
end
function Element:Clear()
	self.m_marquee:Clear()
end
function Element:AddSupporter(name, color, priority)
	local elText = gui.create("WIText")
	elText:SetText(name .. ", ")
	elText:AddStyleClass("input_field_text")
	elText:SizeToContents()
	if color ~= nil then
		time.create_simple_timer(0.0, function()
			if elText:IsValid() then
				elText:SetColor(color)
			end
		end)
	end
	self.m_marquee:AddElement(elText)
end
function Element:OnSizeChanged(w, h)
	if util.is_valid(self.m_marquee) then
		self.m_marquee:SetWidth(w)
	end
end
function Element:OnUpdate()
	self.m_marquee:Update()
end
gui.register("WISupporterTicker", Element)

-----------------

util.register_class("gui.PatreonTicker", gui.HBox)
function gui.PatreonTicker:OnInitialize()
	gui.HBox.OnInitialize(self)

	self:SetAutoFillContents(true)

	gui.create("WIBase", self, 0, 0, 10, 1) -- Gap

	local patronTickerLabel = gui.create("WIText", self)
	patronTickerLabel:SetText(locale.get_text("pfm_patrons") .. ":")
	patronTickerLabel:SizeToContents()
	patronTickerLabel:AddStyleClass("input_field_text")
	patronTickerLabel:SetY(5)
	patronTickerLabel:SetX(5)
	self.m_patronTickerLabel = patronTickerLabel

	local icon = gui.create("WITexturedRect", self)
	icon:SetSize(14, 14)
	icon:SetMaterial("gui/pfm/icon_item_visible_off")
	icon:SetMouseInputEnabled(true)
	icon:SetCursor(gui.CURSOR_SHAPE_HAND)
	icon:SetMouseInputEnabled(true)
	icon:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				console.run(
					"pfm_supporter_ticker_show_all",
					console.get_convar_bool("pfm_supporter_ticker_show_all") and "0" or "1"
				)
			end
			return util.EVENT_REPLY_HANDLED
		end
	end)
	self.m_icon = icon

	local patronTicker = gui.create(
		"WISupporterTicker",
		self,
		patronTickerLabel:GetWidth(),
		5,
		self:GetWidth() - patronTickerLabel:GetWidth(),
		self:GetHeight()
	)
	patronTicker:SetAnchor(0, 0, 1, 1)
	self.m_patronTicker = patronTicker

	self.m_curlRequests = {}

	self.m_cbShowAll = console.add_change_callback("pfm_supporter_ticker_show_all", function(old, new)
		self:SetShowInactiveSupporters(new)
	end)

	self:SetShowInactiveSupporters(console.get_convar_bool("pfm_supporter_ticker_show_all"))

	pfm.util.init_curl()
end
local function table_to_url_parameters(t)
	local params = ""
	local first = true
	for k, v in pairs(t) do
		if first then
			params = params .. "?"
			first = false
		else
			params = params .. "&"
		end
		params = params .. k .. "=" .. v
	end
	return params
end
function gui.PatreonTicker:SetShowInactiveSupporters(shouldShow)
	if shouldShow == self.m_shouldShowInactiveSupporters then
		return
	end
	self.m_shouldShowInactiveSupporters = shouldShow
	local sf = shouldShow and "on" or "off"
	self.m_icon:SetMaterial("gui/pfm/icon_item_visible_" .. sf)
	self.m_icon:SetTooltip(locale.get_text("pfm_supporter_ticker_show_" .. (shouldShow and "active" or "inactive")))
	self:UpdateSupporterList()
end
function gui.PatreonTicker:ShouldShowInactiveSupporters()
	return self.m_shouldShowInactiveSupporters or false
end
function gui.PatreonTicker:SetQueryUrl(uri, args)
	args = args or {}
	args["version"] = "3"
	for _, req in pairs(self.m_curlRequests) do
		req:Cancel()
	end
	self.m_curlRequests = {}

	self.m_queryUri = uri
	self:AddCurlRequest("supporters", uri .. table_to_url_parameters(args))
	--args["query"] = "get_total_supporter_count"
	--self:AddCurlRequest("supporter_count", uri .. table_to_url_parameters(args))
	self:EnableThinking()
end
function gui.PatreonTicker:AddCurlRequest(id, uri)
	local requestData = curl.RequestData()
	local req = curl.request(uri, requestData)
	req:Start()
	self.m_curlRequests[id] = req
end
function gui.PatreonTicker:OnRemove()
	util.remove(self.m_cbShowAll)
	for _, req in pairs(self.m_curlRequests) do
		req:Cancel()
	end
end
function gui.PatreonTicker:OnUpdate()
	self.m_patronTickerLabel:CenterToParentY()
end
function gui.PatreonTicker:UpdateTicker()
	for _, el in ipairs(self.m_patronTicker.m_marquee:GetElements()) do
		if el:IsValid() then
			el:SizeToContents()
		end
	end
	self.m_patronTicker.m_marquee:Rearrange()
	self.m_patronTicker.m_marquee:Reset()
	self.m_patronTicker:Update()

	self.m_patronTickerLabel:SizeToContents()
	self.m_icon:SetX(self.m_patronTickerLabel:GetRight() + 6)
	self.m_icon:CenterToParentY()
	local offset = 10
	self.m_patronTicker:SetX(self.m_icon:GetRight() + offset)
	self.m_patronTicker:SetWidth(self:GetWidth() - self.m_patronTicker:GetX())

	self.m_patronTicker:SetAnchor(0, 0, 1, 1)
end
function gui.PatreonTicker:OnSizeChanged(w, h)
	self:UpdateTicker()
end
function gui.PatreonTicker:UpdateSupporterList()
	self.m_patronTicker:Clear()
	if self.m_supporterList == nil or #self.m_supporterList == 0 then
		return
	end
	local filtered = {}
	local showInactive = self:ShouldShowInactiveSupporters()
	for _, patron in ipairs(self.m_supporterList) do
		if patron.active or showInactive then
			table.insert(filtered, patron)
		end
	end
	filtered = table.randomize(filtered)
	local n = #filtered
	if n > 0 then
		local i = 1
		while n < 50 do
			table.insert(filtered, filtered[i])
			i = i + 1
			n = #filtered
		end
	end
	local text = ""
	local color = Color(220, 220, 220)
	local colorSpecial = Color.Orange
	for i, patronInfo in ipairs(filtered) do
		--[[if patronInfo[2] ~= nil then
			color = Color.CreateFromHexColor(patronInfo[2]:sub(2))
		end]]
		if patronInfo.name ~= nil then
			local supporterColor = color
			local flags = patronInfo.flags or 0
			if patronInfo.color ~= nil then
				supporterColor = Color.CreateFromHexColor(patronInfo.color:sub(2))
				supporterColor.a = 255
			elseif bit.band(flags, 1) ~= 0 then
				supporterColor = colorSpecial
			end
			self.m_patronTicker:AddSupporter(patronInfo.name, supporterColor)
		end
	end

	self.m_patronTicker:Update()
	time.create_simple_timer(0.05, function()
		if self:IsValid() then
			self:UpdateTicker()
		end
	end)
end
function gui.PatreonTicker:OnThink()
	for _, req in pairs(self.m_curlRequests) do
		if req:IsComplete() == false then
			return
		end
	end
	local query = self.m_curlRequests["supporters"]
	if query ~= nil and query:IsSuccessful() then
		local success, patrons = pcall(json.parse, query:GetResult():ReadString())
		if success == false then
			patrons = {}
		end
		self.m_supporterList = patrons
		self:UpdateSupporterList()
	end
	self.m_curlRequests = {}
	self:DisableThinking()
end
gui.register("PatreonTicker", gui.PatreonTicker)

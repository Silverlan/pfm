--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("baseclip.lua")

util.register_class("gui.FilmClip",gui.BaseClip)

function gui.FilmClip:__init()
	gui.BaseClip.__init(self)
end
function gui.FilmClip:OnInitialize()
	gui.BaseClip.OnInitialize(self)

	self:SetHeight(64)
	local w = self:GetWidth()
	local h = self:GetHeight()

	self.m_textDetails = gui.create("WIText",self,4,h -14,w -8,14,0,1,1,1)
	self.m_textDetails:SetFont("pfm_small")
	self.m_textDetails:SetColor(Color(202,202,222))

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed",function()
		self:SetSelected(true)
	end)

	self:AddStyleClass("timeline_clip_film")
end
function gui.FilmClip:SetFilmClipData(filmClip)
	self.m_filmClip = filmClip
	self:SetText(filmClip:GetName())

	local timeFrame = filmClip:GetTimeFrame()
	local offset = timeFrame:GetOffset()
	local duration = timeFrame:GetDuration()
	offset = util.get_pretty_time(offset)
	duration = util.get_pretty_time(duration)
	if(self.m_textDetails:IsValid()) then self.m_textDetails:SetText("scale " .. util.round_string(timeFrame:GetScale(),2) .. " offset " .. offset .. " duration " .. duration) end

	local t = "\t\t"
	self:SetTooltip(
		locale.get_text("pfm_film_clip") .. ":\n" .. filmClip:GetName() .. "\n" .. 
		locale.get_text("start") .. ":" .. t .. util.get_pretty_time(timeFrame:GetStart()) .. "\n" .. 
		locale.get_text("end") .. ":" .. t .. util.get_pretty_time(timeFrame:GetEnd()) .. "\n" .. 
		locale.get_text("duration") .. ":" .. util.get_pretty_time(timeFrame:GetDuration()) .. "\n" .. 
		locale.get_text("offset") .. ":" .. t .. util.get_pretty_time(timeFrame:GetOffset()) .. "\n" .. 
		locale.get_text("scale") .. ":" .. t .. timeFrame:GetScale()
	)
end
function gui.FilmClip:GetFilmClipData() return self.m_filmClip end
function gui.FilmClip:GetTimeFrame() return self.m_filmClip:GetTimeFrame() end
gui.register("WIFilmClip",gui.FilmClip)

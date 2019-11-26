--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("selectionoutline.lua")

util.register_class("gui.FilmClip",gui.Base)

gui.FilmClip.BACKGROUND_COLOR = Color(47,47,121)
gui.FilmClip.BACKGROUND_COLOR_SELECTED = Color(58,56,115)
gui.FilmClip.OUTLINE_COLOR = Color(182,182,182)

gui.FilmClip.TITLE_COLOR = Color.White
gui.FilmClip.TITLE_COLOR_SELECTED = Color(63,53,20)

function gui.FilmClip:__init()
	gui.Base.__init(self)
end
function gui.FilmClip:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 64
	self:SetSize(w,h)

	self.m_bg = gui.create("WIRect",self,0,0,w,h,0,0,1,1)
	self.m_bg:SetColor(gui.FilmClip.BACKGROUND_COLOR)

	self.m_bgOutline = gui.create("WIOutlinedRect",self,0,0,w,h,0,0,1,1)
	self.m_bgOutline:SetColor(gui.FilmClip.OUTLINE_COLOR)

	self.m_selection = gui.create("WISelectionOutline",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_selection:SetVisible(false)

	self.m_text = gui.create("WIText",self,4,0,w -8,14,0,0,1,0)
	self.m_text:SetFont("pfm_small")
	self.m_text:SetColor(gui.FilmClip.TITLE_COLOR)

	self.m_textDetails = gui.create("WIText",self,4,h -14,w -8,14,0,1,1,1)
	self.m_textDetails:SetFont("pfm_small")
	self.m_textDetails:SetColor(Color(202,202,222))

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed",function()
		self:SetSelected(true)
	end)
end
function gui.FilmClip:SetFilmClipData(filmClip)
	self.m_filmClip = filmClip
	if(self.m_text:IsValid()) then self.m_text:SetText(filmClip:GetName()) end

	local timeFrame = filmClip:GetTimeFrame()
	local offset = timeFrame:GetOffset()
	local duration = timeFrame:GetDuration()
	offset = util.get_pretty_time(offset)
	duration = util.get_pretty_time(duration)
	if(self.m_textDetails:IsValid()) then self.m_textDetails:SetText("scale " .. util.round_string(timeFrame:GetScale(),2) .. " offset " .. offset .. " duration " .. duration) end

	local t = "\t\t"
	self:SetTooltip("Film Clip:\n" .. filmClip:GetName() .. "\nStart:" .. t .. util.get_pretty_time(timeFrame:GetStart()) .. "\nEnd:" .. t .. util.get_pretty_time(timeFrame:GetEnd()) .. "\nDuration:" .. util.get_pretty_time(timeFrame:GetDuration()) .. "\nOffset:" .. t .. util.get_pretty_time(timeFrame:GetOffset()) .. "\nScale:" .. t .. timeFrame:GetScale())
end
function gui.FilmClip:GetFilmClipData() return self.m_filmClip end
function gui.FilmClip:GetTimeFrame() return self.m_filmClip:GetTimeFrame() end
function gui.FilmClip:SetSelected(selected)
	self.m_selection:SetVisible(selected)
	if(self.m_text:IsValid()) then
		self.m_text:SetColor(selected and gui.FilmClip.TITLE_COLOR_SELECTED or gui.FilmClip.TITLE_COLOR)
	end
	if(selected) then self:CallCallbacks("OnSelected")
	else self:CallCallbacks("OnDeselected") end
end
gui.register("WIFilmClip",gui.FilmClip)

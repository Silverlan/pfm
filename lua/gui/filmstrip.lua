--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("filmclip.lua")

util.register_class("gui.FilmStrip",gui.Base)

function gui.FilmStrip:__init()
	gui.Base.__init(self)
end
function gui.FilmStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_timeFrame = fudm.PFMTimeFrame()
	self.m_container = gui.create("WIContainer",self)
	self:GetSizeProperty():Link(self.m_container:GetSizeProperty())
	self.m_filmClips = {}
end
function gui.FilmStrip:GetTimeFrame() return self.m_timeFrame end
function gui.FilmStrip:GetFilmClips() return self.m_filmClips end
function gui.FilmStrip:OnUpdate()
	local timeFrame
	-- Calculate total time frame
	for _,el in ipairs(self.m_filmClips) do
		if(el:IsValid()) then
			local filmClipData = el:GetFilmClipData()
			local timeFrameClip = filmClipData:GetTimeFrame()
			if(timeFrame == nil) then timeFrame = timeFrameClip:Copy()
			else timeFrame = timeFrame:Max(timeFrameClip) end
		end
	end
	self.m_timeFrame = timeFrame or fudm.PFMTimeFrame()
end
gui.register("WIFilmStrip",gui.FilmStrip)

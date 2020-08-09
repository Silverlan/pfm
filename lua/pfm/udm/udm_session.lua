--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_film_clip.lua")
include("udm_settings.lua")

udm.ELEMENT_TYPE_PFM_SESSION = udm.register_element("PFMSession")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"activeClip",udm.PFMFilmClip())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"clips",udm.Array(udm.ELEMENT_TYPE_PFM_FILM_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_SESSION,"settings",udm.PFMSettings())

function udm.PFMSession:GetPlayheadFrameOffset() return self:GetSettings():GetPlayheadFrameOffset() end
function udm.PFMSession:GetPlayheadOffset() return self:GetSettings():GetPlayheadOffset() end
function udm.PFMSession:GetFrameRate() return self:GetSettings():GetFrameRate() end
function udm.PFMSession:TimeOffsetToFrameOffset(offset) return self:GetSettings():TimeOffsetToFrameOffset(offset) end
function udm.PFMSession:FrameOffsetToTimeOffset(offset) return self:GetSettings():FrameOffsetToTimeOffset(offset) end

function udm.PFMSession:GetFilmTrack()
	if(self.m_cachedFilmTrack ~= nil) then return self.m_cachedFilmTrack end
	local filmClip = self:GetActiveClip()
	if(filmClip == nil) then return end
	local trackGroup = filmClip:FindSubClipTrackGroup()
	self.m_cachedFilmTrack = (trackGroup ~= nil) and trackGroup:FindElementsByName("Film")[1] or nil
	return self.m_cachedFilmTrack
end

function udm.PFMSession:GetLastFrameIndex()
	local filmTrack = self:GetFilmTrack()
	local filmClipLast
	local tLast = -math.huge
	for _,filmClip in ipairs(filmTrack:GetFilmClips():GetTable()) do
		local timeFrame = filmClip:GetTimeFrame()
		if(timeFrame:GetEnd() > tLast) then
			filmClipLast = filmClip
			tLast = timeFrame:GetEnd()
		end
	end
	return self:TimeOffsetToFrameOffset(tLast)
end
function udm.PFMSession:GetFrameIndexRange()
	return 0,self:GetLastFrameIndex()
end

function udm.PFMSession:GetFilmClip(t)
	t = t or self:GetTimeOffset()
	local filmTrack = self:GetFilmTrack()
	for _,filmClip in ipairs(filmTrack:GetFilmClips():GetTable()) do
		local timeFrame = filmClip:GetTimeFrame()
		if(timeFrame:IsInTimeFrame(t)) then
			return filmClip
		end
	end
end

function udm.PFMSession:UpdateTimeFrame()
	local filmTrack = self:GetFilmTrack()
	local activeClip = self:GetActiveClip()
	if(filmTrack == nil or activeClip == nil) then return end
	local timeFrame = filmTrack:CalcTimeFrame()
	local clipTimeFrame = activeClip:GetTimeFrame()
	clipTimeFrame:SetStart(timeFrame:GetStart())
	clipTimeFrame:SetDuration(timeFrame:GetDuration())
end

function udm.PFMSession:AddFilmClip()
	local filmTrack = self:GetFilmTrack()
	if(filmTrack == nil) then return end
	local name = "shot"
	local filmClipNames = {}
	local endTime = 0.0
	for _,filmClip in ipairs(filmTrack:GetFilmClips():GetTable()) do
		filmClipNames[filmClip:GetName()] = true
		endTime = math.max(endTime,filmClip:GetTimeFrame():GetEnd())
	end
	local i = 1
	while(filmClipNames[name .. i] ~= nil) do i = i +1 end
	local filmClip = udm.create_element(udm.ELEMENT_TYPE_PFM_FILM_CLIP,name)
	filmClip:GetTimeFrame():SetDuration(10.0)
	filmClip:GetTimeFrame():SetStart(endTime)
	filmTrack:AddFilmClip(filmClip)
	self:UpdateTimeFrame()
	return filmClip
end

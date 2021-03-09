--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_film_clip.lua")
include("udm_settings.lua")

fudm.ELEMENT_TYPE_PFM_SESSION = fudm.register_element("PFMSession")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SESSION,"activeClip",fudm.PFMFilmClip())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SESSION,"clips",fudm.Array(fudm.ELEMENT_TYPE_PFM_FILM_CLIP))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_SESSION,"settings",fudm.PFMSettings())

function fudm.PFMSession:GetPlayheadFrameOffset() return self:GetSettings():GetPlayheadFrameOffset() end
function fudm.PFMSession:GetPlayheadOffset() return self:GetSettings():GetPlayheadOffset() end
function fudm.PFMSession:GetFrameRate() return self:GetSettings():GetFrameRate() end
function fudm.PFMSession:TimeOffsetToFrameOffset(offset) return self:GetSettings():TimeOffsetToFrameOffset(offset) end
function fudm.PFMSession:FrameOffsetToTimeOffset(offset) return self:GetSettings():FrameOffsetToTimeOffset(offset) end

function fudm.PFMSession:GetFilmTrack()
	if(self.m_cachedFilmTrack ~= nil) then return self.m_cachedFilmTrack end
	local filmClip = self:GetActiveClip()
	if(filmClip == nil) then return end
	local trackGroup = filmClip:FindSubClipTrackGroup()
	self.m_cachedFilmTrack = (trackGroup ~= nil) and trackGroup:FindElementsByName("Film")[1] or nil
	return self.m_cachedFilmTrack
end

function fudm.PFMSession:GetLastFrameIndex()
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
function fudm.PFMSession:GetFrameIndexRange()
	return 0,self:GetLastFrameIndex()
end

function fudm.PFMSession:GetFilmClip(t)
	t = t or self:GetTimeOffset()
	local filmTrack = self:GetFilmTrack()
	for _,filmClip in ipairs(filmTrack:GetFilmClips():GetTable()) do
		local timeFrame = filmClip:GetTimeFrame()
		if(timeFrame:IsInTimeFrame(t)) then
			return filmClip
		end
	end
end

function fudm.PFMSession:UpdateTimeFrame()
	local filmTrack = self:GetFilmTrack()
	local activeClip = self:GetActiveClip()
	if(filmTrack == nil or activeClip == nil) then return end
	local timeFrame = filmTrack:CalcTimeFrame()
	local clipTimeFrame = activeClip:GetTimeFrame()
	clipTimeFrame:SetStart(timeFrame:GetStart())
	clipTimeFrame:SetDuration(timeFrame:GetDuration())
end

function fudm.PFMSession:AddFilmClip()
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
	local filmClip = fudm.create_element(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,name)
	filmClip:GetTimeFrame():SetDuration(10.0)
	filmClip:GetTimeFrame():SetStart(endTime)
	filmTrack:AddFilmClip(filmClip)
	self:UpdateTimeFrame()
	return filmClip
end

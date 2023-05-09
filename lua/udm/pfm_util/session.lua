--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Session:GetFilmTrack()
	if self.m_cachedFilmTrack ~= nil then
		return self.m_cachedFilmTrack
	end
	local filmClip = self:GetActiveClip()
	if filmClip == nil then
		return
	end
	local trackGroup = filmClip:FindSubClipTrackGroup()
	if trackGroup == nil then
		return
	end
	for _, track in ipairs(trackGroup:GetTracks()) do
		if track:GetName() == "Film" then
			self.m_cachedFilmTrack = track
			return
		end
	end
end

function pfm.udm.Session:FindClipAtTimeOffset(t)
	t = t or self:GetTimeOffset()
	local filmTrack = self:GetFilmTrack()
	if filmTrack == nil then
		return
	end
	for _, filmClip in ipairs(filmTrack:GetFilmClips()) do
		local timeFrame = filmClip:GetTimeFrame()
		if timeFrame:IsInTimeFrame(t) then
			return filmClip
		end
	end
end

function pfm.udm.Session:GetPlayheadFrameOffset()
	return self:GetSettings():GetPlayheadFrameOffset()
end
function pfm.udm.Session:GetPlayheadOffset()
	return self:GetSettings():GetPlayheadOffset()
end
function pfm.udm.Session:GetFrameRate()
	return self:GetSettings():GetFrameRate()
end
function pfm.udm.Session:TimeOffsetToFrameOffset(offset)
	return self:GetSettings():TimeOffsetToFrameOffset(offset)
end
function pfm.udm.Session:FrameOffsetToTimeOffset(offset)
	return self:GetSettings():FrameOffsetToTimeOffset(offset)
end

function pfm.udm.Session:GetLastFrameIndex()
	local filmTrack = self:GetFilmTrack()
	local filmClipLast
	local tLast = -math.huge
	for _, filmClip in ipairs(filmTrack:GetFilmClips()) do
		local timeFrame = filmClip:GetTimeFrame()
		if timeFrame:GetEnd() > tLast then
			filmClipLast = filmClip
			tLast = timeFrame:GetEnd()
		end
	end
	return self:TimeOffsetToFrameOffset(tLast)
end
function pfm.udm.Session:GetFrameIndexRange()
	return 0, self:GetLastFrameIndex()
end

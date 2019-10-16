--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMTrack",BaseEntityComponent)

function ents.PFMTrack:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_offset = 0.0
	self.m_activeClips = {}
	self.m_timeFrame = udm.PFMTimeFrame()
end

function ents.PFMTrack:OnRemove()
	self:Stop()
end

function ents.PFMTrack:GetOffset() return self.m_offset end
function ents.PFMTrack:SetOffset(offset)
	self.m_offset = offset
	self:UpdateTrack()
end
function ents.PFMTrack:Advance(dt) self:SetOffset(self:GetOffset() +dt) end

function ents.PFMTrack:PlayAudio()
	for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then clipC:PlayAudio() end
	end
end

function ents.PFMTrack:PauseAudio()
	for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then clipC:PauseAudio() end
	end
end

function ents.PFMTrack:UpdateTrack()
	local offset = self:GetOffset()

	-- Update clips that are already playing
	local clipsActive = {}
	local i = 1
	while(i <= #self.m_activeClips) do
		local clipC = self.m_activeClips[i]
		local keepClip = true
		if(clipC:IsValid()) then
			local clip = clipC:GetClip()
			local timeFrame = clip:GetTimeFrame()
			if(offset < timeFrame:GetStart() or offset >= timeFrame:GetEnd()) then keepClip = false end
		else keepClip = false end
		
		if(keepClip == false) then
			clipC:Stop()
			clipC:GetEntity():RemoveSafely()
			table.remove(self.m_activeClips,i)
		else
			i = i +1
			clipsActive[clipC:GetClip()] = true
		end
	end

	-- Check if there are new clips that need to be started
	self:UpdateClips(self.m_track:GetAudioClips():GetValue(),offset,clipsActive)
	self:UpdateClips(self.m_track:GetFilmClips():GetValue(),offset,clipsActive)
	
	-- Update offsets for active clips
	for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then
			local clip = clipC:GetClip()
			local timeFrame = clip:GetTimeFrame()
			local clipOffset = offset -timeFrame:GetStart()
			clipC:SetOffset(clipOffset)
		end
	end
end

function ents.PFMTrack:GetTimeFrame()
	return self.m_timeFrame
end

function ents.PFMTrack:UpdateClips(clips,offset,clipsActive)
	for name,clip in pairs(clips) do
		local timeFrame = clip:GetTimeFrame()
		if(clipsActive[clip] == nil and offset >= timeFrame:GetStart() and offset < timeFrame:GetEnd()) then
			self:StartClip(clip)
		end
	end
end

function ents.PFMTrack:SetTrack(udmTrack)
	self:GetEntity():SetName(udmTrack:GetName())
	self.m_track = udmTrack

	local startTime = math.huge
	local endTime = -math.huge
	for _,filmClip in ipairs(udmTrack:GetFilmClips():GetValue()) do
		local timeFrame = filmClip:GetTimeFrame()
		local clipStart = timeFrame:GetStart()
		local clipEnd = timeFrame:GetEnd()
		startTime = math.min(startTime,clipStart)
		endTime = math.max(endTime,clipEnd)
	end
	for _,audioClip in ipairs(udmTrack:GetAudioClips():GetValue()) do
		local timeFrame = audioClip:GetTimeFrame()
		local clipStart = timeFrame:GetStart()
		local clipEnd = timeFrame:GetEnd()
		startTime = math.min(startTime,clipStart)
		endTime = math.max(endTime,clipEnd)
	end
	if(startTime == math.huge or endTime == -math.huge) then
		startTime = 0.0
		endTime = 0.0
	end

	self.m_timeFrame = udm.PFMTimeFrame()
	self.m_timeFrame:SetStart(startTime)
	self.m_timeFrame:SetDuration(endTime -startTime)
end
function ents.PFMTrack:GetTrack() return self.m_track end

function ents.PFMTrack:Stop()
	for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then
			clipC:Stop()
			clipC:GetEntity():RemoveSafely()
		end
	end
	self.m_activeClips = {}
end

function ents.PFMTrack:StartClip(clip)
	local entClip = ents.create("pfm_clip")
	local clipC = entClip:GetComponent(ents.COMPONENT_PFM_CLIP)
	table.insert(self.m_activeClips,clipC)
	clipC:SetClip(clip)
	entClip:Spawn()
	clipC:Start()
end
ents.COMPONENT_PFM_TRACK = ents.register_component("pfm_track",ents.PFMTrack)

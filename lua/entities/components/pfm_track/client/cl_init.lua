--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_channel_clip")
include_component("pfm_audio_clip")

util.register_class("ents.PFMTrack",BaseEntityComponent)

function ents.PFMTrack:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_timeFrame = fudm.PFMTimeFrame()

	self.m_activeClips = {}
	self.m_inactiveClips = {}
	self:SetKeepClipsAlive(true)
end

function ents.PFMTrack:OnRemove()
	self:Reset()
end

function ents.PFMTrack:GetTrackData() return self.m_trackData end
function ents.PFMTrack:GetTrackGroup() return self.m_trackGroup end
function ents.PFMTrack:GetProject() return self.m_project end

function ents.PFMTrack:Reset()
	for clipData,ent in pairs(self.m_activeClips) do if(ent:IsValid()) then ent:Remove() end end
	for clipData,ent in pairs(self.m_inactiveClips) do if(ent:IsValid()) then ent:Remove() end end
	self.m_activeClips = {}
	self.m_inactiveClips = {}
end

function ents.PFMTrack:Setup(trackData,trackGroup,projectC)
	self.m_trackData = trackData
	self.m_trackGroup = trackGroup
	self.m_project = projectC
	self:GetEntity():SetName(trackData:GetName())

	local startTime = math.huge
	local endTime = -math.huge
	for _,filmClip in ipairs(trackData:GetFilmClips():GetTable()) do
		local timeFrame = filmClip:GetTimeFrame()
		local clipStart = timeFrame:GetStart()
		local clipEnd = timeFrame:GetEnd()
		startTime = math.min(startTime,clipStart)
		endTime = math.max(endTime,clipEnd)
	end
	for _,audioClip in ipairs(trackData:GetAudioClips():GetTable()) do
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

	self.m_timeFrame = fudm.PFMTimeFrame()
	self.m_timeFrame:SetStart(startTime)
	self.m_timeFrame:SetDuration(endTime -startTime)
end

function ents.PFMTrack:SetKeepClipsAlive(keepAlive) self.m_keepClipsAlive = keepAlive end

function ents.PFMTrack:OnOffsetChanged(offset,gameViewFlags)
	-- Update film and channel clips
	for _,clipSet in ipairs({self:GetTrackData():GetFilmClips():GetTable(),self:GetTrackData():GetChannelClips():GetTable(),self:GetTrackData():GetAudioClips():GetTable()}) do
		for _,clip in ipairs(clipSet) do
			local timeFrame = clip:GetTimeFrame()
			if(timeFrame:IsInTimeFrame(offset)) then
				if(util.is_valid(self.m_activeClips[clip]) == false) then
					if(clip:GetType() == fudm.ELEMENT_TYPE_PFM_FILM_CLIP) then
						self.m_activeClips[clip] = self:CreateFilmClip(clip)
					elseif(clip:GetType() == fudm.ELEMENT_TYPE_PFM_CHANNEL_CLIP) then
						-- self.m_activeClips[clip] = self:CreateChannelClip(clip) -- Obsolete?
					elseif(clip:GetType() == fudm.ELEMENT_TYPE_PFM_AUDIO_CLIP) then
						self.m_activeClips[clip] = self:CreateAudioClip(clip)
					elseif(clip:GetType() == fudm.ELEMENT_TYPE_PFM_OVERLAY_CLIP) then
						self.m_activeClips[clip] = self:CreateOverlayClip(clip)
					else
						pfm.log("Unsupported clip type '" .. clip:GetTypeName() .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME)
					end
				end
			elseif(util.is_valid(self.m_activeClips[clip])) then
				-- New offset is out of the range of this film clip; Remove it
				local ent = self.m_activeClips[clip]
				if(self.m_keepClipsAlive) then
					self.m_inactiveClips[clip] = ent
					if(util.is_valid(ent)) then ent:TurnOff() end
				else ent:Remove() end
				self.m_activeClips[clip] = nil
			end
		end
	end
	for node,clip in pairs(self.m_activeClips) do
		if(clip:IsValid()) then
			local clipC = clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP) or clip:GetComponent(ents.COMPONENT_PFM_CHANNEL_CLIP) or clip:GetComponent(ents.COMPONENT_PFM_AUDIO_CLIP) or nil
			if(clipC ~= nil) then
				clipC:SetOffset(offset,gameViewFlags)
			end
		end
	end
end

function ents.PFMTrack:GetActiveClips() return self.m_activeClips end

function ents.PFMTrack:ReactivateClip(clipData)
	if(util.is_valid(self.m_inactiveClips[clipData]) == false) then return end
	local ent = self.m_inactiveClips[clipData]
	self.m_inactiveClips[clipData] = nil
	ent:TurnOn()
	return ent
end

function ents.PFMTrack:CreateFilmClip(filmClipData)
	local ent = self:ReactivateClip(filmClipData)
	if(ent ~= nil) then return ent end
	pfm.log("Creating film clip '" .. filmClipData:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_film_clip")
	ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP):Setup(filmClipData,self)
	ent:Spawn()

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent}) end
	return ent
end

function ents.PFMTrack:CreateChannelClip(channelClipData)
	local ent = self:ReactivateClip(channelClipData)
	if(ent ~= nil) then return end
	pfm.log("Creating channel clip '" .. channelClipData:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_channel_clip")
	ent:GetComponent(ents.COMPONENT_PFM_CHANNEL_CLIP):Setup(channelClipData,self)
	ent:Spawn()

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent}) end
	return ent
end

function ents.PFMTrack:CreateAudioClip(audioClipData)
	local ent = self:ReactivateClip(audioClipData)
	if(ent ~= nil) then return end
	pfm.log("Creating audio clip '" .. audioClipData:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_audio_clip")
	ent:GetComponent(ents.COMPONENT_PFM_AUDIO_CLIP):Setup(audioClipData,self)
	ent:Spawn()

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent}) end
	return ent
end

function ents.PFMTrack:CreateOverlayClip(overlayClipData)
	local ent = self:ReactivateClip(overlayClipData)
	if(ent ~= nil) then return end
	pfm.log("Creating overlay clip '" .. overlayClipData:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_overlay_clip")
	ent:GetComponent(ents.COMPONENT_PFM_OVERLAY_CLIP):Setup(overlayClipData,self)
	ent:Spawn()

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent}) end
	return ent
end

function ents.PFMTrack:PlayAudio()
	-- TODO
	--[[for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then clipC:PlayAudio() end
	end]]
end

function ents.PFMTrack:PauseAudio()
	-- TODO
	--[[for _,clipC in ipairs(self.m_activeClips) do
		if(clipC:IsValid()) then clipC:PauseAudio() end
	end]]
end

function ents.PFMTrack:GetTimeFrame()
	return self.m_timeFrame
end
ents.COMPONENT_PFM_TRACK = ents.register_component("pfm_track",ents.PFMTrack)

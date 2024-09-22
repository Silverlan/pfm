--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_channel_clip")
include_component("pfm_audio_clip")

util.register_class("ents.PFMTrack", BaseEntityComponent)

function ents.PFMTrack:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")

	self.m_activeClips = {}
	self.m_inactiveClips = {}
	self:SetKeepClipsAlive(true)
end

function ents.PFMTrack:OnRemove()
	self:Reset()
end

function ents.PFMTrack:GetTrackData()
	return self.m_trackData
end
function ents.PFMTrack:GetTrackGroup()
	return self.m_trackGroup
end
function ents.PFMTrack:GetProject()
	return self.m_project
end

function ents.PFMTrack:Reset()
	for clipData, ent in pairs(self.m_activeClips) do
		if ent:IsValid() then
			ent:Remove()
		end
	end
	for clipData, ent in pairs(self.m_inactiveClips) do
		if ent:IsValid() then
			ent:Remove()
		end
	end
	self.m_activeClips = {}
	self.m_inactiveClips = {}
end

function ents.PFMTrack:Setup(trackData, trackGroup, projectC)
	self.m_trackData = trackData
	self.m_trackGroup = trackGroup
	self.m_project = projectC
	self:GetEntity():SetName(trackData:GetName())

	local startTime = math.huge
	local endTime = -math.huge

	for _, filmClip in ipairs((trackData.TypeName == "Session") and trackData:GetClips() or trackData:GetFilmClips()) do
		local timeFrame = filmClip:GetTimeFrame()
		local clipStart = timeFrame:GetStart()
		local clipEnd = timeFrame:GetEnd()
		startTime = math.min(startTime, clipStart)
		endTime = math.max(endTime, clipEnd)
	end
	if trackData.TypeName ~= "Session" then
		for _, audioClip in ipairs(trackData:GetAudioClips()) do
			local timeFrame = audioClip:GetTimeFrame()
			local clipStart = timeFrame:GetStart()
			local clipEnd = timeFrame:GetEnd()
			startTime = math.min(startTime, clipStart)
			endTime = math.max(endTime, clipEnd)
		end
	end
	if startTime == math.huge or endTime == -math.huge then
		startTime = 0.0
		endTime = 0.0
	end

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")
	self.m_timeFrame:SetStart(startTime)
	self.m_timeFrame:SetDuration(endTime - startTime)

	self:UpdateUpdateCacheInfo()
end

function ents.PFMTrack:SetKeepClipsAlive(keepAlive)
	self.m_keepClipsAlive = keepAlive
end

-- Generate update cache to slightly improve performance
function ents.PFMTrack:UpdateUpdateCacheInfo()
	local trackData = self:GetTrackData()
	local clipSets
	if trackData.TypeName == "Session" then
		clipSets = { trackData:GetClips() }
	else
		clipSets = {
			trackData:GetFilmClips(),
			trackData:GetAnimationClips(),
			trackData:GetAudioClips(),
		}
	end
	local clipSetInfos = {}
	for _, clipSet in ipairs(clipSets) do
		local clipInfos = {}
		for _, clip in ipairs(clipSet) do
			local timeFrame = clip:GetTimeFrame()
			table.insert(clipInfos, {
				clip = clip,
				startTime = timeFrame:GetStart(),
				endTime = timeFrame:GetEnd(),
			})
		end
		table.insert(clipSetInfos, {
			clipInfos = clipInfos,
		})
	end

	local activeClipComponents = {}
	for node, clip in pairs(self.m_activeClips) do
		if clip:IsValid() then
			local clipC = clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
				or clip:GetComponent(ents.COMPONENT_PFM_CHANNEL_CLIP)
				or clip:GetComponent(ents.COMPONENT_PFM_AUDIO_CLIP)
				or nil
			if clipC ~= nil then
				table.insert(activeClipComponents, clipC)
			end
		end
	end

	self.m_cachedUpdateInfo = {
		clipSetInfos = clipSetInfos,
		activeClipComponents = activeClipComponents,
	}
end

function ents.PFMTrack:OnOffsetChanged(offset, gameViewFlags)
	local projectC = self:GetProject()
	if projectC:IsValid() and projectC:IsInEditor() then
		-- We need to update the cache every frame in case the clips or time frames have changed in the editor.
		self:UpdateUpdateCacheInfo()
	end

	-- Update film and channel clips
	local activeClipsChanged = false
	for _, clipSet in ipairs(self.m_cachedUpdateInfo.clipSetInfos) do
		local activeClipSetOutOfRange
		local newClipSet
		for _, clipInfo in ipairs(clipSet.clipInfos) do
			local clip = clipInfo.clip

			-- local timeFrame = clip:GetTimeFrame()
			-- local inTimeFrame = timeFrame:IsInTimeFrame(offset)
			-- Same as commented function above, but faster
			local inTimeFrame = (
				offset >= clipInfo.startTime - pfm.udm.TimeFrame.EPSILON
				and offset <= clipInfo.endTime - pfm.udm.TimeFrame.EPSILON
			)

			local isActiveClip = util.is_valid(self.m_activeClips[clip])
			if not isActiveClip and inTimeFrame then
				newClipSet = clip
			end
			if isActiveClip and inTimeFrame == false then
				activeClipSetOutOfRange = clip
			end
		end

		if newClipSet ~= nil then
			if activeClipSetOutOfRange ~= nil then
				-- New offset is out of the range of this film clip; Remove it
				local clip = activeClipSetOutOfRange
				local ent = self.m_activeClips[clip]
				if self.m_keepClipsAlive then
					self.m_inactiveClips[clip] = ent
					if util.is_valid(ent) then
						ent:TurnOff()
					end
				else
					ent:Remove()
				end
				self.m_activeClips[clip] = nil
				activeClipsChanged = true
			end

			-- Initialize the new film clip
			local clip = newClipSet
			if clip.TypeName == "FilmClip" then
				self.m_activeClips[clip] = self:CreateFilmClip(clip)
				activeClipsChanged = true
			elseif clip.TypeName == "AnimationClip" then
				-- self.m_activeClips[clip] = self:CreateChannelClip(clip) -- Obsolete?
			elseif clip.TypeName == "AudioClip" then
				self.m_activeClips[clip] = self:CreateAudioClip(clip)
				activeClipsChanged = true
			elseif clip.TypeName == "OverlayClip" then
				self.m_activeClips[clip] = self:CreateOverlayClip(clip)
				activeClipsChanged = true
			else
				self:LogInfo("Unsupported clip type '" .. clip.TypeName .. "'! Ignoring...")
			end
		end
	end

	if activeClipsChanged then
		self:UpdateUpdateCacheInfo()
	end

	for _, c in ipairs(self.m_cachedUpdateInfo.activeClipComponents) do
		if c:IsValid() then
			c:SetOffset(offset, gameViewFlags)
		end
	end
end

function ents.PFMTrack:GetActiveClips()
	return self.m_activeClips
end

function ents.PFMTrack:ReactivateClip(clipData)
	if util.is_valid(self.m_inactiveClips[clipData]) == false then
		return
	end
	local ent = self.m_inactiveClips[clipData]
	self.m_inactiveClips[clipData] = nil
	ent:TurnOn()
	return ent
end

function ents.PFMTrack:CreateFilmClip(filmClipData)
	local ent = self:ReactivateClip(filmClipData)
	if ent ~= nil then
		return ent
	end
	self:LogInfo("Creating film clip '" .. filmClipData:GetName() .. "'...")
	local ent = self:GetEntity():CreateChild("pfm_film_clip")
	ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP):Setup(filmClipData, self)
	ent:Spawn()

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
	return ent
end

function ents.PFMTrack:CreateChannelClip(channelClipData)
	local ent = self:ReactivateClip(channelClipData)
	if ent ~= nil then
		return
	end
	self:LogInfo("Creating channel clip '" .. channelClipData:GetName() .. "'...")
	local ent = self:GetEntity():CreateChild("pfm_channel_clip")
	ent:GetComponent(ents.COMPONENT_PFM_CHANNEL_CLIP):Setup(channelClipData, self)
	ent:Spawn()

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
	return ent
end

function ents.PFMTrack:CreateAudioClip(audioClipData)
	local ent = self:ReactivateClip(audioClipData)
	if ent ~= nil then
		return
	end
	self:LogInfo("Creating audio clip '" .. audioClipData:GetName() .. "'...")
	local ent = self:GetEntity():CreateChild("pfm_audio_clip")
	ent:GetComponent(ents.COMPONENT_PFM_AUDIO_CLIP):Setup(audioClipData, self)
	ent:Spawn()

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
	return ent
end

function ents.PFMTrack:CreateOverlayClip(overlayClipData)
	local ent = self:ReactivateClip(overlayClipData)
	if ent ~= nil then
		return
	end
	self:LogInfo("Creating overlay clip '" .. overlayClipData:GetName() .. "'...")
	local ent = self:GetEntity():CreateChild("pfm_overlay_clip")
	ent:GetComponent(ents.COMPONENT_PFM_OVERLAY_CLIP):Setup(overlayClipData, self)
	ent:Spawn()

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
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
ents.register_component("pfm_track", ents.PFMTrack, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)

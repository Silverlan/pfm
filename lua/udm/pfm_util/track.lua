-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.Track:GetTrackGroup()
	return self:GetParent()
end

function pfm.udm.Track:GetFilmClip()
	return self:GetTrackGroup():GetParent()
end

function pfm.udm.Track:AddGenericAudioClip(name, soundPath, startTime, duration, uuid)
	if type(name) ~= "string" then
		local audioClip = name
		self:CallChangeListeners("OnAudioClipAdded", audioClip)
		return audioClip
	end
	local audioClip = self:AddAudioClip()
	audioClip:ChangeUniqueId(uuid)
	audioClip:SetName(name)
	audioClip:GetSound():SetSoundName(soundPath)

	local tf = audioClip:GetTimeFrame()
	tf:SetStart(startTime)
	tf:SetDuration(duration)
	self:CallChangeListeners("OnAudioClipAdded", audioClip)
	return audioClip
end

function pfm.udm.Track:RemoveGenericAudioClip(audioClip)
	self:CallChangeListeners("OnAudioClipRemoved", audioClip)
	self:RemoveAudioClip(audioClip)
end

function pfm.udm.Track:FindActorAnimationClip(actor, addIfNotExists)
	if type(actor) ~= "string" then
		actor = tostring(actor:GetUniqueId())
	end
	for _, channelClip in ipairs(self:GetAnimationClips()) do
		if tostring(channelClip:GetActorId()) == actor then
			return channelClip, false
		end
	end
	if addIfNotExists ~= true then
		return
	end
	actor = udm.dereference(self:GetSchema(), actor)
	if actor == nil then
		return
	end
	local channelClip = self:AddAnimationClip()
	channelClip:SetName(actor:GetName())
	channelClip:SetActor(actor:GetUniqueId())
	return channelClip, true
end

function pfm.udm.Track:GetSortedFilmClips()
	local sorted = {}
	for _, fc in ipairs(self:GetFilmClips()) do
		table.insert(sorted, fc)
	end
	table.sort(sorted, function(a, b)
		return a:GetTimeFrame():GetStart() < b:GetTimeFrame():GetStart()
	end)
	return sorted
end

function pfm.udm.Track:ClearFilmClip(filmClip)
	self:RemoveFilmClip(filmClip)
	self:CallChangeListeners("OnFilmClipRemoved", filmClip)
end

function pfm.udm.Track:AddGenericFilmClip()
	local newFc = self:AddFilmClip()
	local channelTrackGroup = newFc:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")
	return newFc
end

function pfm.udm.Track:InsertFilmClipAfter(target, uuid)
	local clips = self:GetSortedFilmClips()
	local newFc = self:AddGenericFilmClip()
	if uuid ~= nil then
		newFc:ChangeUniqueId(uuid)
	end
	newFc:GetTimeFrame():SetDuration(10)
	local targetIndex
	for i, fc in ipairs(clips) do
		if util.is_same_object(fc, target) then
			targetIndex = i
			break
		end
	end
	if targetIndex ~= nil then
		local tStart = target:GetTimeFrame():GetEnd()
		newFc:GetTimeFrame():SetStart(tStart)
		for i = targetIndex + 1, #clips do
			local timeFrame = clips[i]:GetTimeFrame()
			timeFrame:SetStart(tStart)
			tStart = timeFrame:GetEnd()
		end
	end
	self:CallChangeListeners("OnFilmClipAdded", newFc)
	self:UpdateFilmClipTimeFrames()
	return newFc
end

function pfm.udm.Track:InsertFilmClipBefore(target, uuid)
	local clips = self:GetSortedFilmClips()
	local newFc = self:AddGenericFilmClip()
	if uuid ~= nil then
		newFc:ChangeUniqueId(uuid)
	end
	newFc:GetTimeFrame():SetDuration(10)
	local targetIndex
	for i, fc in ipairs(clips) do
		if util.is_same_object(fc, target) then
			targetIndex = i
			break
		end
	end
	if targetIndex ~= nil then
		local tStart = target:GetTimeFrame():GetStart() - newFc:GetTimeFrame():GetDuration()
		newFc:GetTimeFrame():SetStart(tStart)
		if targetIndex > 1 then
			for i = targetIndex - 1, 1 do
				local timeFrame = clips[i]:GetTimeFrame()
				timeFrame:SetStart(tStart - timeFrame:GetDuration())
				tStart = timeFrame:GetStart()
			end
		end
	end
	self:CallChangeListeners("OnFilmClipAdded", newFc)
	self:UpdateFilmClipTimeFrames()
	return newFc
end

function pfm.udm.Track:MoveFilmClipToRight(fc)
	local clips = self:GetSortedFilmClips()
	for i, clip in ipairs(clips) do
		if util.is_same_object(clip, fc) then
			local clipNext = clips[i + 1]
			if clipNext == nil then
				return
			end
			self:MoveFilmClipToLeft(clipNext)
			break
		end
	end
end

function pfm.udm.Track:MoveFilmClipToLeft(fc)
	local clips = self:GetSortedFilmClips()
	for i, clip in ipairs(clips) do
		if util.is_same_object(clip, fc) then
			local clipPrev = clips[i - 1]
			if clipPrev == nil then
				return
			end
			local startPrev = clipPrev:GetTimeFrame():GetStart()
			clipPrev:GetTimeFrame():SetStart(startPrev + fc:GetTimeFrame():GetDuration())
			fc:GetTimeFrame():SetStart(startPrev)
			break
		end
	end
end

function pfm.udm.Track:UpdateFilmClipTimeFrames()
	local tStart = 0.0
	for _, fc in ipairs(self:GetSortedFilmClips()) do
		local timeFrame = fc:GetTimeFrame()
		timeFrame:SetStart(tStart)
		tStart = timeFrame:GetEnd()
	end
	self:CallChangeListeners("OnFilmClipTimeFramesUpdated")
end

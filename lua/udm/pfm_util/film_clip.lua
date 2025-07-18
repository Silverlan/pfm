-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.FilmClip:FindTrackGroup(name)
	for _, trackGroup in ipairs(self:GetTrackGroups()) do
		if trackGroup:GetName() == name then
			return trackGroup
		end
	end
end

function pfm.udm.FilmClip:AddAudioTrack(name, uuid)
	local trackGroupSound = self:FindTrackGroup("Sound")
	if trackGroupSound == nil then
		trackGroupSound = self:AddTrackGroup()
		trackGroupSound:SetName("Sound")
	end
	if trackGroupSound == nil then
		return
	end

	local newTrack = trackGroupSound:AddTrack()
	if uuid ~= nil then
		newTrack:ChangeUniqueId(uuid)
	end
	newTrack:SetName(name)
	self:CallChangeListeners("OnAudioTrackAdded", newTrack)
	return newTrack
end

function pfm.udm.FilmClip:RemoveAudioTrack(audioTrack)
	local trackGroupSound = self:FindTrackGroup("Sound")
	if trackGroupSound == nil then
		return false
	end

	self:CallChangeListeners("OnAudioTrackRemoved", audioTrack)
	trackGroupSound:RemoveTrack(audioTrack)
end

function pfm.udm.FilmClip:FindChannelTrackGroup()
	return self:FindTrackGroup("channelTrackGroup")
end
function pfm.udm.FilmClip:FindSubClipTrackGroup()
	return self:FindTrackGroup("subClipTrackGroup")
end

function pfm.udm.FilmClip:FindAnimationChannelTrack()
	local channelTrackGroup = self:FindChannelTrackGroup()
	return (channelTrackGroup ~= nil) and channelTrackGroup:FindTrack("animSetEditorChannels") or nil
end

function pfm.udm.FilmClip:LocalizeOffset(offset)
	return self:GetTimeFrame():LocalizeOffset(offset)
end
function pfm.udm.FilmClip:LocalizeTimeOffset(offset)
	return self:GetTimeFrame():LocalizeTimeOffset(offset)
end
function pfm.udm.FilmClip:GlobalizeOffset(offset)
	return self:GetTimeFrame():GlobalizeOffset(offset)
end
function pfm.udm.FilmClip:GlobalizeTimeOffset(offset)
	return self:GetTimeFrame():GlobalizeTimeOffset(offset)
end

function pfm.udm.FilmClip:FindEntity()
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PFM_FILM_CLIP) }) do
		local filmClipC = ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
		if util.is_same_object(filmClipC:GetClipData(), self) then
			return ent
		end
	end
end
function pfm.udm.FilmClip:DoesComponentTypeExist(componentType)
	for _, actor in ipairs(self:GetActorList()) do
		local c = actor:FindComponent(componentType)
		if c ~= nil then
			return true
		end
	end
	return false
end
function pfm.udm.FilmClip:FindComponentsByType(componentType)
	local components = {}
	local actors = {}
	for _, actor in ipairs(self:GetActorList()) do
		local c = actor:FindComponent(componentType)
		if c ~= nil then
			table.insert(components, c)
			table.insert(actors, actor)
		end
	end
	return components, actors
end
function pfm.udm.FilmClip:GetActorList(list, recursive)
	if recursive == nil then
		recursive = true
	end
	list = self:GetScene():GetActorList(list)
	if recursive then
		for _, trackGroup in ipairs(self:GetTrackGroups()) do
			for _, track in ipairs(trackGroup:GetTracks()) do
				for _, filmClip in ipairs(track:GetFilmClips()) do
					filmClip:GetActorList(list)
				end
			end
		end
	end
	return list
end
function pfm.udm.FilmClip:FindComponent(componentType)
	for _, actor in ipairs(self:GetActorList()) do
		local c = actor:FindComponent(componentType)
		if c ~= nil then
			return c, actor
		end
	end
end
function pfm.udm.FilmClip:FindActor(name)
	for _, actor in ipairs(self:GetActorList()) do
		if actor:GetName() == name then
			return actor
		end
	end
end
function pfm.udm.FilmClip:FindActorByUniqueId(uuid)
	local actor, group = self:GetScene():FindActorByUniqueId(uuid)
	if actor ~= nil then
		return actor, group
	end
	for _, trackGroup in ipairs(self:GetTrackGroups()) do
		for _, track in ipairs(trackGroup:GetTracks()) do
			for _, filmClip in ipairs(track:GetFilmClips()) do
				local actor, group = filmClip:FindActorByUniqueId(uuid)
				if actor ~= nil then
					return actor, group
				end
			end
		end
	end
end
function pfm.udm.FilmClip:RemoveGroup(group)
	local uuid = tostring(group:GetUniqueId())
	local parentCollection = group:GetParent()
	parentCollection:RemoveGroup(group)
	self:CallChangeListeners("OnGroupRemoved", uuid)
end
function pfm.udm.FilmClip:AddGroup(parentCollection, name, uuid)
	local childGroup = parentCollection:AddGroup()
	childGroup:ChangeUniqueId(uuid)
	childGroup:SetName(name)
	self:CallChangeListeners("OnGroupAdded", childGroup)
	return childGroup
end
function pfm.udm.FilmClip:FindBookmarkSet(setName)
	for _, bmSet in ipairs(self:GetBookmarkSets()) do
		if bmSet:GetName() == setName then
			return bmSet
		end
	end
end
function pfm.udm.FilmClip:GetTrack()
	return self:GetParent()
end
function pfm.udm.FilmClip:FindActorAnimationClip(actor, addIfNotExists)
	if type(actor) ~= "string" then
		actor = tostring(actor:GetUniqueId())
	end
	local track = self:FindAnimationChannelTrack()
	if track == nil then
		return
	end
	return track:FindActorAnimationClip(actor, addIfNotExists)
end
function pfm.udm.FilmClip:GetChildFilmClip(offset)
	for _, trackGroup in ipairs(self:GetTrackGroups()) do
		for _, track in ipairs(trackGroup:GetTracks()) do
			for _, filmClip in ipairs(track:GetFilmClips()) do
				if filmClip:GetTimeFrame():IsInTimeFrame(offset) then
					return filmClip
				end
			end
		end
	end
end
function pfm.udm.FilmClip:RemoveActor(actor, batch)
	local uuid = tostring(actor:GetUniqueId())
	local track = self:FindAnimationChannelTrack()
	if track ~= nil then
		local animClip = self:FindActorAnimationClip(actor, false)
		if animClip ~= nil then
			track:RemoveAnimationClip(animClip)
			-- track:Reinitialize(track:GetUdmData())
		end
	end

	local _, group = self:FindActorByUniqueId(uuid)
	if group ~= nil then
		group:RemoveActor(actor)
		-- group:Reinitialize(group:GetUdmData())
	end

	self:CallChangeListeners("OnActorRemoved", uuid, batch or false)
end
function pfm.udm.FilmClip:RemoveActors(actors)
	local uuids = {}
	for _, actor in ipairs(actors) do
		table.insert(uuids, tostring(actor:GetUniqueId()))
		self:RemoveActor(actor, true)
	end
	self:CallChangeListeners("OnActorsRemoved", uuids)
end
function pfm.udm.FilmClip:RemoveActorComponent(actor, component)
	local c = actor:FindComponent(component)
	if c == nil then
		return
	end
	local animClip = self:FindActorAnimationClip(actor, false)
	if animClip ~= nil then
		local anim = animClip:GetAnimation()
		local removeChannelIndices = {}
		for i, channel in ipairs(anim:GetChannels()) do
			local targetPath = channel:GetTargetPath()
			local componentName, componentPath =
				ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
			if componentName == component then
				table.insert(removeChannelIndices, 1, i)
			end
		end
		for _, idx in ipairs(removeChannelIndices) do
			anim:RemoveChannel(idx)
		end
		animClip:SetPanimaAnimationDirty()
	end
	actor:RemoveComponentType(component)
end

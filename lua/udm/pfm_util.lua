--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Session:GetFilmTrack()
	if(self.m_cachedFilmTrack ~= nil) then return self.m_cachedFilmTrack end
	local filmClip = self:GetActiveClip()
	if(filmClip == nil) then return end
	local trackGroup = filmClip:FindSubClipTrackGroup()
	if(trackGroup == nil) then return end
	for _,track in ipairs(trackGroup:GetTracks()) do
		if(track:GetName() == "Film") then
			self.m_cachedFilmTrack = track
			return
		end
	end
end

function pfm.udm.Session:FindClipAtTimeOffset(t)
	t = t or self:GetTimeOffset()
	local filmTrack = self:GetFilmTrack()
	if(filmTrack == nil) then return end
	for _,filmClip in ipairs(filmTrack:GetFilmClips()) do
		local timeFrame = filmClip:GetTimeFrame()
		if(timeFrame:IsInTimeFrame(t)) then
			return filmClip
		end
	end
end

function pfm.udm.Session:GetPlayheadFrameOffset() return self:GetSettings():GetPlayheadFrameOffset() end
function pfm.udm.Session:GetPlayheadOffset() return self:GetSettings():GetPlayheadOffset() end
function pfm.udm.Session:GetFrameRate() return self:GetSettings():GetFrameRate() end
function pfm.udm.Session:TimeOffsetToFrameOffset(offset) return self:GetSettings():TimeOffsetToFrameOffset(offset) end
function pfm.udm.Session:FrameOffsetToTimeOffset(offset) return self:GetSettings():FrameOffsetToTimeOffset(offset) end

function pfm.udm.TimeFrame:GetEnd() return self:GetStart() +self:GetDuration() end
function pfm.udm.TimeFrame:IsInTimeFrame(t,e)
	e = e or 0.001
	-- Note: -e for both start and end is on purpose
	return t >= self:GetStart() -e and t < self:GetEnd() -e
end
function pfm.udm.TimeFrame:Max(timeFrameOther)
	local startTime = math.min(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.max(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = pfm.udm.TimeFrame.create(self:GetSchema())
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function pfm.udm.TimeFrame:Min(timeFrameOther)
	local startTime = math.max(self:GetStart(),timeFrameOther:GetStart())
	local endTime = math.min(self:GetEnd(),timeFrameOther:GetEnd())
	local duration = endTime -startTime
	local result = pfm.udm.TimeFrame.create(self:GetSchema())
	result:SetStart(startTime)
	result:SetDuration(endTime)
	return result
end
function pfm.udm.TimeFrame:LocalizeOffset(offset)
	return (offset -self:GetStart() +self:GetOffset()) *self:GetScale()
end
function pfm.udm.TimeFrame:GlobalizeOffset(offset)
	return (self:GetStart() +offset -self:GetOffset()) /self:GetScale()
end
function pfm.udm.TimeFrame:LocalizeTimeOffset(offset)
	return offset -self:GetStart()
end
function pfm.udm.TimeFrame:GlobalizeTimeOffset(offset)
	return offset +self:GetStart()
end

function pfm.udm.FilmClip:FindTrackGroup(name)
	for _,trackGroup in ipairs(self:GetTrackGroups()) do
		if(trackGroup:GetName() == name) then return trackGroup end
	end
end

function pfm.udm.FilmClip:FindChannelTrackGroup() return self:FindTrackGroup("channelTrackGroup") end
function pfm.udm.FilmClip:FindSubClipTrackGroup() return self:FindTrackGroup("subClipTrackGroup") end

function pfm.udm.FilmClip:FindAnimationChannelTrack()
	local channelTrackGroup = self:FindChannelTrackGroup()
	return (channelTrackGroup ~= nil) and channelTrackGroup:FindTrack("animSetEditorChannels") or nil
end

function pfm.udm.TrackGroup:FindTrack(name)
	for _,track in ipairs(self:GetTracks()) do
		if(track:GetName() == name) then return track end
	end
end

function pfm.udm.Settings:GetPlayheadFrameOffset() return self:TimeOffsetToFrameOffset(self:GetPlayheadOffset()) end
function pfm.udm.Settings:GetFrameRate() return self:GetRenderSettings():GetFrameRate() end
function pfm.udm.Settings:TimeOffsetToFrameOffset(offset) return offset *self:GetFrameRate() end
function pfm.udm.Settings:FrameOffsetToTimeOffset(offset) return offset /self:GetFrameRate() end

function pfm.udm.Actor:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if(util.is_same_object(actorC:GetActorData(),self)) then return ent end
	end
end

function pfm.udm.Actor:FindComponent(name)
	for _,component in ipairs(self:GetComponents()) do
		if(component:GetType() == name) then return component end
	end
end

function pfm.udm.Actor:HasComponent(name)
	if(type(name) == "string") then return self:FindComponent(name) ~= nil end
	for _,component in ipairs(self:GetComponents()) do
		if(util.is_same_object(name,component)) then return true end
	end
	return false
end

function pfm.udm.Actor:AddComponentType(componentType)
	local component = self:AddComponent()
	component:SetType(componentType)

	local componentName = component:GetType() .. "_component"
	local componentIndex = 1
	while(self:FindComponent(componentName .. componentIndex) ~= nil) do componentIndex = componentIndex +1 end
	component:SetName((componentIndex == 1) and componentName or (componentName .. componentIndex))
	return component
end

function pfm.udm.Actor:ChangeModel(mdlName)
	mdlName = asset.normalize_asset_name(mdlName,asset.TYPE_MODEL)
	local mdlC = self:FindComponent("model") or self:AddComponentType("model")
	-- TODO: Clear animation data for this actor?
	debug.start_profiling_task("pfm_load_model")
	local mdl = game.load_model(mdlName)
	debug.stop_profiling_task()
	mdlC:SetMemberValue("model",udm.TYPE_STRING,mdlName)
end

function pfm.udm.Actor:GetAbsolutePose(filter)
	local pose = self:GetTransform()
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return pose end
	return parent:GetAbsolutePose() *pose
end

function pfm.udm.Actor:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return true end
	return parent:IsAbsoluteVisible()
end

function pfm.udm.EntityComponent:SetMemberValue(memberName,type,value)
	self:GetProperties():SetValue(memberName,type,value)
	self:CallChangeListeners(memberName,value)
end

function pfm.udm.EntityComponent:GetMemberValue(memberName)
	return self:GetProperties():Get(memberName):GetValue()
end

function pfm.udm.FilmClip:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_FILM_CLIP)}) do
		local filmClipC = ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
		if(util.is_same_object(filmClipC:GetClipData(),self)) then return ent end
	end
end
function pfm.udm.FilmClip:GetActorList(list)
	list = self:GetScene():GetActorList(list)
	for _,trackGroup in ipairs(self:GetTrackGroups()) do
		for _,track in ipairs(trackGroup:GetTracks()) do
			for _,filmClip in ipairs(track:GetFilmClips()) do
				filmClip:GetActorList(list)
			end
		end
	end
	return list
end
function pfm.udm.FilmClip:FindActor(name)
	for _,actor in ipairs(self:GetActorList()) do
		if(actor:GetName() == name) then return name end
	end
end
function pfm.udm.FilmClip:GetChildFilmClip(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups()) do
		for _,track in ipairs(trackGroup:GetTracks()) do
			for _,filmClip in ipairs(track:GetFilmClips()) do
				if(filmClip:GetTimeFrame():IsInTimeFrame(offset)) then return filmClip end
			end
		end
	end
end

function pfm.udm.Group:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors()) do
		table.insert(list,actor)
	end
	for _,group in ipairs(self:GetGroups()) do
		group:GetActorList(list)
	end
	return list
end

function pfm.udm.Group:FindActorByUniqueId(uniqueId)
	for _,actor in ipairs(self:GetActorList()) do
		if(actor:GetName() == name) then return name end
	end
end

function pfm.udm.Group:GetAbsolutePose(filter)
	local pose = self:GetTransform()
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return pose end
	return parent:GetAbsolutePose() *pose
end

function pfm.udm.Group:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return true end
	return parent:IsAbsoluteVisible()
end

function pfm.udm.Track:FindActorAnimationClip(actor,addIfNotExists)
	if(type(actor) ~= "string") then actor = tostring(actor:GetUniqueId()) end
	for _,channelClip in ipairs(self:GetAnimationClips()) do
		if(tostring(channelClip:GetActorId()) == actor) then return channelClip end
	end
	if(addIfNotExists ~= true) then return end
	actor = udm.dereference(self:GetSchema(),actor)
	if(actor == nil) then return end
	channelClip = self:AddAnimationClip()
	channelClip:SetName(actor:GetName())
	channelClip:SetActor(actor:GetUniqueId())
	return channelClip
end

function pfm.udm.AnimationClip:OnInitialize()

end
function pfm.udm.AnimationClip:FindChannel(path)
	for _,channel in ipairs(self:GetAnimation():GetChannels()) do
		if(channel:GetTargetPath() == path) then return channel end
	end
end

function pfm.udm.AnimationClip:GetChannel(path,type,addIfNotExists)
	local channel = self:FindChannel(path)
	if(channel ~= nil) then return channel end
	if(addIfNotExists ~= true) then return end
	channel = self:AddChannel(type)
	channel:SetTargetPath(path)
	return channel
end

function pfm.udm.AnimationClip:AddChannel(type)
	local anim = self:GetAnimation()
	local channel = anim:AddChannel()
	channel:SetValuesValueType(type)
	self.m_panimaAnim = nil
	return channel
end

function pfm.udm.AnimationClip:GetPanimaAnimation()
	if(self.m_panimaAnim == nil) then
		self.m_panimaAnim = panima.Animation.load(self:GetAnimation():GetUdmData())
		-- TODO: Re-create panima animation when properties have changed or new channel has been added
	end
	return self.m_panimaAnim
end

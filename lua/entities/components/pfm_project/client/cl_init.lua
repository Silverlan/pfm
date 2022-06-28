--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_model")
include_component("pfm_actor")
include_component("pfm_film_clip")

local cvAnimCache = console.register_variable("pfm_animation_cache_enabled",udm.TYPE_BOOLEAN,true,bit.bor(console.FLAG_BIT_ARCHIVE),"Enables caching for actor animations to speed up performance.")

local Component = util.register_class("ents.PFMProject",BaseEntityComponent)

Component:RegisterMember("PlaybackOffset",ents.MEMBER_TYPE_FLOAT,math.huge,{onChange = function(self) self:OnOffsetChanged() end},"def")

ents.PFMProject.GAME_VIEW_FLAG_NONE = 0
ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE = 1

function ents.PFMProject:__init(ent) BaseEntityComponent.__init(self,ent) end

function ents.PFMProject:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_timeFrame = fudm.PFMTimeFrame()
	self:AddEventCallback(ents.PFMProject.EVENT_ON_ENTITY_CREATED,function(ent) self:OnEntityCreated(ent) end)

	self:AddEntityComponent(ents.COMPONENT_STATIC_BVH_CACHE)
end

function ents.PFMProject:OnEntityCreated(ent)
	local bvhCache = self:GetEntityComponent(ents.COMPONENT_STATIC_BVH_CACHE)
	if(bvhCache ~= nil) then
		bvhCache:AddEntity(ent)
	end

	local filmClipC = ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
	if(filmClipC == nil) then return end
	local clipData = filmClipC:GetClipData()
	local parent = (clipData ~= nil) and clipData:FindAncestor(function(el) return el.TypeName == "Session" or el.TypeName == "FilmClip" end) or nil
	if(parent == nil or parent.TypeName == "Session") then return end
	self:BroadcastEvent(ents.PFMProject.EVENT_ON_FILM_CLIP_CREATED,{filmClipC})
end

function ents.PFMProject:OnRemove()
	self:Reset()
end

function ents.PFMProject:SetProjectData(project)
	self.m_project = project

	local timeFrame
	local session = project:GetSession()
	if(session ~= nil) then
		for _,filmClip in ipairs(session:GetClips()) do
			local timeFrameClip = filmClip:GetTimeFrame()
			timeFrame = timeFrame and timeFrame:Max(timeFrameClip) or timeFrameClip
		end
	end
	self.m_timeFrame = timeFrame or fudm.PFMTimeFrame()
end

local function collect_clips(trackC,clips)
	for clipData,clip in pairs(trackC:GetActiveClips()) do
		if(clip:IsValid()) then table.insert(clips,clip) end
		local filmClipC = clip:IsValid() and clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP) or nil
		if(filmClipC ~= nil) then
			for _,trackGroup in ipairs(filmClipC:GetTrackGroups()) do
				local trackGroupC = trackGroup:IsValid() and trackGroup:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP) or nil
				if(trackGroupC ~= nil) then
					for _,track in ipairs(trackGroupC:GetTracks()) do
						local trackC = track:IsValid() and track:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
						if(trackC ~= nil) then
							collect_clips(trackC,clips)
						end
					end
				end
			end
		end
	end
end
function ents.PFMProject:GetClips()
	local trackC = util.is_valid(self.m_entRootTrack) and self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
	if(trackC == nil) then return {} end
	local clips = {}
	collect_clips(trackC,clips)
	return clips
end

function ents.PFMProject:GetActors()
	local clips = self:GetClips()
	local actors = {}
	for _,clip in ipairs(clips) do
		local filmClipC = clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
		if(filmClipC ~= nil) then
			for _,actor in ipairs(filmClipC:GetActors()) do
				local actorC = actor:IsValid() and actor:GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
				if(actorC ~= nil) then table.insert(actors,actorC) end
			end
		end
	end
	return actors
end

function ents.PFMProject:Start()
	self:Reset()
	
	debug.start_profiling_task("pfm_start_game_view")
	local ent = ents.create("pfm_track")
	local trackC = ent:GetComponent(ents.COMPONENT_PFM_TRACK)
	trackC:Setup(self.m_project:GetSession(),nil,self)
	ent:Spawn()
	self.m_entRootTrack = ent
	self:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent})
	debug.stop_profiling_task()
end

function ents.PFMProject:GetProject() return self.m_project end

function ents.PFMProject:OnOffsetChanged()
	if(self.m_skipOffsetOnChangeCallback) then return end
	self.m_skipOffsetOnChangeCallback = true
	self:ChangePlaybackOffset(self:GetPlaybackOffset())
	self.m_skipOffsetOnChangeCallback = nil
end

local cvPanima = console.get_convar("pfm_experimental_enable_panima_for_flex_and_skeletal_animations")
function ents.PFMProject:ChangePlaybackOffset(offset,gameViewFlags)
	self:SetPlaybackOffset(offset)

	if(util.is_valid(self.m_entRootTrack)) then
		local trackC = self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:OnOffsetChanged(offset,gameViewFlags) end
	end
	
	if(cvAnimCache:GetBool() == false) then return end
	-- if(bit.band(gameViewFlags,ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE) == ents.PFMProject.GAME_VIEW_FLAG_NONE) then return end

	local pm = pfm.get_project_manager()
	local animCache = pm:GetAnimationCache()
	local frameIndex = pm:TimeOffsetToFrameOffset(offset)
	if(animCache == nil) then return end
	-- animCache:UpdateCache(offset)
	local filmClip = animCache:GetFilmClip(frameIndex)
	if(filmClip == nil) then return end
	local usePanima = cvPanima:GetBool()
	-- TODO: Ensure that the entity actually belongs to this project
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_MODEL)}) do
		local mdlC = ent:GetComponent(ents.COMPONENT_PFM_MODEL)
		local mdl = ent:GetModel()
		local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if(mdl ~= nil and animC ~= nil and actorC ~= nil and mdlC:IsAnimationFrozen() == false) then
			local animName = animCache:GetAnimationName(filmClip,actorC:GetActorData())
			
			local flexC = ent:GetComponent(ents.COMPONENT_FLEX)
			if(usePanima == false) then
				animC:PlayAnimation(animName)
				if(flexC ~= nil) then flexC:PlayFlexAnimation(animName) end
			end
			local anim = animC:GetAnimationObject()
			if(anim ~= nil) then
				local numFrames = anim:GetFrameCount()
				local cycle = (numFrames >= 2) and (frameIndex /(numFrames -1)) or 0
				animC:SetCycle(cycle)
				if(flexC ~= nil) then flexC:SetFlexAnimationCycle(animName,cycle) end
			end
			animC:SetPlaybackRate(0.0)
			if(flexC ~= nil) then flexC:SetFlexAnimationPlaybackRate(animName,0.0) end
		end
	end
end

function ents.PFMProject:Reset()
	util.remove(self.m_entRootTrack)
	self:SetPlaybackOffset(math.huge)
end

function ents.PFMProject:GetTimeFrame() return self.m_timeFrame end
ents.COMPONENT_PFM_PROJECT = ents.register_component("pfm_project",ents.PFMProject)
ents.PFMProject.EVENT_ON_ACTOR_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT,"on_actor_created")
ents.PFMProject.EVENT_ON_ENTITY_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT,"on_entity_created")
ents.PFMProject.EVENT_ON_FILM_CLIP_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT,"on_film_clip_created")

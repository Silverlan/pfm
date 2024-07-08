--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_model")
include_component("pfm_actor")
include_component("pfm_film_clip")
include_component("pfm_editor_actor")

local Component = util.register_class("ents.PFMProject", BaseEntityComponent)

include("precache.lua")

Component:RegisterMember("PlaybackOffset", ents.MEMBER_TYPE_FLOAT, math.huge, {
	onChange = function(self)
		self:OnOffsetChanged()
	end,
}, "def")

Component.GAME_VIEW_FLAG_NONE = 0
Component.GAME_VIEW_FLAG_BIT_USE_CACHE = 1

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_timeFrame = udm.create_property_from_schema(pfm.udm.SCHEMA, "TimeFrame")
	self:AddEventCallback(Component.EVENT_ON_ENTITY_CREATED, function(ent)
		self:OnEntityCreated(ent)
	end)

	self:AddEntityComponent(ents.COMPONENT_STATIC_BVH_CACHE)
end

function Component:OnEntityCreated(ent)
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		actorC:SetProject(self)
	end

	local pm = self:GetProjectManager()
	if util.is_valid(pm) and pm:IsEditor() then
		-- This project is running in an editor, we'll add a special component to the actors
		-- to mark them as editor actors.
		ent:AddComponent(ents.COMPONENT_PFM_EDITOR_ACTOR)
	end

	local filmClipC = ent:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
	if filmClipC == nil then
		return
	end
	local clipData = filmClipC:GetClipData()
	local parent = (clipData ~= nil)
			and clipData:FindAncestor(function(el)
				return el.TypeName == "Session" or el.TypeName == "FilmClip"
			end)
		or nil
	if parent == nil or parent.TypeName == "Session" then
		return
	end

	self.m_activeGameViewFilmClip = filmClipC:GetClipData()
	local animManager = self:GetAnimationManager()
	if animManager ~= nil then
		animManager:SetFilmClip(self.m_activeGameViewFilmClip)
	end

	self:BroadcastEvent(Component.EVENT_ON_FILM_CLIP_CREATED, { filmClipC })
end

function Component:GetActiveGameViewFilmClip()
	return self.m_activeGameViewFilmClip
end

function Component:OnRemove()
	self:Reset()
end

function Component:SetProjectData(project, projectManager)
	self.m_project = project
	self:SetProjectManager(projectManager)

	local timeFrame
	local session = project:GetSession()
	if session ~= nil then
		for _, filmClip in ipairs(session:GetClips()) do
			local timeFrameClip = filmClip:GetTimeFrame()
			timeFrame = timeFrame and timeFrame:Max(timeFrameClip) or timeFrameClip
		end
	end
	self.m_timeFrame = timeFrame or fudm.PFMTimeFrame()
end

local function collect_clips(trackC, clips)
	for clipData, clip in pairs(trackC:GetActiveClips()) do
		if clip:IsValid() then
			table.insert(clips, clip)
		end
		local filmClipC = clip:IsValid() and clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP) or nil
		if filmClipC ~= nil then
			for _, trackGroup in ipairs(filmClipC:GetTrackGroups()) do
				local trackGroupC = trackGroup:IsValid() and trackGroup:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP)
					or nil
				if trackGroupC ~= nil then
					for _, track in ipairs(trackGroupC:GetTracks()) do
						local trackC = track:IsValid() and track:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
						if trackC ~= nil then
							collect_clips(trackC, clips)
						end
					end
				end
			end
		end
	end
end
function Component:GetClips()
	local trackC = util.is_valid(self.m_entRootTrack) and self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		or nil
	if trackC == nil then
		return {}
	end
	local clips = {}
	collect_clips(trackC, clips)
	return clips
end
function Component:GetActorIterator(animatedOnly)
	local filters = { ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR) }
	if animatedOnly then
		table.insert(filters, ents.IteratorFilterComponent(ents.COMPONENT_PANIMA))
	end
	table.insert(
		filters,
		ents.IteratorFilterFunction(function(ent, c)
			return util.is_same_object(c:GetProject(), self)
		end)
	)
	return ents.iterator(filters)
end
function Component:GetActors()
	local clips = self:GetClips()
	local actors = {}
	for _, clip in ipairs(clips) do
		local filmClipC = clip:GetComponent(ents.COMPONENT_PFM_FILM_CLIP)
		if filmClipC ~= nil then
			for _, actor in ipairs(filmClipC:GetActors()) do
				local actorC = actor:IsValid() and actor:GetComponent(ents.COMPONENT_PFM_ACTOR) or nil
				if actorC ~= nil then
					table.insert(actors, actorC)
				end
			end
		end
	end
	return actors
end

function Component:Start()
	self:Reset()

	debug.start_profiling_task("pfm_start_game_view")
	self:AddEntityComponent("pfm_animation_manager")
	local ent = self:GetEntity():CreateChild("pfm_track")
	local trackC = ent:GetComponent(ents.COMPONENT_PFM_TRACK)
	trackC:Setup(self.m_project:GetSession(), nil, self)
	ent:Spawn()
	self.m_entRootTrack = ent

	local track = self.m_project:GetSession():GetFilmTrack()
	util.remove(self.m_cbOnFilmClipRemoved)
	self.m_cbOnFilmClipRemoved = track:AddChangeListener("OnFilmClipRemoved", function(c, filmClip)
		if util.is_same_object(self:GetActiveGameViewFilmClip(), filmClip) then
			self:ClearActiveGameViewFilmClip()
		end
	end)

	self:BroadcastEvent(Component.EVENT_ON_ENTITY_CREATED, { ent })
	debug.stop_profiling_task()
end

function Component:GetProject()
	return self.m_project
end

function Component:GetSession()
	return (self.m_project ~= nil) and self.m_project:GetSession() or nil
end

function Component:OnOffsetChanged()
	if self.m_skipOffsetOnChangeCallback then
		return
	end
	self.m_skipOffsetOnChangeCallback = true
	self:ChangePlaybackOffset(self:GetPlaybackOffset())
	self.m_skipOffsetOnChangeCallback = nil
end

function Component:SetProjectManager(pm)
	self.m_projectManager = pm
end
function Component:GetProjectManager()
	return self.m_projectManager
end
function Component:IsInEditor()
	return util.is_valid(self.m_projectManager) and self.m_projectManager:IsEditor()
end
function Component:GetAnimationManager()
	return self:GetEntityComponent(ents.COMPONENT_PFM_ANIMATION_MANAGER)
end
function Component:ClearActiveGameViewFilmClip()
	self.m_activeGameViewFilmClip = nil
	local animManager = self:GetAnimationManager()
	if animManager ~= nil then
		animManager:Reset()
	end
end
function Component:ChangePlaybackOffset(offset, gameViewFlags)
	if offset == self.m_prevPlaybackOffset or self.m_project == nil then
		return
	end

	local session = self.m_project:GetSession()
	local activeClip = (session ~= nil) and session:GetActiveClip() or nil
	local gameViewFlags = ents.PFMProject.GAME_VIEW_FLAG_NONE
	if activeClip == nil then
		self:ClearActiveGameViewFilmClip()
	end

	self.m_prevPlaybackOffset = offset
	self:SetPlaybackOffset(offset)

	if util.is_valid(self.m_entRootTrack) then
		local trackC = self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		if trackC ~= nil then
			trackC:OnOffsetChanged(offset, gameViewFlags)
		end
	end

	local animManager = self:GetAnimationManager()
	if animManager ~= nil then
		animManager:SetTime(offset)
	end

	self:InvokeEventCallbacks(Component.EVENT_ON_PLAYBACK_OFFSET_CHANGED, { offset })
end

function Component:Reset()
	self:GetEntity():RemoveComponent("pfm_animation_manager")
	util.remove(self.m_cbOnFilmClipRemoved)
	util.remove(self.m_entRootTrack)
	self:SetPlaybackOffset(math.huge)
end

function Component:GetTimeFrame()
	return self.m_timeFrame
end
ents.COMPONENT_PFM_PROJECT = ents.register_component("pfm_project", Component)
Component.EVENT_ON_ACTOR_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT, "on_actor_created")
Component.EVENT_ON_ENTITY_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT, "on_entity_created")
Component.EVENT_ON_FILM_CLIP_CREATED = ents.register_component_event(ents.COMPONENT_PFM_PROJECT, "on_film_clip_created")
Component.EVENT_ON_PLAYBACK_OFFSET_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_PROJECT, "on_playback_offset_changed")

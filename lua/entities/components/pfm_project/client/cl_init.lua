--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_model")
include_component("pfm_actor")

local cvAnimCache = console.register_variable("pfm_animation_cache_enabled","1",bit.bor(console.FLAG_BIT_ARCHIVE),"Enables caching for actor animations to speed up performance.")

util.register_class("ents.PFMProject",BaseEntityComponent)

ents.PFMProject.GAME_VIEW_FLAG_NONE = 0
ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE = 1

function ents.PFMProject:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = math.huge -- Current playback offset in seconds
	self.m_timeFrame = udm.PFMTimeFrame()
end

function ents.PFMProject:OnRemove()
	self:Reset()
end

function ents.PFMProject:SetProjectData(project)
	self.m_project = project

	local timeFrame
	local session = project:GetSessions()[1] -- TODO: How to handle multiple sessions?
	if(session ~= nil) then
		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			local timeFrameClip = filmClip:GetTimeFrame()
			timeFrame = timeFrame and timeFrame:Max(timeFrameClip) or timeFrameClip
		end
	end
	self.m_timeFrame = timeFrame or udm.PFMTimeFrame()

	self.m_rootTrack = udm.PFMTrack()
	if(session ~= nil) then
		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			self.m_rootTrack:GetFilmClipsAttr():PushBack(filmClip)
		end
	end
end

function ents.PFMProject:Start()
	self:Reset()

	local ent = ents.create("pfm_track")
	ent:GetComponent(ents.COMPONENT_PFM_TRACK):Setup(self.m_rootTrack)
	ent:Spawn()
	self.m_entRootTrack = ent
end

function ents.PFMProject:GetProject() return self.m_project end

function ents.PFMProject:SetOffset(offset,gameViewFlags)
	if(offset == self.m_offset) then return end
	-- pfm.log("Changing playback offset to " .. offset .. "...",pfm.LOG_CATEGORY_PFM_GAME)
	self.m_offset = offset

	if(util.is_valid(self.m_entRootTrack)) then
		local trackC = self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:OnOffsetChanged(offset,gameViewFlags) end
	end
	if(cvAnimCache:GetBool() == false) then return end
	-- if(bit.band(gameViewFlags,ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE) == ents.PFMProject.GAME_VIEW_FLAG_NONE) then return end

	local filmmaker = tool.get_filmmaker()
	local animCache = filmmaker:GetAnimationCache()
	local frameIndex = filmmaker:TimeOffsetToFrameOffset(offset)
	if(animCache == nil) then return end
	animCache:UpdateCache(offset)
	local filmClip = animCache:GetFilmClip(frameIndex)
	if(filmClip == nil) then return end
	-- TODO: Ensure that the entity actually belongs to this project
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_MODEL)}) do
		local mdl = ent:GetModel()
		local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if(mdl ~= nil and animC ~= nil and actorC ~= nil) then
			local animName = animCache:GetAnimationName(filmClip,actorC:GetActorData())
			animC:PlayAnimation(animName)
			local anim = animC:GetAnimationObject()
			if(anim ~= nil) then
				local cycle = frameIndex /(anim:GetFrameCount() -1)
				animC:SetCycle(cycle)
			end
			animC:SetPlaybackRate(0.0)
		end
	end
end

function ents.PFMProject:GetOffset()
	return self.m_offset
end

function ents.PFMProject:Reset()
	if(util.is_valid(self.m_entRootTrack)) then self.m_entRootTrack:Remove() end
	self.m_offset = math.huge
end

function ents.PFMProject:GetTimeFrame() return self.m_timeFrame end
ents.COMPONENT_PFM_PROJECT = ents.register_component("pfm_project",ents.PFMProject)

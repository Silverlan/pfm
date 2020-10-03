--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("film_clip")
include("udm_group.lua")

udm.ELEMENT_TYPE_PFM_FILM_CLIP = udm.register_element("PFMFilmClip")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"timeFrame",udm.PFMTimeFrame())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"actors",udm.Array(udm.ELEMENT_TYPE_ANY)) -- Can contain actors or groups
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"trackGroups",udm.Array(udm.ELEMENT_TYPE_PFM_TRACK_GROUP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"scene",udm.PFMGroup())
-- TODO: Material overlay should be an actor with a material overlay component
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeIn",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeOut",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"bookmarkSets",udm.Array(udm.ELEMENT_TYPE_PFM_BOOKMARK_SET))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"activeBookmarkSet",udm.Int())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"mapName",udm.String())

function udm.PFMFilmClip:AddActor(actor)
	for _,actorOther in ipairs(self:GetActorList()) do
		if(util.is_same_object(actor,actorOther)) then return end
	end
	self:GetActors():PushBack(actor)
end

function udm.PFMFilmClip:AddGroup(group)
	self:AddActor(group)
end

function udm.PFMFilmClip:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then actor:GetActorList(list)
		else table.insert(list,actor) end
	end
	return list
end

function udm.PFMFilmClip:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent("pfm_film_clip")}) do
		local filmClipC = ent:GetComponent("pfm_film_clip")
		if(util.is_same_object(filmClipC:GetClipData(),self)) then return ent end
	end
end

function udm.PFMFilmClip:FindActor(name)
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then
			local el = actor:FindActor(name)
			if(el ~= nil) then return el end
		elseif(actor:GetName() == name) then return actor end
	end
end

function udm.PFMFilmClip:FindTrackGroup(name)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		if(trackGroup:GetName() == name) then return trackGroup end
	end
end

function udm.PFMFilmClip:FindChannelTrackGroup() return self:FindTrackGroup("channelTrackGroup") end
function udm.PFMFilmClip:FindSubClipTrackGroup() return self:FindTrackGroup("subClipTrackGroup") end

function udm.PFMFilmClip:FindAnimationChannelTrack()
	local channelTrackGroup = self:FindChannelTrackGroup()
	return (channelTrackGroup ~= nil) and channelTrackGroup:FindTrack("animSetEditorChannels") or nil
end

function udm.PFMFilmClip:SetPlaybackOffset(offset,filter)
	if(self:GetTimeFrame():IsInTimeFrame(offset) == false) then return end
	local localOffset = self:LocalizeOffset(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		trackGroup:SetPlaybackOffset(localOffset,offset,filter)
	end
end

function udm.PFMFilmClip:LocalizeOffset(offset) return self:GetTimeFrame():LocalizeOffset(offset) end
function udm.PFMFilmClip:LocalizeTimeOffset(offset) return self:GetTimeFrame():LocalizeTimeOffset(offset) end

function udm.PFMFilmClip:GetChildFilmClip(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
				if(filmClip:GetTimeFrame():IsInTimeFrame(offset)) then return filmClip end
			end
		end
	end
end

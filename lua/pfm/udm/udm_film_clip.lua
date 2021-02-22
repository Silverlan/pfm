--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("film_clip")
include("udm_group.lua")

fudm.ELEMENT_TYPE_PFM_FILM_CLIP = fudm.register_element("PFMFilmClip")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"timeFrame",fudm.PFMTimeFrame())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"actors",fudm.Array(fudm.ELEMENT_TYPE_ANY)) -- Can contain actors or groups
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"trackGroups",fudm.Array(fudm.ELEMENT_TYPE_PFM_TRACK_GROUP))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"scene",fudm.PFMGroup())
-- TODO: Material overlay should be an actor with a material overlay component
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeIn",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeOut",fudm.Float())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"bookmarkSets",fudm.Array(fudm.ELEMENT_TYPE_PFM_BOOKMARK_SET))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"activeBookmarkSet",fudm.Int())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_FILM_CLIP,"mapName",fudm.String())

function fudm.PFMFilmClip:AddActor(actor)
	for _,actorOther in ipairs(self:GetActorList()) do
		if(util.is_same_object(actor,actorOther)) then return end
	end
	self:GetActors():PushBack(actor)
end

function fudm.PFMFilmClip:AddGroup(group)
	self:AddActor(group)
end

function fudm.PFMFilmClip:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == fudm.ELEMENT_TYPE_PFM_GROUP) then actor:GetActorList(list)
		else table.insert(list,actor) end
	end
	return list
end

function fudm.PFMFilmClip:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent("pfm_film_clip")}) do
		local filmClipC = ent:GetComponent("pfm_film_clip")
		if(util.is_same_object(filmClipC:GetClipData(),self)) then return ent end
	end
end

function fudm.PFMFilmClip:FindActor(name)
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == fudm.ELEMENT_TYPE_PFM_GROUP) then
			local el = actor:FindActor(name)
			if(el ~= nil) then return el end
		elseif(actor:GetName() == name) then return actor end
	end
end

function fudm.PFMFilmClip:FindTrackGroup(name)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		if(trackGroup:GetName() == name) then return trackGroup end
	end
end

function fudm.PFMFilmClip:FindChannelTrackGroup() return self:FindTrackGroup("channelTrackGroup") end
function fudm.PFMFilmClip:FindSubClipTrackGroup() return self:FindTrackGroup("subClipTrackGroup") end

function fudm.PFMFilmClip:FindAnimationChannelTrack()
	local channelTrackGroup = self:FindChannelTrackGroup()
	return (channelTrackGroup ~= nil) and channelTrackGroup:FindTrack("animSetEditorChannels") or nil
end

function fudm.PFMFilmClip:SetPlaybackOffset(offset,filter)
	if(self:GetTimeFrame():IsInTimeFrame(offset) == false) then return end
	local localOffset = self:LocalizeOffset(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		trackGroup:SetPlaybackOffset(localOffset,offset,filter)
	end
end

function fudm.PFMFilmClip:LocalizeOffset(offset) return self:GetTimeFrame():LocalizeOffset(offset) end
function fudm.PFMFilmClip:LocalizeTimeOffset(offset) return self:GetTimeFrame():LocalizeTimeOffset(offset) end

function fudm.PFMFilmClip:GetChildFilmClip(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
				if(filmClip:GetTimeFrame():IsInTimeFrame(offset)) then return filmClip end
			end
		end
	end
end

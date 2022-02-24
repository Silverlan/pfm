--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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

function pfm.udm.FilmClip:LocalizeOffset(offset) return self:GetTimeFrame():LocalizeOffset(offset) end
function pfm.udm.FilmClip:LocalizeTimeOffset(offset) return self:GetTimeFrame():LocalizeTimeOffset(offset) end

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
function pfm.udm.FilmClip:FindActorAnimationClip(actor,addIfNotExists)
    if(type(actor) ~= "string") then actor = tostring(actor:GetUniqueId()) end
    local track = self:FindAnimationChannelTrack()
    if(track == nil) then return end
    return track:FindActorAnimationClip(actor,addIfNotExists)
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

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
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"actors",udm.Array(udm.ELEMENT_TYPE_PFM_ACTOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"trackGroups",udm.Array(udm.ELEMENT_TYPE_PFM_TRACK_GROUP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"scene",udm.PFMGroup())
-- TODO: Material overlay should be an actor with a material overlay component
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"materialOverlay",udm.PFMMaterialOverlayFXClip())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeIn",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"fadeOut",udm.Float())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"bookmarkSets",udm.Array(udm.ELEMENT_TYPE_PFM_BOOKMARK_SET))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_FILM_CLIP,"activeBookmarkSet",udm.Int())

function udm.PFMFilmClip:SetPlaybackOffset(offset)
	if(self:GetTimeFrame():IsInTimeFrame(offset) == false) then return end
	local timeFrame = self:GetTimeFrame()
	local localOffset = timeFrame:LocalizeOffset(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		trackGroup:SetPlaybackOffset(localOffset,offset)
	end
end

function udm.PFMFilmClip:GetChildFilmClip(offset)
	for _,trackGroup in ipairs(self:GetTrackGroups():GetTable()) do
		for _,track in ipairs(trackGroup:GetTracks():GetTable()) do
			for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
				if(filmClip:GetTimeFrame():IsInTimeFrame(offset)) then return filmClip end
			end
		end
	end
end

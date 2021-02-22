--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track_group")

fudm.ELEMENT_TYPE_PFM_TRACK_GROUP = fudm.register_element("PFMTrackGroup")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRACK_GROUP,"tracks",fudm.Array(fudm.ELEMENT_TYPE_PFM_TRACK))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRACK_GROUP,"visible",fudm.Bool(true),{
	getter = "IsVisible"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_TRACK_GROUP,"muted",fudm.Bool(false),{
	getter = "IsMuted"
})

function fudm.PFMTrackGroup:SetPlaybackOffset(localOffset,absOffset,filter)
	for _,track in ipairs(self:GetTracks():GetTable()) do
		track:SetPlaybackOffset(localOffset,absOffset,filter)
	end
end

function fudm.PFMTrackGroup:FindTrack(name)
	for _,track in ipairs(self:GetTracks():GetTable()) do
		if(track:GetName() == name) then return track end
	end
end

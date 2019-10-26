--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("track.lua")

util.register_class("sfm.TrackGroup",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.TrackGroup,"tracks",sfm.Track)
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup,"visible",true,{
	getterName = "IsVisible"
})
sfm.BaseElement.RegisterAttribute(sfm.TrackGroup,"mute",false,{
	getterName = "IsMuted"
})

function sfm.TrackGroup:__init()
  sfm.BaseElement.__init(self,sfm.TrackGroup)
end

function sfm.TrackGroup:ToPFMTrackGroup(pfmTrackGroup)
	pfmTrackGroup:SetVisible(self:IsVisible())
	pfmTrackGroup:SetMuted(self:IsMuted())
	for _,track in ipairs(self:GetTracks()) do
		local pfmTrack = udm.PFMTrack(track:GetName())
		track:ToPFMTrack(pfmTrack)
		pfmTrackGroup:GetTracksAttr():PushBack(pfmTrack)
	end
end

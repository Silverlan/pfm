--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_track")

util.register_class("ents.PFMTrackGroup", BaseEntityComponent)

function ents.PFMTrackGroup:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_tracks = {}

	-- self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON,"OnTurnOn")
	-- self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF,"OnTurnOff")
end

--[[function ents.PFMTrackGroup:OnTurnOn()
	for _,ent in ipairs(self.m_tracks) do if(ent:IsValid()) then ent:TurnOn() end end
end

function ents.PFMTrackGroup:OnTurnOff()
	for _,ent in ipairs(self.m_tracks) do if(ent:IsValid()) then ent:TurnOff() end end
end]]

function ents.PFMTrackGroup:OnRemove()
	for _, track in ipairs(self.m_tracks) do
		if track:IsValid() then
			track:Remove()
		end
	end
end

function ents.PFMTrackGroup:GetProject()
	local filmClipC = self:GetFilmClip()
	if util.is_valid(filmClipC) == false then
		return
	end
	return filmClipC:GetProject()
end

function ents.PFMTrackGroup:OnOffsetChanged(offset, gameViewFlags)
	for _, track in ipairs(self.m_tracks) do
		local trackC = track:IsValid() and track:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
		if trackC ~= nil then
			trackC:OnOffsetChanged(offset, gameViewFlags)
		end
	end
end

function ents.PFMTrackGroup:GetTrackGroupData()
	return self.m_trackGroupData
end
function ents.PFMTrackGroup:GetFilmClip()
	return self.m_filmClip
end
function ents.PFMTrackGroup:GetTracks()
	return self.m_tracks
end

function ents.PFMTrackGroup:Setup(trackGroupData, filmClipC)
	self.m_trackGroupData = trackGroupData
	self.m_filmClip = filmClipC
	for _, track in ipairs(trackGroupData:GetTracks()) do
		if track:IsMuted() == false then
			self:CreateTrack(track)
		end
	end
	self:GetEntity():SetName(trackGroupData:GetName())
end

function ents.PFMTrackGroup:CreateTrack(trackData)
	pfm.log("Creating track '" .. trackData:GetName() .. "'...", pfm.LOG_CATEGORY_PFM_GAME)
	local ent = self:GetEntity():CreateChild("pfm_track")
	ent:GetComponent(ents.COMPONENT_PFM_TRACK):Setup(trackData, self, self:GetProject())
	ent:Spawn()
	table.insert(self.m_tracks, ent)

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
end
ents.COMPONENT_PFM_TRACK_GROUP = ents.register_component("pfm_track_group", ents.PFMTrackGroup)

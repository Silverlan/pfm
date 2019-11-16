--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_track_group")

util.register_class("ents.PFMFilmClip",BaseEntityComponent)

local CLIP_CAMERA_ENABLED = true
ents.PFMFilmClip.set_clip_camera_enabled = function(enabled)
	CLIP_CAMERA_ENABLED = enabled
end
function ents.PFMFilmClip:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = 0.0
	
	self.m_actors = {}
	self.m_trackGroups = {}
	self:AddEntityComponent(ents.COMPONENT_NAME)
end

function ents.PFMFilmClip:OnRemove()
	for _,actor in ipairs(self.m_actors) do
		if(actor:IsValid()) then actor:Remove() end
	end
	for _,trackGroup in ipairs(self.m_trackGroups) do
		if(trackGroup:IsValid()) then trackGroup:Remove() end
	end
end

function ents.PFMFilmClip:FindActorByName(name,filter)
	for _,actor in ipairs(self:GetActors()) do
		if(actor:IsValid() and actor:GetName() == name and (filter == nil or filter(actor))) then return actor end
	end
end

function ents.PFMFilmClip:GetActors() return self.m_actors end
function ents.PFMFilmClip:GetTrackGroups() return self.m_trackGroups end
function ents.PFMFilmClip:GetCamera() return self.m_camera end

function ents.PFMFilmClip:Setup(filmClip,trackC)
	self.m_filmClipData = filmClip
	self.m_track = trackC

	local matOverlay = filmClip:GetMaterialOverlay()
	if(matOverlay ~= nil and #matOverlay:GetMaterial() > 0) then
		local entActor = ents.create("pfm_material_overlay")
		entActor:GetComponent("pfm_material_overlay"):Setup(self,matOverlay)
		entActor:Spawn()
		table.insert(self.m_actors,entActor)
	end

	local fadeIn = filmClip:GetFadeIn()
	local fadeOut = filmClip:GetFadeOut()
	if(fadeIn > 0.0 or fadeOut > 0.0) then
		local matOverlayData = udm.PFMMaterialOverlayFXClip()
		matOverlayData:SetTimeFrame(filmClip:GetTimeFrame())
		matOverlayData:SetMaterial("black")
		matOverlayData:SetFullscreen(true)
		local entActor = ents.create("pfm_material_overlay")
		entActor:GetComponent("pfm_material_overlay"):Setup(self,matOverlayData,fadeIn,fadeOut)
		entActor:Spawn()
		table.insert(self.m_actors,entActor)
	end

	for _,actorData in ipairs(filmClip:GetActors():GetTable()) do
		self:CreateActor(actorData)
	end

	for _,trackGroupData in ipairs(filmClip:GetTrackGroups():GetTable()) do
		if(trackGroupData:IsMuted() == false) then
			self:CreateTrackGroup(trackGroupData)
		end
	end
	self:GetEntity():SetName(filmClip:GetName())

	local cam = self:GetClipData():GetProperty("camera")
	if(cam ~= nil) then
		local entCam = self:FindActorByName(cam:GetName(),function(ent) return ent:HasComponent("pfm_camera") end)
		self.m_camera = entCam and entCam:GetComponent("pfm_camera") or entCam
	end
	if(util.is_valid(self.m_camera) == false) then
		if(cam == nil) then
			pfm.log("Film clip '" .. self:GetEntity():GetName() .. "' has no camera!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
		else
			pfm.log("No camera by name '" .. cam:GetName() .. "' found for film clip ('" .. self:GetEntity():GetName() .. "')!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
		end
	else ents.PFMCamera.set_active_camera(self.m_camera) end
end

function ents.PFMFilmClip:GetClipData() return self.m_filmClipData end
function ents.PFMFilmClip:GetTrack() return self.m_track end

function ents.PFMFilmClip:GetOffset() return self.m_offset end
function ents.PFMFilmClip:SetOffset(offset)
	local timeFrame = self:GetTimeFrame()
	local absOffset = offset
	offset = timeFrame:LocalizeOffset(offset)
	if(offset == self.m_offset) then return end
	self.m_offset = offset
	self:UpdateClip()
	
	self:BroadcastEvent(ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED,{offset,absOffset})
end

function ents.PFMFilmClip:UpdateClip()
	for _,trackGroup in ipairs(self:GetTrackGroups()) do
		local trackGroupC = trackGroup:IsValid() and trackGroup:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP) or nil
		if(trackGroupC ~= nil) then
			trackGroupC:OnOffsetChanged(self:GetOffset())
		end
	end
end

function ents.PFMFilmClip:CreateTrackGroup(trackGroup)
	pfm.log("Creating track group '" .. trackGroup:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_track_group")
	ent:Spawn()
	ent:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP):Setup(trackGroup,self)
	table.insert(self.m_trackGroups,ent)
end

function ents.PFMFilmClip:CreateActor(actor)
	local entActor = ents.create("pfm_actor")
	entActor:GetComponent(ents.COMPONENT_PFM_ACTOR):Setup(actor)
	entActor:Spawn()
	table.insert(self.m_actors,entActor)

	local pos = entActor:GetPos()
	local ang = entActor:GetRotation():ToEulerAngles()
	pfm.log("Created actor '" .. actor:GetName() .. "' at position (" .. util.round_string(pos.x,0) .. "," .. util.round_string(pos.y,0) .. "," .. util.round_string(pos.z,0) .. ") with rotation (" .. util.round_string(ang.p,0) .. "," .. util.round_string(ang.y,0) .. "," .. util.round_string(ang.r,0) .. ")...",pfm.LOG_CATEGORY_PFM_GAME)
end

function ents.PFMFilmClip:GetTimeFrame()
	local clip = self:GetClipData()
	if(clip == nil) then return udm.PFMTimeFrame() end
	return clip:GetTimeFrame()
end

function ents.PFMFilmClip:PlayAudio()
	-- TODO
	--[[for _,actor in ipairs(self.m_entities) do
		if(actor:IsValid()) then
			local sndC = actor:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
			if(sndC ~= nil) then sndC:Play() end
		end
	end]]
end

function ents.PFMFilmClip:PauseAudio()
	-- TODO
	--[[for _,actor in ipairs(self.m_entities) do
		if(actor:IsValid()) then
			local sndC = actor:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
			if(sndC ~= nil) then sndC:Pause() end
		end
	end]]
end

ents.COMPONENT_PFM_FILM_CLIP = ents.register_component("pfm_film_clip",ents.PFMFilmClip)
ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_FILM_CLIP,"on_offset_changed")

--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_track_group")

util.register_class("ents.PFMFilmClip",BaseEntityComponent)

function ents.PFMFilmClip:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = 0.0
	
	self.m_actors = {}
	self.m_trackGroups = {}
	self:AddEntityComponent(ents.COMPONENT_NAME)

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON,"OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF,"OnTurnOff")
end

function ents.PFMFilmClip:OnTurnOn()
	for _,actor in ipairs(self:GetActors()) do if(actor:IsValid()) then actor:TurnOn() end end
	-- for _,ent in ipairs(self.m_trackGroups) do if(ent:IsValid()) then ent:TurnOn() end end
end

function ents.PFMFilmClip:OnTurnOff()
	for _,actor in ipairs(self:GetActors()) do if(actor:IsValid()) then actor:TurnOff() end end
	-- for _,ent in ipairs(self.m_trackGroups) do if(ent:IsValid()) then ent:TurnOff() end end
end

function ents.PFMFilmClip:OnRemove()
	util.remove(self.m_actors)
	util.remove(self.m_trackGroups)

	game.clear_unused_materials() -- Clear unused materials that may have been created through material overrides of actor model components
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

	-- TODO
	--[[local matOverlay = filmClip:GetMaterialOverlay()
	if(matOverlay ~= nil and #matOverlay:GetMaterial() > 0) then
		local entActor = ents.create("pfm_material_overlay")
		entActor:GetComponent("pfm_material_overlay"):Setup(self,matOverlay)
		entActor:Spawn()
		table.insert(self.m_actors,entActor)
	end

	local fadeIn = filmClip:GetFadeIn()
	local fadeOut = filmClip:GetFadeOut()
	if(fadeIn > 0.0 or fadeOut > 0.0) then
		local matOverlayData = fudm.PFMMaterialOverlayFXClip()
		matOverlayData:SetTimeFrame(filmClip:GetTimeFrame())
		matOverlayData:SetMaterial("black")
		matOverlayData:SetFullscreen(true)
		local entActor = ents.create("pfm_material_overlay")
		entActor:GetComponent("pfm_material_overlay"):Setup(self,matOverlayData,fadeIn,fadeOut)
		entActor:Spawn()
		table.insert(self.m_actors,entActor)
	end
]]
	self:InitializeActors()

	for _,trackGroupData in ipairs(filmClip:GetTrackGroups():GetTable()) do
		if(trackGroupData:IsMuted() == false) then
			self:CreateTrackGroup(trackGroupData)
		end
	end
	self:GetEntity():SetName(filmClip:GetName())

	local cam = self:GetClipData():GetProperty("camera")
	if(cam ~= nil) then
		local entCam = self:GetActor(cam)
		self.m_camera = entCam and entCam:GetComponent("pfm_camera") or entCam
		if(util.is_valid(self.m_camera)) then
			self.m_camera:SetFrustumModelVisible(true)
		end
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
function ents.PFMFilmClip:SetOffset(offset,gameViewFlags)
	gameViewFlags = gameViewFlags or ents.PFMProject.GAME_VIEW_FLAG_NONE
	local timeFrame = self:GetTimeFrame()
	local absOffset = offset
	offset = timeFrame:LocalizeOffset(offset)
	if(offset == self.m_offset) then return end
	self.m_offset = offset
	self:UpdateClip(gameViewFlags)

	for _,actor in ipairs(self:GetActors()) do
		if(actor:IsValid()) then
			local actorC = actor:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if(actorC ~= nil) then
				actorC:OnOffsetChanged(offset,gameViewFlags)
			end
		end
	end
	
	self:BroadcastEvent(ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED,{offset,absOffset})
end

function ents.PFMFilmClip:UpdateClip(gameViewFlags)
	for _,trackGroup in ipairs(self:GetTrackGroups()) do
		local trackGroupC = trackGroup:IsValid() and trackGroup:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP) or nil
		if(trackGroupC ~= nil) then
			trackGroupC:OnOffsetChanged(self:GetOffset(),gameViewFlags)
		end
	end
end

function ents.PFMFilmClip:CreateTrackGroup(trackGroup)
	pfm.log("Creating track group '" .. trackGroup:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local ent = ents.create("pfm_track_group")
	ent:Spawn()
	table.insert(self.m_trackGroups,ent)

	local trackGroupC = ent:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP)
	if(trackGroupC ~= nil) then
		trackGroupC:Setup(trackGroup,self)
		trackGroupC:OnOffsetChanged(self:GetOffset())
	end

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{ent}) end
end

function ents.PFMFilmClip:GetActor(actorData)
	for _,actor in ipairs(self:GetActors()) do
		if(actor:IsValid() and actor:HasComponent(ents.COMPONENT_PFM_ACTOR)) then
			if(util.is_same_object(actor:GetComponent(ents.COMPONENT_PFM_ACTOR):GetActorData(),actorData)) then
				return actor
			end
		end
	end
end

function ents.PFMFilmClip:InitializeActors()
	-- Only create actors that don't exist in the scene yet!
	local actorDataToEnt = {}
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		actorDataToEnt[actorC:GetActorData()] = ent
	end
	for _,actorData in ipairs(self.m_filmClipData:GetActorList()) do
		if(actorDataToEnt[actorData] == nil) then self:CreateActor(actorData) end
	end
end

function ents.PFMFilmClip:CreateActor(actor)
	local entActor = ents.create("pfm_actor")
	local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	actorC:Setup(actor)
	entActor:Spawn()
	table.insert(self.m_actors,entActor)

	local pos = entActor:GetPos()
	local ang = entActor:GetRotation():ToEulerAngles()
	local trC = entActor:GetComponent(ents.COMPONENT_TRANSFORM)
	local scale = (trC ~= nil) and trC:GetScale() or Vector(1,1,1)
	pfm.log("Created actor '" .. actor:GetName() ..
		"' at position (" .. util.round_string(pos.x,0) .. "," .. util.round_string(pos.y,0) .. "," .. util.round_string(pos.z,0) ..
		") with rotation (" .. util.round_string(ang.p,0) .. "," .. util.round_string(ang.y,0) .. "," .. util.round_string(ang.r,0) ..
		") with scale (" .. util.round_string(scale.x,2) .. "," .. util.round_string(scale.y,2) .. "," .. util.round_string(scale.z,2) .. ")...",pfm.LOG_CATEGORY_PFM_GAME)
	actorC:OnOffsetChanged(self:GetOffset(),ents.PFMProject.GAME_VIEW_FLAG_NONE)

	self:BroadcastEvent(ents.PFMFilmClip.EVENT_ON_ACTOR_CREATED,{actorC})

	local projectC = self:GetProject()
	if(util.is_valid(projectC)) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ACTOR_CREATED,{actorC})
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED,{actorC:GetEntity()})
	end
end

function ents.PFMFilmClip:GetProject()
	local trackC = self:GetTrack()
	if(util.is_valid(trackC) == false) then return end
	local projectC = trackC:GetProject()
	if(util.is_valid(projectC)) then return projectC end
	local trackGroupC = trackC:GetTrackGroup()
	if(util.is_valid(trackGroupC) == false) then return end
	return trackGroupC:GetProject()
end

function ents.PFMFilmClip:GetTimeFrame()
	local clip = self:GetClipData()
	if(clip == nil) then return fudm.PFMTimeFrame() end
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
ents.PFMFilmClip.EVENT_ON_ACTOR_CREATED = ents.register_component_event(ents.COMPONENT_PFM_FILM_CLIP,"on_actor_created")

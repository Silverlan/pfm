--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_track_group")

util.register_class("ents.PFMFilmClip", BaseEntityComponent)

function ents.PFMFilmClip:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_offset = 0.0

	self.m_actors = {}
	self.m_particles = {}
	self.m_trackGroups = {}
	self.m_actorChannels = {}
	self.m_listeners = {}
	self:AddEntityComponent(ents.COMPONENT_NAME)

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "OnTurnOff")
end

function ents.PFMFilmClip:OnTurnOn()
	for _, actor in ipairs(self:GetActors()) do
		if actor:IsValid() then
			actor:TurnOn()
		end
	end
	-- for _,ent in ipairs(self.m_trackGroups) do if(ent:IsValid()) then ent:TurnOn() end end
end

function ents.PFMFilmClip:OnTurnOff()
	for _, actor in ipairs(self:GetActors()) do
		if actor:IsValid() then
			actor:TurnOff()
		end
	end
	-- for _,ent in ipairs(self.m_trackGroups) do if(ent:IsValid()) then ent:TurnOff() end end
end

function ents.PFMFilmClip:OnRemove()
	util.remove(self.m_actors)
	util.remove(self.m_trackGroups)
	util.remove(self.m_listeners)

	game.clear_unused_materials() -- Clear unused materials that may have been created through material overrides of actor model components
end

function ents.PFMFilmClip:FindActorByName(name, filter)
	for _, actor in ipairs(self:GetActors()) do
		if actor:IsValid() and actor:GetName() == name and (filter == nil or filter(actor)) then
			return actor
		end
	end
end

function ents.PFMFilmClip:GetActors()
	return self.m_actors
end
function ents.PFMFilmClip:GetParticles()
	return self.m_particles
end
function ents.PFMFilmClip:GetTrackGroups()
	return self.m_trackGroups
end
function ents.PFMFilmClip:GetCamera()
	return self.m_camera
end

function ents.PFMFilmClip:Setup(filmClip, trackC)
	self.m_filmClipData = filmClip
	self.m_track = trackC

	table.insert(
		self.m_listeners,
		filmClip:AddChangeListener("camera", function(c, newCamera)
			self:UpdateCamera()
		end)
	)
	-- TODO
	--[[local matOverlay = filmClip:GetMaterialOverlay()
	if(matOverlay ~= nil and #matOverlay:GetMaterial() > 0) then
		local entActor = self:GetEntity():CreateChild("pfm_material_overlay")
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
		local entActor = self:GetEntity():CreateChild("pfm_material_overlay")
		entActor:GetComponent("pfm_material_overlay"):Setup(self,matOverlayData,fadeIn,fadeOut)
		entActor:Spawn()
		table.insert(self.m_actors,entActor)
	end
]]
	--[[local track = filmClip:FindAnimationChannelTrack()
	if(track ~= nil) then
		for _,channelClip in ipairs(track:GetAnimationClips()) do
			for _,channel in ipairs(channelClip:GetAniation():GetChannels()) do
				local toAttribute = channel:GetToAttribute()
				local toElement = channel:GetToElement()
				toElement = (toElement ~= nil) and toElement:FindParentElement() or nil
				if(toElement ~= nil and toElement:GetType() == fudm.ELEMENT_TYPE_PFM_BONE) then
					local mdlC = toElement:GetModelComponent()
					if(mdlC ~= nil) then
						local actorC = mdlC:FindParentElement()
						if(actorC ~= nil and actorC:GetType() == fudm.ELEMENT_TYPE_PFM_ACTOR) then
							self.m_actorChannels[actorC] = self.m_actorChannels[actorC] or {}
							local toElementName = toElement:GetName()
							self.m_actorChannels[actorC][toElementName] = self.m_actorChannels[actorC][toElementName] or {}
							self.m_actorChannels[actorC][toElementName][channel:GetToAttribute()] = channel
						end
					end
				end
			end
		end
	end]]

	self:InitializeActors()

	for _, trackGroupData in ipairs(filmClip:GetTrackGroups()) do
		if trackGroupData:IsMuted() == false then
			self:CreateTrackGroup(trackGroupData)
		end
	end
	self:GetEntity():SetName(filmClip:GetName())
	self:UpdateCamera()
end

function ents.PFMFilmClip:UpdateCamera()
	local cam = self:GetClipData():GetCamera()
	if cam ~= nil then
		local entCam = cam:FindEntity()
		self.m_camera = entCam and entCam:GetComponent("pfm_camera") or nil
		if util.is_valid(self.m_camera) then
			self.m_camera:SetFrustumModelVisible(true)
		end
	end
	if util.is_valid(self.m_camera) == false then
		if cam == nil then
			self:LogWarn("Film clip '" .. self:GetEntity():GetName() .. "' has no camera!")
		else
			self:LogWarn(
				"No camera by name '"
					.. cam:GetName()
					.. "' found for film clip ('"
					.. self:GetEntity():GetName()
					.. "')!"
			)
		end
	else
		ents.PFMCamera.set_active_camera(self.m_camera)
	end
end

function ents.PFMFilmClip:GetClipData()
	return self.m_filmClipData
end
function ents.PFMFilmClip:GetTrack()
	return self.m_track
end

function ents.PFMFilmClip:GetOffset()
	return self.m_offset
end
function ents.PFMFilmClip:SetOffset(offset, gameViewFlags)
	gameViewFlags = gameViewFlags or ents.PFMProject.GAME_VIEW_FLAG_NONE
	local timeFrame = self:GetTimeFrame()
	local absOffset = offset
	offset = timeFrame:LocalizeOffset(offset)
	if offset == self.m_offset then
		return
	end
	self.m_offset = offset
	self:UpdateClip(gameViewFlags)

	local tParticles = self:GetParticles()
	for i = #tParticles, 1, -1 do
		local particleC = tParticles[i]
		if particleC:IsValid() then
			particleC:OnOffsetChanged(offset)
		else
			table.remove(tParticles, i)
		end
	end

	self:InvokeEventCallbacks(ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED, { offset, absOffset })
end

function ents.PFMFilmClip:UpdateClip(gameViewFlags)
	for _, trackGroup in ipairs(self:GetTrackGroups()) do
		local trackGroupC = trackGroup:IsValid() and trackGroup:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP) or nil
		if trackGroupC ~= nil then
			trackGroupC:OnOffsetChanged(self:GetOffset(), gameViewFlags)
		end
	end
end

function ents.PFMFilmClip:CreateTrackGroup(trackGroup)
	self:LogInfo("Creating track group '" .. trackGroup:GetName() .. "'...")
	local ent = self:GetEntity():CreateChild("pfm_track_group")
	ent:Spawn()
	table.insert(self.m_trackGroups, ent)

	local trackGroupC = ent:GetComponent(ents.COMPONENT_PFM_TRACK_GROUP)
	if trackGroupC ~= nil then
		trackGroupC:Setup(trackGroup, self)
		trackGroupC:OnOffsetChanged(self:GetOffset())
	end

	local projectC = self:GetProject()
	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { ent })
	end
end

function ents.PFMFilmClip:InitializeActors()
	-- Only create actors that don't exist in the scene yet!
	local newActors = {}
	local actorDataToEnt = {}
	for ent in ents.iterator({ ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR) }) do
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		actorDataToEnt[actorC:GetActorData()] = ent
	end
	for _, actorData in ipairs(self.m_filmClipData:GetActorList(nil, false)) do
		if actorDataToEnt[actorData] == nil then
			local ent = self:CreateActor(actorData)
			table.insert(newActors, ent)
		end
	end
	for _, ent in ipairs(newActors) do
		if ent:IsValid() then
			ent:Spawn()
		end
	end
end

function ents.PFMFilmClip:CreateActor(actor)
	local entActor = self:GetEntity():CreateChild("pfm_actor")
	local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	actorC:Setup(actor)
	local channels = self.m_actorChannels[actor]
	if channels ~= nil then
		for boneName, boneChannels in pairs(channels) do
			for attr, channel in pairs(boneChannels) do
				actorC:SetBoneChannel(boneName, attr, channel)
			end
		end
	end
	actorC:ApplyPropertyValues()
	-- entActor:Spawn()
	table.insert(self.m_actors, entActor)

	local pfmParticleC = entActor:GetComponent(ents.COMPONENT_PFM_PARTICLE_SYSTEM)
	if pfmParticleC ~= nil then
		table.insert(self.m_particles, pfmParticleC)
	end

	local pos = entActor:GetPos()
	local ang = entActor:GetRotation():ToEulerAngles()
	local trC = entActor:GetComponent(ents.COMPONENT_TRANSFORM)
	local scale = (trC ~= nil) and trC:GetScale() or Vector(1, 1, 1)
	self:LogInfo(
		"Created actor '"
			.. actor:GetName()
			.. "' at position ("
			.. util.round_string(pos.x, 0)
			.. ","
			.. util.round_string(pos.y, 0)
			.. ","
			.. util.round_string(pos.z, 0)
			.. ") with rotation ("
			.. util.round_string(ang.p, 0)
			.. ","
			.. util.round_string(ang.y, 0)
			.. ","
			.. util.round_string(ang.r, 0)
			.. ") with scale ("
			.. util.round_string(scale.x, 2)
			.. ","
			.. util.round_string(scale.y, 2)
			.. ","
			.. util.round_string(scale.z, 2)
			.. ")..."
	)

	local projectC = self:GetProject()
	local animManager = self:GetAnimationManager()
	if animManager ~= nil then
		animManager:PlayActorAnimation(entActor)
	end

	self:BroadcastEvent(ents.PFMFilmClip.EVENT_ON_ACTOR_CREATED, { actorC })

	if util.is_valid(projectC) then
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ACTOR_CREATED, { actorC })
		projectC:BroadcastEvent(ents.PFMProject.EVENT_ON_ENTITY_CREATED, { actorC:GetEntity() })
	end
	return entActor
end

function ents.PFMFilmClip:GetProject()
	local trackC = self:GetTrack()
	if util.is_valid(trackC) == false then
		return
	end
	local projectC = trackC:GetProject()
	if util.is_valid(projectC) then
		return projectC
	end
	local trackGroupC = trackC:GetTrackGroup()
	if util.is_valid(trackGroupC) == false then
		return
	end
	return trackGroupC:GetProject()
end

function ents.PFMFilmClip:GetAnimationManager()
	local projectC = self:GetProject()
	if util.is_valid(projectC) == false then
		return
	end
	return projectC:GetAnimationManager()
end

function ents.PFMFilmClip:GetProjectManager()
	local projectC = self:GetProject()
	if util.is_valid(projectC) == false then
		return
	end
	return projectC:GetProjectManager()
end

function ents.PFMFilmClip:GetTimeFrame()
	local clip = self:GetClipData()
	if clip == nil then
		return fudm.PFMTimeFrame()
	end
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

ents.register_component("pfm_film_clip", ents.PFMFilmClip, "pfm")
ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_FILM_CLIP, "on_offset_changed")
ents.PFMFilmClip.EVENT_ON_ACTOR_CREATED =
	ents.register_component_event(ents.COMPONENT_PFM_FILM_CLIP, "on_actor_created")

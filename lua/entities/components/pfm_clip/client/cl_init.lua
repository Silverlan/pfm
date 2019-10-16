--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMClip",BaseEntityComponent)

local CLIP_CAMERA_ENABLED = true
ents.PFMClip.set_clip_camera_enabled = function(enabled)
	CLIP_CAMERA_ENABLED = enabled
end
function ents.PFMClip:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = 0.0
	self.m_entities = {}
	self:AddEntityComponent(ents.COMPONENT_NAME)
end

function ents.PFMClip:OnRemove()
	self:Stop()
end

function ents.PFMClip:GetOffset() return self.m_offset end
function ents.PFMClip:SetOffset(offset)
	if(offset == self.m_offset) then return end
	self.m_offset = offset
	self:UpdateClip()
	
	self:BroadcastEvent(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,{offset})
end
function ents.PFMClip:Advance(dt) self:SetOffset(self:GetOffset() +dt) end

function ents.PFMClip:UpdateClip()
	-- print("Updating clip...")
end

function ents.PFMClip:SetClip(udmClip) self.m_clip = udmClip end
function ents.PFMClip:GetClip() return self.m_clip end

function ents.PFMClip:CreateActor(actor)
	pfm.log("Creating actor '" .. actor:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	local entActor = ents.create("pfm_actor")
	entActor:GetComponent(ents.COMPONENT_PFM_ACTOR):Setup(self,actor)
	entActor:Spawn()
	table.insert(self.m_entities,entActor)
end

function ents.PFMClip:GetTimeFrame()
	local clip = self:GetClip()
	if(clip == nil) then return udm.PFMTimeFrame() end
	return clip:GetTimeFrame()
end

function ents.PFMClip:PlayAudio()
	for _,actor in ipairs(self.m_entities) do
		if(actor:IsValid()) then
			local sndC = actor:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
			if(sndC ~= nil) then sndC:Play() end
		end
	end
end

function ents.PFMClip:PauseAudio()
	for _,actor in ipairs(self.m_entities) do
		if(actor:IsValid()) then
			local sndC = actor:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE)
			if(sndC ~= nil) then sndC:Pause() end
		end
	end
end

function ents.PFMClip:Start()
	if(self:IsActive()) then return end

	self.m_bActive = true
	local clip = self:GetClip()
	pfm.log("Starting clip '" .. clip:GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	if(clip:GetType() == udm.ELEMENT_TYPE_PFM_AUDIO_CLIP) then
		local entSound = ents.create("pfm_sound_source")
		entSound:GetComponent(ents.COMPONENT_PFM_SOUND_SOURCE):Setup(self,clip:GetSound())
		entSound:Spawn()
		table.insert(self.m_entities,entSound)
	elseif(clip:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
		for _,actor in ipairs(clip:GetActors():GetValue()) do
			self:CreateActor(actor)
		end

		if(CLIP_CAMERA_ENABLED == true) then
			-- Initialize camera
			local cam = self:GetClip():GetProperty("camera")
			local foundCamera = false
			for _,entActor in ipairs(self.m_entities) do
				if(entActor:IsValid()) then
					if(cam ~= nil and entActor:HasComponent("pfm_camera") and entActor:GetName() == cam:GetName()) then -- TODO: Identify by unique id instead of the name!
						pfm.log("Using camera '" .. cam:GetName() .. "'!",pfm.LOG_CATEGORY_PFM_GAME)
						local toggleC = entActor:GetComponent(ents.COMPONENT_TOGGLE)
						if(toggleC ~= nil) then toggleC:TurnOn() end
						foundCamera = true
						break
					end
				end
			end
			if(foundCamera == false) then
				pfm.log("No camera found for the currently active clip ('" .. self:GetEntity():GetName() .. "')!",pfm.LOG_CATEGORY_PFM_GAME)
			end
		end
	end
end

function ents.PFMClip:Stop()
	if(self:IsActive() == false) then return end

	-- Re-enable the default game camera
	local camGame = game.get_primary_camera()
	local toggleC = (camGame ~= nil) and camGame:GetEntity():GetComponent(ents.COMPONENT_TOGGLE) or nil
	if(toggleC ~= nil) then toggleC:TurnOn() end

	self.m_bActive = false
	pfm.log("Stopping clip '" .. self:GetClip():GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	for _,ent in ipairs(self.m_entities) do
		if(ent:IsValid()) then ent:Remove() end
	end
	self.m_entities = {}
end

function ents.PFMClip:IsActive() return self.m_bActive end
ents.COMPONENT_PFM_CLIP = ents.register_component("pfm_clip",ents.PFMClip)
ents.PFMClip.EVENT_ON_OFFSET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_CLIP,"on_offset_changed")

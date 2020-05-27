--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerVelocityNoise",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerVelocityNoise:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerVelocityNoise:Initialize()
	self.m_controlPoint = tonumber(self:GetKeyValue("control_point_id")) or 0
	self.m_noiseScale = tonumber(self:GetKeyValue("time_noise_coordinate_scale")) or 1.0
	self.m_noiseScaleLoc = tonumber(self:GetKeyValue("spatial_noise_coordinate_scale")) or 0.01
	self.m_offset = tonumber(self:GetKeyValue("time_coordinate_offset")) or 0.0
	self.m_vecOffsetLoc = vector.create_from_string(self:GetKeyValue("spatial_coordinate_offset") or "0 0 0")
	self.m_vecAbsVal = vector.create_from_string(self:GetKeyValue("absolute_value") or "0 0 0")
	self.m_absValInv = vector.create_from_string(self:GetKeyValue("invert_abs_value") or "0 0 0")
	self.m_vecOutputMin = vector.create_from_string(self:GetKeyValue("output_minimum") or "0 0 0")
	self.m_vecOutputMax = vector.create_from_string(self:GetKeyValue("output_maximum") or "1 1 1")
	self.m_localSpace = toboolean(self:GetKeyValue("apply_velocity_in_local_space")) or false

	self:SetPriority(-5)
end
function ents.ParticleSystemComponent.InitializerVelocityNoise:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerVelocityNoise:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerVelocityNoise:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local absVal = Vector()
	local absScale = Vector(0.5,0.5,0.5)
	local bNoiseAbs = (self.m_absValInv.x ~= 0.0 or self.m_absValInv.y ~= 0.0 or self.m_absValInv.z ~= 0.0)
	if(self.m_vecAbsVal.x ~= 0.0) then
		absScale.x = 1.0
	end
	if(self.m_vecAbsVal.y ~= 0.0) then
		absScale.y = 1.0
	end
	if(self.m_vecAbsVal.z ~= 0.0) then
		absScale.z = 1.0
	end

	local valueScale = absScale *(self.m_vecOutputMax -self.m_vecOutputMin)
	local valueBase = self.m_vecOutputMin +(Vector(1.0,1.0,1.0) -absScale) *(self.m_vecOutputMax -self.m_vecOutputMin)

	local coordScale = self.m_noiseScale
	local coordScaleLoc = self.m_noiseScaleLoc
	local ofsY = Vector(100000.5,300000.25,9000000.75)
	local ofsZ = Vector(110000.25,310000.75,9100000.5)

	local pos = pt:GetPosition()
	local prevPos = pt:GetPreviousPosition()
	local creationTime = pt:GetTimeCreated()

	local offset = self.m_offset
	local pose = GetControlPointTransformAtTime(self,self.m_controlPoint,creationTime)

	local coordLoc = pt:GetPosition()
	coordLoc = coordLoc +self.m_vecOffsetLoc

	local coord = Vector(creationTime,creationTime,creationTime)
	coordLoc = coordLoc *self.m_noiseScaleLoc
	coord = coord *coordScale
	coord = coord +coordLoc

	local coord2 = coord:Copy()
	local offsetTemp = ofsY
	coord2 = coord2 +offsetTemp
	local coord3 = coord:Copy()
	coord3 = coord3 +offsetTemp

	local noise = NoiseV3(coord.x,coord.y,coord.z)
	if(bNoiseAbs) then
		noise.x = math.abs(noise.x)
		noise.y = math.abs(noise.y)
		noise.z = math.abs(noise.z)
	end

	if(bNoiseAbs) then
		if(self.m_absValInv.x ~= 0.0) then noise.x = 1.0 -noise.x end
		if(self.m_absValInv.y ~= 0.0) then noise.y = 1.0 -noise.y end
		if(self.m_absValInv.z ~= 0.0) then noise.z = 1.0 -noise.z end
	end

	local offset = valueBase +(valueScale *noise)
	offset = offset *GetPrevPtDelta()

	if(self.m_localSpace) then
		pose:SetOrigin(Vector())
		offset = pose *offset
	end
	prevPos = prevPos -offset
	pt:SetPreviousPosition(prevPos)
end
function ents.ParticleSystemComponent.InitializerVelocityNoise:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_velocity_random_noise",ents.ParticleSystemComponent.InitializerVelocityNoise)

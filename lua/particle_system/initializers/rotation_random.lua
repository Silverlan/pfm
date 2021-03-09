--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerRotationRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerRotationRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerRotationRandom:Initialize()
	self.m_rotationInitial = tonumber(self:GetKeyValue("rotation_initial")) or 0.0
	self.m_rotationOffsetMin = tonumber(self:GetKeyValue("rotation_offset_min")) or 0.0
	self.m_rotationOffsetMax = tonumber(self:GetKeyValue("rotation_offset_max")) or 360.0
	self.m_rotationRandomExponent = tonumber(self:GetKeyValue("rotation_random_exponent")) or 1.0
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local rot = self.m_rotationInitial +pt:CalcRandomFloatExp(self.m_rotationOffsetMin,self.m_rotationOffsetMax,self.m_rotationRandomExponent)
	rot = math.rad(rot)
	pt:SetRotation(rot)
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_rotation_random",ents.ParticleSystemComponent.InitializerRotationRandom)

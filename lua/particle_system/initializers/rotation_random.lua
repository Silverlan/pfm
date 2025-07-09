-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class(
	"ents.ParticleSystemComponent.InitializerRotationRandom",
	ents.ParticleSystemComponent.BaseInitializer
)

function ents.ParticleSystemComponent.InitializerRotationRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerRotationRandom:Initialize()
	self.m_rotationInitial = tonumber(self:GetKeyValue("rotation_initial") or "") or 0.0
	self.m_rotationOffsetMin = tonumber(self:GetKeyValue("rotation_offset_min") or "") or 0.0
	self.m_rotationOffsetMax = tonumber(self:GetKeyValue("rotation_offset_max") or "") or 360.0
	self.m_rotationRandomExponent = tonumber(self:GetKeyValue("rotation_random_exponent") or "") or 1.0
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local rot = self.m_rotationInitial
		+ pt:CalcRandomFloatExp(self.m_rotationOffsetMin, self.m_rotationOffsetMax, self.m_rotationRandomExponent)
	rot = math.rad(rot)
	pt:SetRotation(rot)
end
function ents.ParticleSystemComponent.InitializerRotationRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer(
	"source_rotation_random",
	ents.ParticleSystemComponent.InitializerRotationRandom
)

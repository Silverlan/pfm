-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class(
	"ents.ParticleSystemComponent.InitializerLifetimeRandom",
	ents.ParticleSystemComponent.BaseInitializer
)

function ents.ParticleSystemComponent.InitializerLifetimeRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:Initialize()
	self.m_lifetimeMin = tonumber(self:GetKeyValue("lifetime_min")) or 0
	self.m_lifetimeMax = tonumber(self:GetKeyValue("lifetime_max")) or 0
	self.m_lifetimeRandomExponent = tonumber(self:GetKeyValue("lifetime_random_exponent")) or 1.0
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local lifetime = self.m_lifetimeMin
		+ (math.randomf(0.0, self.m_lifetimeMax - self.m_lifetimeMin) ^ self.m_lifetimeRandomExponent)
	pt:SetLife(lifetime)
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer(
	"source_lifetime_random",
	ents.ParticleSystemComponent.InitializerLifetimeRandom
)

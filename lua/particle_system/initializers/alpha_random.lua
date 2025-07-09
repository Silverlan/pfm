-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.ParticleSystemComponent.InitializerAlphaRandom", ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerAlphaRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerAlphaRandom:Initialize()
	self.m_alphaMin = tonumber(self:GetKeyValue("alpha_min") or "255")
	self.m_alphaMax = tonumber(self:GetKeyValue("alpha_max") or "255")
	self.m_alphaRandomExponent = tonumber(self:GetKeyValue("alpha_random_exponent") or "1.0")
end
function ents.ParticleSystemComponent.InitializerAlphaRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerAlphaRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerAlphaRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local alpha = self.m_alphaMin + (math.randomf(0.0, self.m_alphaMax - self.m_alphaMin) ^ self.m_alphaRandomExponent)
	pt:SetAlpha(alpha / 255.0)
end
function ents.ParticleSystemComponent.InitializerAlphaRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer(
	"source_alpha_random",
	ents.ParticleSystemComponent.InitializerAlphaRandom
)

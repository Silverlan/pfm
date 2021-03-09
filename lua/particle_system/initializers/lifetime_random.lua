--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerLifetimeRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerLifetimeRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:Initialize()
	self.m_lifetimeMin = tonumber(self:GetKeyValue("lifetime_min") or "0")
	self.m_lifetimeMax = tonumber(self:GetKeyValue("lifetime_max") or "0")
	self.m_lifetimeRandomExponent = tonumber(self:GetKeyValue("lifetime_random_exponent") or "1.0")
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local lifetime = self.m_lifetimeMin +(math.randomf(0.0,self.m_lifetimeMax -self.m_lifetimeMin) ^self.m_lifetimeRandomExponent)
	pt:SetLife(lifetime)
end
function ents.ParticleSystemComponent.InitializerLifetimeRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_lifetime_random",ents.ParticleSystemComponent.InitializerLifetimeRandom)

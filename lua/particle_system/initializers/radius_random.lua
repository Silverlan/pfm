--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerRadiusRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerRadiusRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerRadiusRandom:Initialize()
	self.m_radiusMin = tonumber(self:GetKeyValue("radius_min")) or 1.0
	self.m_radiusMax = tonumber(self:GetKeyValue("radius_max")) or 1.0
	self.m_radiusRandomExponent = tonumber(self:GetKeyValue("radius_random_exponent")) or 1.0
end
function ents.ParticleSystemComponent.InitializerRadiusRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerRadiusRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerRadiusRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local radius = self.m_radiusMin +(math.randomf(0.0,self.m_radiusMax -self.m_radiusMin) ^self.m_radiusRandomExponent)
	pt:SetRadius(radius)
end
function ents.ParticleSystemComponent.InitializerRadiusRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_radius_random",ents.ParticleSystemComponent.InitializerRadiusRandom)

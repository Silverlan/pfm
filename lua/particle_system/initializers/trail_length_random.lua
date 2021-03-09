--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.TrailLengthRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.TrailLengthRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.TrailLengthRandom:Initialize()
	self.m_lengthMin = tonumber(self:GetKeyValue("length_min")) or 0.1
	self.m_lengthMax = tonumber(self:GetKeyValue("length_max")) or 0.1
	self.m_lengthRandomExponent = tonumber(self:GetKeyValue("length_random_exponent")) or 1.0
end
function ents.ParticleSystemComponent.TrailLengthRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.TrailLengthRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.TrailLengthRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local len = pt:CalcRandomFloatExp(self.m_lengthMin,self.m_lengthMax,self.m_lengthRandomExponent)
	pt:SetLength(len)
end
function ents.ParticleSystemComponent.TrailLengthRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_trail_length_random",ents.ParticleSystemComponent.TrailLengthRandom)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.SequenceRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.SequenceRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.SequenceRandom:Initialize()
	self.m_sequenceMin = tonumber(self:GetKeyValue("sequence_min")) or 0
	self.m_sequenceMax = tonumber(self:GetKeyValue("sequence_max")) or 0
end
function ents.ParticleSystemComponent.SequenceRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.SequenceRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.SequenceRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	pt:SetSequence(pt:CalcRandomInt(self.m_sequenceMin,self.m_sequenceMax))
end
function ents.ParticleSystemComponent.SequenceRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_sequence_random",ents.ParticleSystemComponent.SequenceRandom)

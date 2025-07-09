-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.ParticleSystemComponent.OperatorRandomForce", ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorRandomForce:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorRandomForce:Initialize()
	self.m_minForce = vector.create_from_string(self:GetKeyValue("min_force") or "0 0 0")
	self.m_maxForce = vector.create_from_string(self:GetKeyValue("max_force") or "0 0 0")
	self._isForce = true
end
function ents.ParticleSystemComponent.OperatorRandomForce:AddForces(force, pt, dt, strength)
	return force + RandomVector(self.m_minForce, self.m_maxForce)
end
function ents.ParticleSystemComponent.OperatorRandomForce:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorRandomForce:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorRandomForce:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorRandomForce:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_force_random", ents.ParticleSystemComponent.OperatorRandomForce)

-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class(
	"ents.ParticleSystemComponent.OperatorAttractToControlPoint",
	ents.ParticleSystemComponent.BaseOperator
)

function ents.ParticleSystemComponent.OperatorAttractToControlPoint:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:Initialize()
	self.m_force = tonumber(self:GetKeyValue("amount_of_force") or "") or 0.0
	self.m_falloffPower = tonumber(self:GetKeyValue("falloff_power") or "") or 2.0
	self.m_controlPoint = tonumber(self:GetKeyValue("control_point_id") or "") or 0
	self._isForce = true
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:AddForces(force, pt, dt, strength)
	local powerFrac = -self.m_falloffPower
	local forceScale = -self.m_force * strength

	local vecCenter = GetControlPointAtTime(self, self.m_controlPoint, pt:GetTimeCreated())
	local center = vecCenter:Copy()

	local ofs = pt:GetPosition()
	ofs = ofs - center
	local len = ofs:Length()
	ofs = ofs * forceScale * ReciprocalSaturate(len)
	ofs = ofs * math.pow(len, powerFrac)
	if len > FLT_EPSILON then
		force = force + ofs
	end
	return force
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorAttractToControlPoint:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator(
	"source_pull_towards_control_point",
	ents.ParticleSystemComponent.OperatorAttractToControlPoint
)

--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorTwistAroundAxis",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorTwistAroundAxis:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:Initialize()
	self.m_force = tonumber(self:GetKeyValue("amount_of_force")) or 0.0
	self.m_twistAxis = vector.create_from_string(self:GetKeyValue("twist_axis") or "0 1 0")
	self.m_localSpace = toboolean(self:GetKeyValue("local_space_axis")) or false
	self._isForce = true
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:AddForces(force,pt,dt,strength)
	local axisInWorldSpace = TransformAxis(self,self.m_twistAxis,self.m_localSpace)

	local vecCenter = GetControlPointAtTime(self,self.m_controlPoint,pt:GetTimeCreated())
	local center = vecCenter:Copy()

	local forceScale = self.m_force *strength
	local ofs = pt:GetPosition()
	ofs = ofs -center
	ofs:Normalize()

	local parallelComp = ofs *(ofs *axisInWorldSpace)
	ofs = ofs -parallelComp
	ofs:Normalize()
	local tangentialForce = ofs:Cross(axisInWorldSpace)
	tangentialForce = tangentialForce *forceScale
	return force +tangentialForce
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorTwistAroundAxis:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_twist_around_axis",ents.ParticleSystemComponent.OperatorTwistAroundAxis)

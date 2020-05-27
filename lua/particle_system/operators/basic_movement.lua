--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorBasicMovement",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorBasicMovement:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorBasicMovement:Initialize()
	self.m_drag = tonumber(self:GetKeyValue("drag") or "0.0")
	self.m_maxConstraintPasses = tonumber(self:GetKeyValue("max_constraint_passes") or "3")
	self.m_gravity = vector.create_from_string(self:GetKeyValue("gravity") or "0 0 0")
end
function ents.ParticleSystemComponent.OperatorBasicMovement:Simulate(pt,dt,strength)
	if(dt == 0.0) then return end
	local factor = 1.0 -- TODO: This is arbitrary
	local prevDt = dt *factor
	local adj_dt = ( dt / prevDt ) * ExponentialDecay( (1.0-math.max(0.0,self.m_drag)), (1.0/30.0), dt )

	local dtSquared = dt *dt

	local acc = self.m_gravity /3.0 -- TODO: Arbitrary factor
	for _,force in ipairs(self.m_forces) do
		local forceStrength = force:CalcStrength(pt:GetTimeAlive())
		acc = force:AddForces(acc,pt,dt,forceStrength)
	end
	acc = acc *dtSquared
	local accFactor = acc

	local newPos = pt:GetPosition() +accFactor +adj_dt *(pt:GetPosition() -pt:GetPreviousPosition()) *factor *1.0

	local pos = pt:GetPosition()
	pt:SetPosition(newPos)
	pt:SetPreviousPosition(pos)
end
function ents.ParticleSystemComponent.OperatorBasicMovement:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
	self.m_forces = {}
	self.m_constraints = {}
	for _,initializer in ipairs(self:GetParticleSystem():GetOperators()) do
		if(initializer._isForce) then
			table.insert(self.m_forces,initializer)
		elseif(initializer._isConstraint) then
			table.insert(self.m_constraints,initializer)
		end
	end
end
function ents.ParticleSystemComponent.OperatorBasicMovement:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorBasicMovement:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	-- pt:SetPreviousPosition(Vector())
end
function ents.ParticleSystemComponent.OperatorBasicMovement:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_movement_basic",ents.ParticleSystemComponent.OperatorBasicMovement)

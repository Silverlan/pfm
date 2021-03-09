--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerPositionFromParentParticles",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:Initialize()
	self.m_velocityScale = tonumber(self:GetKeyValue("inherited_velocity_scale")) or 0.0
	self.m_randomDistribution = toboolean(self:GetKeyValue("random_parent_particle_distribution")) or false
end
function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	error("TODO: Not yet fully implemented")
	local ptC = self:GetParticleSystem()
	local parent = ptC:GetParent()
	if(util.is_valid(parent) == false) then
		pt:SetPosition(Vector())
		pt:SetPreviousPosition(Vector())
		return
	end

	local numActiveParticles = parent:GetActiveParticles()
	if(numActiveParticles == 0) then
		pt:SetLife(0.0)
		return
	end
	numActiveParticles = math.max(0,numActiveParticles -1)

	if(self.m_randomDistribution) then

	else

	end
end
function ents.ParticleSystemComponent.InitializerPositionFromParentParticles:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_position_from_parent_particle",ents.ParticleSystemComponent.InitializerPositionFromParentParticles)

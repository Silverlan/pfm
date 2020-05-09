--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:Initialize()
	self.m_controlPointNumber = tonumber(self:GetKeyValue("control_point_number") or "0")
	self.m_offsetMin = vector.create_from_string(self:GetKeyValue("offset min") or "0 0 0")
	self.m_offsetMax = vector.create_from_string(self:GetKeyValue("offset max") or "0 0 0")
	self.m_offsetInLocalSpace = toboolean(self:GetKeyValue("offset in local space 0/1") or "0")
	self.m_offsetProportionalToRadius = toboolean(self:GetKeyValue("offset proportional to radius 0/1") or "0")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local randPos = Vector()
	if(self.m_offsetProportionalToRadius) then
		randPos = RandomVector((self.m_offsetMin *radius),self.m_offsetMax *radius)
	else
		randPos = RandomVector(m_offsetMin,m_offsetMax)
	end

	if(self.m_offsetInLocalSpace) then
		-- TODO
		--[[local mat = Mat3x4()
		pParticles:GetControlPointTransformAtTime( m_nControlPointNumber, ct, mat )
		local vecTransformLocal = Vector()
		VectorRotate( randpos, mat, vecTransformLocal )
		randpos = vecTransformLocal]]
	end
	pt:SetPosition(pt:GetPosition() +randPos)
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("position modify offset random",ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom)

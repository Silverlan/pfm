--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:Initialize()
	self.m_min = vector.create_from_string(self:GetKeyValue("min") or "0 0 0")
	self.m_max = vector.create_from_string(self:GetKeyValue("max") or "0 0 0")
	self.m_controlPointNumber = tonumber(self:GetKeyValue("control_point_id") or "0")
end
function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local v = RandomVector(self.m_min,self.m_max)
	local vecControlPoint = GetControlPointAtTime(self,self.m_controlPointNumber,pt:GetTimeCreated())
	v = v +vecControlPoint
	pt:SetPosition(v)
	pt:SetPreviousPosition(v)
end
function ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_position_random_box",ents.ParticleSystemComponent.InitializerPositionWithinBoxRandom)

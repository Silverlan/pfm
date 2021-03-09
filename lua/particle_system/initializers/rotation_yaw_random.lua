--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerYawFlipRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerYawFlipRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:Initialize()
	self.m_percent = tonumber(self:GetKeyValue("flip_percentage")) or 0.5
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local chance = pt:CalcRandomFloat(0.0,1.0)
	if(chance < self.m_percent) then
		pt:SetRotationYaw(pt:GetRotationYaw() +math.rad(180.0))
	end
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_rotation_yaw_flip_random",ents.ParticleSystemComponent.InitializerYawFlipRandom)

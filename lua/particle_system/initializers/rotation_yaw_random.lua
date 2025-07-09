-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class(
	"ents.ParticleSystemComponent.InitializerYawFlipRandom",
	ents.ParticleSystemComponent.BaseInitializer
)

function ents.ParticleSystemComponent.InitializerYawFlipRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:Initialize()
	self.m_percent = tonumber(self:GetKeyValue("flip_percentage") or "") or 0.5
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local chance = pt:CalcRandomFloat(0.0, 1.0)
	if chance < self.m_percent then
		pt:SetRotationYaw(pt:GetRotationYaw() + math.rad(180.0))
	end
end
function ents.ParticleSystemComponent.InitializerYawFlipRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer(
	"source_rotation_yaw_flip_random",
	ents.ParticleSystemComponent.InitializerYawFlipRandom
)
